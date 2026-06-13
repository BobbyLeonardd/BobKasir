<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Product;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The cashier is used by all roles, so reading the catalog must be allowed for
 * karyawan (#1) — while product writes stay owner/manager only.
 */
class ProductAccessTest extends TestCase
{
    use RefreshDatabase;

    private User $employee;

    protected function setUp(): void
    {
        parent::setUp();

        $owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $business = Business::create([
            'owner_id' => $owner->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);

        $this->employee = User::create([
            'name' => 'Kasir', 'email' => 'kasir@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->employee->id,
            'business_id' => $business->id,
            'role' => 'karyawan',
            'status' => 'active',
        ]);

        Product::create([
            'business_id' => $business->id,
            'name' => 'Kopi Susu',
            'price' => 18000,
            'is_active' => true,
        ]);
    }

    public function test_karyawan_can_list_products(): void
    {
        Sanctum::actingAs($this->employee);

        $response = $this->getJson('/api/products');

        $response->assertOk();
        $response->assertJsonFragment(['name' => 'Kopi Susu']);
    }

    public function test_karyawan_can_list_categories(): void
    {
        Sanctum::actingAs($this->employee);

        $this->getJson('/api/categories')->assertOk();
    }

    public function test_karyawan_cannot_create_products(): void
    {
        Sanctum::actingAs($this->employee);

        $this->postJson('/api/products', [
            'name' => 'Hack', 'price' => 1,
        ])->assertStatus(403);
    }
}
