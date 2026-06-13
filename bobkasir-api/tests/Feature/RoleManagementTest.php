<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Subscription;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Guards H5: updating a member's role must be restricted to a valid enum
 * (manager/karyawan) and must never touch the owner account.
 */
class RoleManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $member;

    protected function setUp(): void
    {
        parent::setUp();

        $this->owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $business = Business::create([
            'owner_id' => $this->owner->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->owner->id, 'business_id' => $business->id,
            'role' => 'owner', 'status' => 'active',
        ]);
        Subscription::create([
            'business_id' => $business->id, 'owner_id' => $this->owner->id,
            'status' => 'active', 'expired_at' => now()->addDays(30),
        ]);

        $this->member = User::create([
            'name' => 'Staff', 'email' => 'staff@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->member->id, 'business_id' => $business->id,
            'role' => 'karyawan', 'status' => 'active',
        ]);

        Sanctum::actingAs($this->owner);
    }

    public function test_cannot_escalate_member_to_owner(): void
    {
        $this->putJson('/api/users/' . $this->member->id, [
            'name' => 'Staff', 'role' => 'owner',
        ])->assertStatus(422);

        $this->assertSame('karyawan', UserBusinessRole::where('user_id', $this->member->id)->first()->role);
    }

    public function test_can_promote_member_to_manager(): void
    {
        $this->putJson('/api/users/' . $this->member->id, [
            'name' => 'Staff', 'role' => 'manager',
        ])->assertOk();

        $this->assertSame('manager', UserBusinessRole::where('user_id', $this->member->id)->first()->role);
    }

    public function test_cannot_edit_owner_account(): void
    {
        $this->putJson('/api/users/' . $this->owner->id, [
            'name' => 'Hacked', 'role' => 'karyawan',
        ])->assertStatus(403);

        $this->assertSame('owner', UserBusinessRole::where('user_id', $this->owner->id)->first()->role);
    }
}
