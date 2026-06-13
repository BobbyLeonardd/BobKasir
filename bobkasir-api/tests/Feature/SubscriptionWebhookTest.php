<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Business;
use App\Models\Subscription;
use App\Models\SubscriptionPayment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Guards the Midtrans webhook (#4): a paid notification must activate/extend the
 * subscription exactly once, even though Midtrans retries the same webhook.
 */
class SubscriptionWebhookTest extends TestCase
{
    use RefreshDatabase;

    private const SERVER_KEY = 'test-server-key';
    private const ORDER_ID = 'BK-SUB-TEST-1';
    private const GROSS = '30000.00';

    private Subscription $subscription;

    protected function setUp(): void
    {
        parent::setUp();
        config(['midtrans.server_key' => self::SERVER_KEY]);

        $owner = User::create([
            'name' => 'Owner', 'email' => 'owner@example.com',
            'password' => 'password', 'status' => 'active',
        ]);
        $business = Business::create([
            'owner_id' => $owner->id, 'name' => 'Bob Coffee', 'status' => 'active',
        ]);
        $this->subscription = Subscription::create([
            'business_id' => $business->id,
            'owner_id'    => $owner->id,
            'status'      => 'trial',
            'trial_started_at' => now(),
            'trial_expired_at' => now()->addDays(7),
        ]);
        SubscriptionPayment::create([
            'subscription_id'   => $this->subscription->id,
            'business_id'       => $business->id,
            'plan'              => 'weekly',
            'amount'            => 30000,
            'midtrans_order_id' => self::ORDER_ID,
            'status'            => 'pending',
        ]);
    }

    private function signature(string $statusCode = '200'): string
    {
        return hash('sha512', self::ORDER_ID . $statusCode . self::GROSS . self::SERVER_KEY);
    }

    private function settlementPayload(): array
    {
        return [
            'order_id'           => self::ORDER_ID,
            'status_code'        => '200',
            'gross_amount'       => self::GROSS,
            'transaction_status' => 'settlement',
            'transaction_id'     => 'trx-123',
            'payment_type'       => 'qris',
            'signature_key'      => $this->signature(),
        ];
    }

    public function test_settlement_activates_and_extends_subscription(): void
    {
        $response = $this->postJson('/api/midtrans/webhook', $this->settlementPayload());

        $response->assertOk();
        $sub = $this->subscription->fresh();
        $this->assertSame('active', $sub->status);
        $this->assertNotNull($sub->expired_at);
        $this->assertTrue($sub->expired_at->isFuture());
        $this->assertEqualsWithDelta(7, now()->diffInDays($sub->expired_at), 0.01);
        $this->assertSame('settlement', SubscriptionPayment::first()->status);
    }

    public function test_duplicate_settlement_does_not_double_credit(): void
    {
        $this->postJson('/api/midtrans/webhook', $this->settlementPayload())->assertOk();
        $firstExpiry = $this->subscription->fresh()->expired_at;

        // Midtrans re-delivers the same notification.
        $this->postJson('/api/midtrans/webhook', $this->settlementPayload())->assertOk();
        $secondExpiry = $this->subscription->fresh()->expired_at;

        $this->assertEquals(
            $firstExpiry->toIso8601String(),
            $secondExpiry->toIso8601String(),
            'Subscription must not be extended a second time',
        );
        // Crediting (and its audit log) happened exactly once.
        $this->assertSame(1, AuditLog::where('action', 'ubah_langganan')->count());
    }

    public function test_invalid_signature_is_rejected(): void
    {
        $payload = $this->settlementPayload();
        $payload['signature_key'] = 'tampered';

        $this->postJson('/api/midtrans/webhook', $payload)->assertStatus(400);
        $this->assertSame('trial', $this->subscription->fresh()->status);
    }
}
