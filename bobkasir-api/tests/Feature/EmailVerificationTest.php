<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

/**
 * Guards C2: email verification must require a valid HMAC-signed URL (APP_KEY +
 * expiry). A bare id+sha1(email) link must NOT be accepted.
 */
class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'pending',
        ]);
    }

    public function test_valid_signed_link_verifies_email(): void
    {
        $url = URL::temporarySignedRoute(
            'verification.verify',
            now()->addMinutes(60),
            ['id' => $this->user->id, 'hash' => sha1($this->user->email)],
        );

        $this->get($url)->assertOk();

        $fresh = $this->user->fresh();
        $this->assertNotNull($fresh->email_verified_at);
        $this->assertSame('active', $fresh->status);
    }

    public function test_unsigned_link_is_rejected(): void
    {
        // No signature/expiry — this is the forgeable link the old code accepted.
        $this->getJson('/api/auth/verify-email/' . $this->user->id . '/' . sha1($this->user->email))
            ->assertForbidden();

        $this->assertNull($this->user->fresh()->email_verified_at);
    }

    public function test_tampered_signature_is_rejected(): void
    {
        $url = URL::temporarySignedRoute(
            'verification.verify',
            now()->addMinutes(60),
            ['id' => $this->user->id, 'hash' => sha1($this->user->email)],
        ) . 'tampered';

        $this->get($url)->assertForbidden();
        $this->assertNull($this->user->fresh()->email_verified_at);
    }
}
