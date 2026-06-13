<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\User;
use App\Models\UserBusinessRole;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Guards H2: Sanctum tokens carry an expiry, so a past-due token is rejected.
 */
class TokenExpiryTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $business = Business::create([
            'owner_id' => $this->user->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);
        UserBusinessRole::create([
            'user_id' => $this->user->id, 'business_id' => $business->id,
            'role' => 'owner', 'status' => 'active',
        ]);
    }

    public function test_expired_token_is_rejected(): void
    {
        $token = $this->user->createToken('t', ['*'], now()->subMinute())->plainTextToken;

        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_valid_token_is_accepted(): void
    {
        $token = $this->user->createToken('t', ['*'], now()->addDay())->plainTextToken;

        $this->withToken($token)->getJson('/api/auth/me')->assertOk();
    }
}
