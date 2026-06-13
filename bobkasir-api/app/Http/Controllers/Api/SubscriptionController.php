<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Subscription;
use App\Models\SubscriptionPayment;
use App\Services\NotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;

class SubscriptionController extends Controller
{
    use ApiResponse;

    public function __construct()
    {
        Config::$serverKey = config('midtrans.server_key');
        Config::$isProduction = config('midtrans.is_production');
        Config::$isSanitized = true;
        Config::$is3ds = true;
    }

    // GET /api/subscription/status
    public function status(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $sub = Subscription::where('business_id', $biz)->first();
        if (!$sub) return $this->notFound('Data langganan tidak ditemukan');
        return $this->success([
            'status' => $sub->status,
            'plan' => $sub->plan,
            'started_at' => $sub->started_at?->toISOString(),
            'expired_at' => $sub->expired_at?->toISOString(),
            'trial_expired_at' => $sub->trial_expired_at?->toISOString(),
            'is_active' => $sub->isActive(),
        ]);
    }

    // GET /api/subscription/plans
    public function plans(): JsonResponse
    {
        return $this->success([
            ['slug' => 'weekly', 'name' => 'Mingguan', 'price' => 30000, 'duration_days' => 7],
            ['slug' => 'monthly', 'name' => 'Bulanan', 'price' => 100000, 'duration_days' => 30],
        ]);
    }

    // POST /api/subscription/checkout
    public function checkout(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['plan' => 'required|in:weekly,monthly']);
        if ($v->fails()) return $this->validationError($v->errors());

        $plans = ['weekly' => ['price' => 30000, 'days' => 7, 'name' => 'Mingguan'], 'monthly' => ['price' => 100000, 'days' => 30, 'name' => 'Bulanan']];
        $plan = $plans[$request->plan];
        $user = $request->user();
        $biz = $request->get('_business_id');
        $sub = Subscription::where('business_id', $biz)->first();
        if (!$sub) return $this->notFound();

        $orderId = 'BK-SUB-' . strtoupper(Str::random(8)) . '-' . time();

        // Create payment record
        $payment = SubscriptionPayment::create([
            'subscription_id' => $sub->id,
            'business_id' => $biz,
            'plan' => $request->plan,
            'amount' => $plan['price'],
            'midtrans_order_id' => $orderId,
            'status' => 'pending',
        ]);

        try {
            $snapToken = Snap::getSnapToken([
                'transaction_details' => ['order_id' => $orderId, 'gross_amount' => $plan['price']],
                'customer_details' => ['first_name' => $user->name, 'email' => $user->email],
                'item_details' => [['id' => $request->plan, 'price' => $plan['price'], 'quantity' => 1, 'name' => 'BobKasir ' . $plan['name']]],
            ]);
            return $this->success([
                'snap_token' => $snapToken,
                'order_id' => $orderId,
                'client_key' => config('midtrans.client_key'),
                'snap_url' => config('midtrans.snap_url'),
            ], 'Transaksi berhasil dibuat');
        } catch (\Exception $e) {
            $payment->delete();
            return $this->error('Gagal membuat transaksi Midtrans: ' . $e->getMessage(), 500);
        }
    }

    // POST /api/midtrans/webhook
    public function webhook(Request $request): JsonResponse
    {
        $payload = $request->all();
        // Validate Midtrans signature (timing-safe)
        $serverKey = config('midtrans.server_key');
        $orderId = $payload['order_id'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $signature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if (!hash_equals($signature, (string) ($payload['signature_key'] ?? ''))) {
            return $this->error('Invalid signature', 400);
        }

        $transactionStatus = $payload['transaction_status'] ?? '';
        $isPaid = in_array($transactionStatus, ['settlement', 'capture'], true);

        // Lock the payment row + credit the subscription exactly once. Midtrans
        // retries webhooks, so crediting must be idempotent (PRD §10.4 / §38.2).
        $credited = DB::transaction(function () use ($orderId, $payload, $transactionStatus, $isPaid) {
            $payment = SubscriptionPayment::where('midtrans_order_id', $orderId)
                ->lockForUpdate()
                ->first();
            if (!$payment) {
                return null; // not found
            }

            // Was this payment already credited before this webhook?
            $alreadyCredited = in_array($payment->status, ['settlement', 'capture'], true);

            $payment->update([
                'midtrans_transaction_id' => $payload['transaction_id'] ?? null,
                'payment_type'            => $payload['payment_type'] ?? null,
                'status'                  => $transactionStatus,
                'midtrans_response'       => $payload,
                'paid_at'                 => $isPaid ? ($payment->paid_at ?? now()) : $payment->paid_at,
            ]);

            if (!$isPaid || $alreadyCredited) {
                return false; // found, but nothing to credit
            }

            $plans = ['weekly' => 7, 'monthly' => 30];
            $days  = $plans[$payment->plan] ?? 0;
            $sub   = $payment->subscription;

            // Extend from remaining time if still active, else from now (PRD §10.5).
            $base = ($sub->expired_at && $sub->expired_at->isFuture()) ? $sub->expired_at : now();
            $sub->update([
                'plan'       => $payment->plan,
                'status'     => 'active',
                'started_at' => $sub->started_at ?? now(),
                'expired_at' => $base->copy()->addDays($days),
            ]);

            AuditLog::create([
                'business_id' => $sub->business_id,
                'action'      => 'ubah_langganan',
                'table_name'  => 'subscriptions',
                'record_id'   => $sub->id,
                'new_data'    => ['plan' => $payment->plan, 'expired_at' => $sub->expired_at->toISOString()],
            ]);

            return $payment; // credited on this call
        });

        if ($credited === null) {
            return $this->notFound();
        }

        // Notify owner only on the first successful credit (avoids duplicate alerts).
        if ($credited instanceof SubscriptionPayment) {
            NotificationService::paymentSuccess(
                $credited->subscription->business_id,
                $credited->plan,
                $credited->amount
            );
        }

        return response()->json(['success' => true]);
    }

    // GET /api/subscription/history
    public function history(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $sub = Subscription::where('business_id', $biz)->first();
        if (!$sub) return $this->notFound();
        $payments = SubscriptionPayment::where('subscription_id', $sub->id)->orderByDesc('created_at')->get();
        return $this->success($payments);
    }
}
