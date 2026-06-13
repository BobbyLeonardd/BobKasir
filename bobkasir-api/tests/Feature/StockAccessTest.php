<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Product;
use App\Models\Stock;
use App\Models\Subscription;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards C3: stock writes must be scoped to the caller's business — an owner
 * must not be able to create/adjust stock for another tenant's product (IDOR).
 */
class StockAccessTest extends TestCase
{
    use RefreshDatabase;

    private User $ownerA;
    private Product $productA;
    private Product $foreignProduct;

    protected function setUp(): void
    {
        parent::setUp();

        // Business A (the caller)
        $this->ownerA = User::create([
            'name' => 'Owner A', 'email' => 'a@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $bizA = Business::create([
            'owner_id' => $this->ownerA->id, 'name' => 'Bob A', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->ownerA->id, 'business_id' => $bizA->id,
            'role' => 'owner', 'status' => 'active',
        ]);
        Subscription::create([
            'business_id' => $bizA->id, 'owner_id' => $this->ownerA->id,
            'status' => 'active', 'expired_at' => now()->addDays(30),
        ]);
        $this->productA = Product::create([
            'business_id' => $bizA->id, 'name' => 'Kopi A', 'price' => 10000, 'is_active' => true,
        ]);

        // Business B (the victim)
        $ownerB = User::create([
            'name' => 'Owner B', 'email' => 'b@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $bizB = Business::create([
            'owner_id' => $ownerB->id, 'name' => 'Bob B', 'status' => 'active',
        ]);
        $this->foreignProduct = Product::create([
            'business_id' => $bizB->id, 'name' => 'Kopi B', 'price' => 10000, 'is_active' => true,
        ]);

        Sanctum::actingAs($this->ownerA);
    }

    public function test_cannot_set_initial_stock_for_foreign_product(): void
    {
        $this->postJson('/api/stocks', [
            'product_id' => $this->foreignProduct->id,
            'quantity' => 50,
        ])->assertNotFound();

        $this->assertDatabaseMissing('stocks', [
            'product_id' => $this->foreignProduct->id,
        ]);
    }

    public function test_cannot_adjust_stock_of_foreign_product(): void
    {
        $this->patchJson('/api/stocks/' . $this->foreignProduct->id . '/adjust', [
            'type' => 'in',
            'quantity' => 5,
        ])->assertNotFound();
    }

    public function test_can_set_stock_for_own_product(): void
    {
        $this->postJson('/api/stocks', [
            'product_id' => $this->productA->id,
            'quantity' => 30,
        ])->assertCreated();

        $this->assertSame(30, Stock::where('product_id', $this->productA->id)->first()->quantity);
    }
}
