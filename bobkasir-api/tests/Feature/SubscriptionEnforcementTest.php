<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Product;
use App\Models\Subscription;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards H1: premium endpoints lock when the subscription is expired, while the
 * basic cashier flow keeps working (PRD §10.6).
 */
class SubscriptionEnforcementTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private Business $business;

    protected function setUp(): void
    {
        parent::setUp();
        $this->owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $this->business = Business::create([
            'owner_id' => $this->owner->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->owner->id, 'business_id' => $this->business->id,
            'role' => 'owner', 'status' => 'active',
        ]);
        Sanctum::actingAs($this->owner);
    }

    private function setSubscription(string $status, ?string $expiredAt): void
    {
        Subscription::create([
            'business_id' => $this->business->id,
            'owner_id'    => $this->owner->id,
            'status'      => $status,
            'expired_at'  => $expiredAt,
        ]);
    }

    public function test_expired_subscription_blocks_premium_endpoint(): void
    {
        $this->setSubscription('expired', now()->subDay()->toDateTimeString());

        $this->getJson('/api/discounts')->assertStatus(403);
    }

    public function test_active_subscription_allows_premium_endpoint(): void
    {
        $this->setSubscription('active', now()->addDays(10)->toDateTimeString());

        $this->getJson('/api/discounts')->assertOk();
    }

    public function test_trial_allows_premium_endpoint(): void
    {
        $this->setSubscription('trial', null);

        $this->getJson('/api/discounts')->assertOk();
    }

    public function test_expired_subscription_still_allows_cashier_checkout(): void
    {
        $this->setSubscription('expired', now()->subDay()->toDateTimeString());

        $product = Product::create([
            'business_id' => $this->business->id, 'name' => 'Kopi', 'price' => 15000, 'is_active' => true,
        ]);

        // Orders are a basic flow — must NOT be gated by subscription.
        $this->postJson('/api/orders', [
            'local_order_id' => 'OFF-1',
            'items' => [
                ['product_id' => $product->id, 'product_name' => 'Kopi', 'price' => 15000, 'qty' => 1],
            ],
            'payments' => [['method' => 'cash', 'amount' => 15000]],
        ])->assertCreated();
    }
}
