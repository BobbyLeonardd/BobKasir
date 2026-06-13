<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards the offline-sync replay (#2): POST /api/sync/push must actually persist
 * the order on the server and must never create duplicates on retry.
 */
class SyncPushTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private Business $business;
    private Product $product;

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

        $this->product = Product::create([
            'business_id' => $this->business->id,
            'name'        => 'Americano',
            'price'       => 25000,
            'is_active'   => true,
            'track_stock' => false,
        ]);

        Sanctum::actingAs($this->owner);
    }

    private function orderPayload(string $localId): array
    {
        return [
            'local_order_id' => $localId,
            'ordered_at'     => now()->toISOString(),
            'items' => [
                ['product_id' => $this->product->id, 'product_name' => 'Americano', 'price' => 25000, 'qty' => 2],
            ],
            'payments' => [
                ['method' => 'cash', 'amount' => 50000],
            ],
        ];
    }

    private function push(string $syncId, string $localId): \Illuminate\Testing\TestResponse
    {
        return $this->postJson('/api/sync/push', [
            'device_id' => 'device-1',
            'items' => [
                [
                    'sync_id'  => $syncId,
                    'local_id' => $localId,
                    'type'     => 'order',
                    'payload'  => $this->orderPayload($localId),
                ],
            ],
        ]);
    }

    public function test_push_creates_the_order_on_the_server(): void
    {
        $response = $this->push('S1', 'L1');

        $response->assertOk();
        $this->assertTrue($response->json('success'));
        $this->assertSame('synced', $response->json('data.results.0.status'));
        $this->assertStringStartsWith('BK-', $response->json('data.results.0.order_number'));

        $order = Order::where('local_order_id', 'L1')->first();
        $this->assertNotNull($order);
        $this->assertSame(50000, $order->grand_total);
        $this->assertSame('synced', $order->sync_status);
        $this->assertCount(1, $order->items);
        $this->assertCount(1, $order->payments);
    }

    public function test_repeated_sync_id_does_not_duplicate(): void
    {
        $this->push('S1', 'L1');
        $second = $this->push('S1', 'L1');

        $this->assertSame('already_synced', $second->json('data.results.0.status'));
        $this->assertSame(1, Order::where('local_order_id', 'L1')->count());
    }

    public function test_same_local_order_with_different_sync_id_does_not_duplicate(): void
    {
        $this->push('S1', 'L1');
        $second = $this->push('S2', 'L1'); // different queue id, same offline order

        $this->assertSame('already_synced', $second->json('data.results.0.status'));
        $this->assertSame(1, Order::where('local_order_id', 'L1')->count());
    }

    public function test_push_requires_authentication(): void
    {
        // Drop the acting user by hitting the route without Sanctum context.
        $this->app['auth']->forgetGuards();

        $response = $this->withHeaders(['Accept' => 'application/json'])
            ->postJson('/api/sync/push', ['items' => []]);

        $response->assertUnauthorized();
    }
}
