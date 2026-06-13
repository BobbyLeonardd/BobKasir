<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Order;
use App\Models\Product;
use App\Models\ServiceCharge;
use App\Models\Stock;
use App\Models\Tax;
use App\Models\User;
use App\Models\UserBusinessRole;
use App\Services\OrderCreationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards the money-integrity rules (#3): the server recomputes every total from
 * authoritative product prices and never trusts client-sent amounts, and order
 * creation is idempotent on local_order_id (#2 / PRD §26.5).
 */
class OrderMoneyTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private Business $business;

    protected function setUp(): void
    {
        parent::setUp();

        $this->owner = User::create([
            'name'              => 'Owner',
            'email'             => 'owner@example.com',
            'password'          => 'password',
            'status'            => 'active',
            'email_verified_at' => now(),
        ]);

        $this->business = Business::create([
            'owner_id' => $this->owner->id,
            'name'     => 'Bob Coffee',
            'status'   => 'active',
        ]);

        UserBusinessRole::create([
            'user_id'     => $this->owner->id,
            'business_id' => $this->business->id,
            'role'        => 'owner',
            'status'      => 'active',
        ]);
    }

    private function makeProduct(int $price, ?int $stockQty = null): Product
    {
        $product = Product::create([
            'business_id' => $this->business->id,
            'name'        => 'Latte',
            'price'       => $price,
            'is_active'   => true,
            'track_stock' => $stockQty !== null,
        ]);

        if ($stockQty !== null) {
            Stock::create([
                'product_id'    => $product->id,
                'quantity'      => $stockQty,
                'minimum_stock' => 0,
            ]);
        }

        return $product;
    }

    private function create(array $payload): array
    {
        return OrderCreationService::create(
            $payload,
            $this->owner,
            $this->business->id,
            'owner',
            null,
            'device-1',
            '127.0.0.1',
        );
    }

    public function test_totals_are_recomputed_from_product_price_ignoring_client_values(): void
    {
        $product = $this->makeProduct(25000);

        $result = $this->create([
            'local_order_id' => 'L1',
            // Client lies about price and totals — all must be ignored.
            'discount_total' => 5000,
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'tamper', 'price' => 1, 'qty' => 2],
            ],
            'payments' => [
                ['method' => 'cash', 'amount' => 50000],
            ],
        ]);

        $order = $result['order'];

        $this->assertFalse($result['duplicate']);
        $this->assertSame(50000, $order->subtotal);          // 25000 * 2
        $this->assertSame(5000, $order->discount_total);
        $this->assertSame(45000, $order->grand_total);       // 50000 - 5000
        $this->assertSame(50000, $order->paid_amount);
        $this->assertSame(5000, $order->change_amount);      // 50000 - 45000
        $this->assertSame(25000, $order->items->first()->price_snapshot); // not 1
        $this->assertSame('Latte', $order->items->first()->product_name_snapshot);
    }

    public function test_discount_is_clamped_to_subtotal_so_grand_total_never_negative(): void
    {
        $product = $this->makeProduct(10000);

        $order = $this->create([
            'local_order_id' => 'L2',
            'discount_total' => 999999,
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 10000, 'qty' => 1],
            ],
            'payments' => [['method' => 'cash', 'amount' => 0]],
        ])['order'];

        $this->assertSame(10000, $order->subtotal);
        $this->assertSame(10000, $order->discount_total); // clamped
        $this->assertSame(0, $order->grand_total);
    }

    public function test_creation_is_idempotent_on_local_order_id(): void
    {
        $product = $this->makeProduct(15000);
        $payload = [
            'local_order_id' => 'DUP-1',
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 15000, 'qty' => 1],
            ],
            'payments' => [['method' => 'cash', 'amount' => 15000]],
        ];

        $first  = $this->create($payload);
        $second = $this->create($payload);

        $this->assertFalse($first['duplicate']);
        $this->assertTrue($second['duplicate']);
        $this->assertSame($first['order']->id, $second['order']->id);
        $this->assertSame(1, Order::where('local_order_id', 'DUP-1')->count());
    }

    public function test_stock_is_deducted_for_tracked_products(): void
    {
        $product = $this->makeProduct(20000, stockQty: 10);

        $this->create([
            'local_order_id' => 'L3',
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 20000, 'qty' => 3],
            ],
            'payments' => [['method' => 'cash', 'amount' => 60000]],
        ]);

        $this->assertSame(7, Stock::where('product_id', $product->id)->first()->quantity);
    }

    public function test_orders_endpoint_ignores_client_grand_total(): void
    {
        $product = $this->makeProduct(30000);
        Sanctum::actingAs($this->owner);

        $response = $this->postJson('/api/orders', [
            'local_order_id' => 'API-1',
            'grand_total'    => 1,   // tampered
            'subtotal'       => 1,   // tampered
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 1, 'qty' => 2],
            ],
            'payments' => [['method' => 'cash', 'amount' => 60000]],
        ]);

        $response->assertCreated();
        $this->assertSame(60000, $response->json('data.grand_total'));
        $this->assertDatabaseHas('orders', [
            'local_order_id' => 'API-1',
            'grand_total'    => 60000,
        ]);
    }

    private function activateTax(float $rate): void
    {
        Tax::create([
            'business_id' => $this->business->id,
            'name'        => "PPN $rate%",
            'rate'        => $rate,
            'is_active'   => true,
        ]);
    }

    private function activateServiceCharge(float $rate): void
    {
        ServiceCharge::create([
            'business_id' => $this->business->id,
            'name'        => "Service $rate%",
            'rate'        => $rate,
            'is_active'   => true,
        ]);
    }

    public function test_tax_and_service_charge_computed_from_active_config(): void
    {
        $product = $this->makeProduct(25000);
        $this->activateTax(10);            // 10%
        $this->activateServiceCharge(5);   // 5%

        $order = $this->create([
            'local_order_id' => 'TAX-1',
            // Client values must be ignored — server reads config.
            'tax_total' => 999,
            'service_charge_total' => 999,
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 25000, 'qty' => 2],
            ],
            'payments' => [['method' => 'cash', 'amount' => 60000]],
        ])['order'];

        $this->assertSame(50000, $order->subtotal);
        $this->assertSame(5000, $order->tax_total);            // 10% of 50000
        $this->assertSame(2500, $order->service_charge_total); // 5% of 50000
        $this->assertSame(57500, $order->grand_total);
    }

    public function test_tax_applies_to_subtotal_after_discount(): void
    {
        $product = $this->makeProduct(50000);
        $this->activateTax(10);

        $order = $this->create([
            'local_order_id' => 'TAX-2',
            'discount_total' => 10000,
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 50000, 'qty' => 1],
            ],
            'payments' => [['method' => 'cash', 'amount' => 50000]],
        ])['order'];

        $this->assertSame(50000, $order->subtotal);
        $this->assertSame(10000, $order->discount_total);
        $this->assertSame(4000, $order->tax_total);  // 10% of (50000 - 10000)
        $this->assertSame(44000, $order->grand_total);
    }

    public function test_inactive_tax_is_not_applied(): void
    {
        $product = $this->makeProduct(20000);
        Tax::create([
            'business_id' => $this->business->id,
            'name'        => 'PPN nonaktif',
            'rate'        => 10,
            'is_active'   => false,
        ]);

        $order = $this->create([
            'local_order_id' => 'TAX-3',
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'x', 'price' => 20000, 'qty' => 1],
            ],
            'payments' => [['method' => 'cash', 'amount' => 20000]],
        ])['order'];

        $this->assertSame(0, $order->tax_total);
        $this->assertSame(20000, $order->grand_total);
    }
}
