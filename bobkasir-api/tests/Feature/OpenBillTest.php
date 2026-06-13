<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\OpenBill;
use App\Models\Product;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards H6: open-bill line money is server-authoritative — client price is
 * ignored for catalog products, discounts can't drive the subtotal negative,
 * and foreign products can't be attached.
 */
class OpenBillTest extends TestCase
{
    use RefreshDatabase;

    private Business $business;
    private Product $product;
    private OpenBill $bill;

    protected function setUp(): void
    {
        parent::setUp();

        $owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $this->business = Business::create([
            'owner_id' => $owner->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $owner->id, 'business_id' => $this->business->id,
            'role' => 'owner', 'status' => 'active',
        ]);
        $this->product = Product::create([
            'business_id' => $this->business->id, 'name' => 'Latte', 'price' => 25000, 'is_active' => true,
        ]);
        $this->bill = OpenBill::create([
            'business_id' => $this->business->id,
            'user_id' => $owner->id,
            'bill_number' => 'OB-TEST-1',
        ]);

        Sanctum::actingAs($owner);
    }

    private function addItem(array $payload)
    {
        return $this->postJson('/api/open-bills/' . $this->bill->id . '/items', $payload);
    }

    public function test_uses_authoritative_product_price(): void
    {
        $res = $this->addItem([
            'product_id' => $this->product->id,
            'product_name' => 'tamper',
            'price' => 1,
            'qty' => 2,
        ]);

        $res->assertCreated();
        $this->assertSame(25000, $res->json('data.price'));
        $this->assertSame(50000, $res->json('data.subtotal'));
        $this->assertSame('Latte', $res->json('data.product_name'));
    }

    public function test_discount_cannot_make_subtotal_negative(): void
    {
        $res = $this->addItem([
            'product_id' => $this->product->id,
            'product_name' => 'Latte',
            'price' => 25000,
            'qty' => 1,
            'discount' => 999999,
        ]);

        $res->assertCreated();
        $this->assertSame(0, $res->json('data.subtotal'));
    }

    public function test_cannot_attach_foreign_product(): void
    {
        $ownerB = User::create([
            'name' => 'B', 'email' => 'b@example.com', 'password' => 'password', 'status' => 'active',
        ]);
        $bizB = Business::create([
            'owner_id' => $ownerB->id, 'name' => 'Bob B', 'status' => 'active',
        ]);
        $foreign = Product::create([
            'business_id' => $bizB->id, 'name' => 'Kopi B', 'price' => 10000, 'is_active' => true,
        ]);

        $this->addItem([
            'product_id' => $foreign->id,
            'product_name' => 'Kopi B',
            'price' => 10000,
            'qty' => 1,
        ])->assertNotFound();
    }

    public function test_custom_item_without_product_uses_client_price(): void
    {
        $res = $this->addItem([
            'product_name' => 'Custom Item',
            'price' => 5000,
            'qty' => 3,
        ]);

        $res->assertCreated();
        $this->assertSame(5000, $res->json('data.price'));
        $this->assertSame(15000, $res->json('data.subtotal'));
    }

    public function test_negative_price_is_rejected(): void
    {
        $this->addItem([
            'product_name' => 'Hack',
            'price' => -1000,
            'qty' => 1,
        ])->assertStatus(422);
    }
}
