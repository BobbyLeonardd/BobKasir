<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\Subscription;
use App\Models\Tenant;
use App\Services\FcmService;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class SubscriptionController extends Controller
{
    public function __construct(
        private MidtransService $midtrans,
        private FcmService $fcm
    ) {}

    public function current(Request $request)
    {
        $tenant = $request->user()->tenant;
        $sub = Subscription::where('tenant_id', $tenant->id)
            ->whereIn('status', ['active', 'pending'])
            ->latest()
            ->first();

        return response()->json([
            'data' => [
                'tenant_status' => $tenant->subscription_status,
                'trial_until' => $tenant->trial_until,
                'subscription_expires_at' => $tenant->subscription_expires_at,
                'has_full_access' => $tenant->hasFullAccess(),
                'active_subscription' => $sub,
            ],
        ]);
    }

    public function checkout(Request $request)
    {
        $data = $request->validate([
            'package' => 'required|in:weekly,monthly',
        ]);

        $user = $request->user();
        $tenant = $user->tenant;
        $amount = $data['package'] === 'weekly' ? 15000 : 50000; // in IDR
        $orderId = 'SUB-' . $tenant->id . '-' . time();

        $sub = Subscription::create([
            'tenant_id' => $tenant->id,
            'package' => $data['package'],
            'start_date' => now()->toDateString(),
            'end_date' => now()->addDays($data['package'] === 'weekly' ? 7 : 30)->toDateString(),
            'status' => 'pending',
            'midtrans_order_id' => $orderId,
        ]);

        $snapData = $this->midtrans->createSnapTransaction($orderId, $amount, [
            'first_name' => $user->name,
            'email' => $user->email,
        ]);

        return response()->json([
            'message' => 'Transaksi Midtrans dibuat.',
            'snap_token' => $snapData['token'] ?? null,
            'snap_url' => $snapData['redirect_url'] ?? null,
            'subscription_id' => $sub->id,
        ]);
    }

    public function manualPayment(Request $request)
    {
        $data = $request->validate([
            'package' => 'required|in:weekly,monthly',
            'proof' => 'required|image|max:2048',
        ]);

        $tenant = $request->user()->tenant;
        $path = $request->file('proof')->store("payment_proofs/{$tenant->id}", 'public');

        Subscription::create([
            'tenant_id' => $tenant->id,
            'package' => $data['package'],
            'start_date' => now()->toDateString(),
            'end_date' => now()->addDays($data['package'] === 'weekly' ? 7 : 30)->toDateString(),
            'status' => 'pending',
            'payment_method' => 'manual',
            'manual_proof' => Storage::url($path),
        ]);

        return response()->json(['message' => 'Bukti pembayaran dikirim. Menunggu konfirmasi admin.']);
    }

    /** POST /subscriptions/webhook/midtrans */
    public function webhook(Request $request)
    {
        $payload = $request->all();
        $orderId = $payload['order_id'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $signatureKey = $payload['signature_key'] ?? '';

        if (!$this->midtrans->verifySignature($orderId, $statusCode, $grossAmount, $signatureKey)) {
            Log::warning("Midtrans webhook signature invalid for order: $orderId");
            return response()->json(['message' => 'Invalid signature.'], 401);
        }

        $sub = Subscription::where('midtrans_order_id', $orderId)->first();
        if (!$sub) {
            return response()->json(['message' => 'Subscription not found.'], 404);
        }

        $transactionStatus = $payload['transaction_status'] ?? '';
        $fraudStatus = $payload['fraud_status'] ?? '';

        if ($transactionStatus === 'capture' && $fraudStatus === 'accept') {
            $this->activateSubscription($sub, $payload['transaction_id'] ?? null);
        } elseif ($transactionStatus === 'settlement') {
            $this->activateSubscription($sub, $payload['transaction_id'] ?? null);
        } elseif (in_array($transactionStatus, ['deny', 'expire', 'cancel'])) {
            $sub->update(['status' => 'cancelled']);
        }

        return response()->json(['message' => 'OK']);
    }

    private function activateSubscription(Subscription $sub, ?string $txId): void
    {
        $tenant = Tenant::find($sub->tenant_id);
        $duration = $sub->getDurationDays();

        // Upgrade: overwrite; same/downgrade: extend from expiry or now
        $base = now();
        if ($tenant->subscription_status === 'active' && $tenant->subscription_expires_at) {
            $existingExpiry = $tenant->subscription_expires_at;
            // Downgrade: queue after current period
            if ($sub->package === 'weekly' && $existingExpiry->isAfter($base)) {
                // queue — just activate from expiry
                $base = $existingExpiry;
            }
        }

        $newExpiry = $base->copy()->addDays($duration);

        $sub->update([
            'status' => 'active',
            'start_date' => $base->toDateString(),
            'end_date' => $newExpiry->toDateString(),
            'midtrans_transaction_id' => $txId,
        ]);

        $tenant->update([
            'subscription_status' => 'active',
            'subscription_expires_at' => $newExpiry,
        ]);

        // Push + in-app notification
        $title = 'Pembayaran Berhasil';
        $body = "Langganan {$sub->package} aktif hingga {$newExpiry->format('d M Y')}.";

        $ownerUser = $tenant->owner;
        if ($ownerUser) {
            AppNotification::create([
                'user_id' => $ownerUser->id,
                'tenant_id' => $tenant->id,
                'type' => 'payment_success',
                'title' => $title,
                'body' => $body,
                'data' => ['subscription_id' => $sub->id],
            ]);
            $this->fcm->sendToUsers([$ownerUser->id], $title, $body, [
                'type' => 'payment_success',
                'subscription_id' => (string) $sub->id,
            ]);
        }
    }

    public function cancel(Request $request)
    {
        $sub = Subscription::where('tenant_id', $request->user()->tenant_id)
            ->where('status', 'active')
            ->latest()
            ->first();

        if (!$sub) {
            return response()->json(['message' => 'Tidak ada langganan aktif.'], 404);
        }

        $sub->update(['status' => 'cancelled']);
        return response()->json(['message' => 'Langganan dibatalkan.']);
    }
}
