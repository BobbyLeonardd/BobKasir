<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\CancelRequest;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\PrintLog;
use App\Models\RefundRequest;
use App\Services\NotificationService;
use App\Services\OrderCreationService;
use App\Services\StockService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    use ApiResponse;

    // ──────────────────────────────────────────
    // GET /api/orders
    // ──────────────────────────────────────────
    public function index(Request $request): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $role       = $request->get('_user_role');

        $query = Order::where('business_id', $businessId)
            ->with(['items', 'payments', 'user', 'cancelRequest', 'refundRequest'])
            ->orderByDesc('ordered_at');

        // Filters
        if ($request->filled('status')) {
            $query->where('order_status', $request->status);
        }
        if ($request->filled('cashier_id')) {
            $query->where('user_id', $request->cashier_id);
        }
        if ($request->filled('date_from')) {
            $query->whereDate('ordered_at', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('ordered_at', '<=', $request->date_to);
        }
        if ($request->filled('outlet_id')) {
            $query->where('outlet_id', $request->outlet_id);
        }

        $perPage = $request->get('per_page', 20);
        $orders  = $query->paginate($perPage);

        return $this->success($orders);
    }

    // ──────────────────────────────────────────
    // POST /api/orders
    // ──────────────────────────────────────────
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'items'                => 'required|array|min:1',
            'items.*.product_id'   => 'nullable|string',
            'items.*.product_name' => 'required|string',
            'items.*.price'        => 'required|integer|min:0',
            'items.*.qty'          => 'required|integer|min:1',
            'payments'             => 'required|array|min:1',
            'payments.*.method'    => 'required|string',
            'payments.*.amount'    => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        // Totals are recomputed server-side in OrderCreationService — the client
        // values (subtotal/grand_total/item subtotal) are intentionally ignored.
        try {
            $result = OrderCreationService::create(
                $request->all(),
                $request->user(),
                $request->get('_business_id'),
                $request->get('_user_role'),
                $request->get('_outlet_id'),
                $request->device_id,
                $request->ip(),
                true
            );

            return $this->success(
                $result['order'],
                $result['duplicate']
                    ? 'Transaksi sudah tersimpan sebelumnya'
                    : 'Transaksi berhasil disimpan',
                $result['duplicate'] ? 200 : 201
            );
        } catch (\Exception $e) {
            if ($e->getCode() === 409) {
                return $this->error($e->getMessage(), 409);
            }
            return $this->error('Gagal menyimpan transaksi: ' . $e->getMessage(), 500);
        }
    }

    // ──────────────────────────────────────────
    // GET /api/orders/{id}
    // ──────────────────────────────────────────
    public function show(Request $request, string $id): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $order      = Order::where('business_id', $businessId)
            ->with(['items', 'payments', 'user', 'cancelRequest.requester', 'refundRequest.requester'])
            ->find($id);

        if (!$order) {
            return $this->notFound('Order tidak ditemukan');
        }
        return $this->success($order);
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/print-log
    // ──────────────────────────────────────────
    public function printLog(Request $request, string $id): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $order      = Order::where('business_id', $businessId)->find($id);
        if (!$order) return $this->notFound();

        PrintLog::create([
            'order_id'  => $id,
            'user_id'   => $request->user()->id,
            'type'      => $request->input('type', 'customer'),
            'device_id' => $request->device_id,
        ]);

        AuditLog::create([
            'business_id' => $businessId,
            'user_id'     => $request->user()->id,
            'role'        => $request->get('_user_role'),
            'action'      => 'cetak_ulang_struk',
            'table_name'  => 'orders',
            'record_id'   => $id,
            'new_data'    => ['type' => $request->input('type', 'customer')],
            'ip_address'  => $request->ip(),
        ]);

        return $this->success(null, 'Cetak ulang tercatat');
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/cancel-request
    // ──────────────────────────────────────────
    public function cancelRequest(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), ['reason' => 'required|string']);
        if ($validator->fails()) return $this->validationError($validator->errors());

        $businessId = $request->get('_business_id');
        $role       = $request->get('_user_role');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->find($id);

        if (!$order) return $this->notFound();
        if ($order->order_status !== 'completed') {
            return $this->error('Order tidak bisa dicancel');
        }

        // Owner/manager: direct cancel
        if (in_array($role, ['owner', 'manager'])) {
            $order->update(['order_status' => 'cancelled']);
            AuditLog::create([
                'business_id' => $businessId, 'user_id' => $user->id,
                'role' => $role, 'action' => 'approve_cancel',
                'table_name' => 'orders', 'record_id' => $id,
                'new_data' => ['reason' => $request->reason],
                'ip_address' => $request->ip(),
            ]);
            return $this->success(null, 'Order dibatalkan');
        }

        // Karyawan: create cancel request
        $req = CancelRequest::create([
            'order_id'     => $id,
            'requested_by' => $user->id,
            'reason'       => $request->reason,
            'status'       => 'pending',
        ]);
        $order->update(['order_status' => 'cancel_requested']);

        // Notify owner & manager (PRD §32.1)
        NotificationService::cancelRequested($businessId, $order->order_number ?? $id, $user->name, $id);

        AuditLog::create([
            'business_id' => $businessId, 'user_id' => $user->id,
            'role' => $role, 'action' => 'request_cancel',
            'table_name' => 'orders', 'record_id' => $id,
            'new_data' => ['reason' => $request->reason],
            'ip_address' => $request->ip(),
        ]);

        return $this->success($req, 'Request cancel terkirim', 201);    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/cancel-approve
    // ──────────────────────────────────────────
    public function cancelApprove(Request $request, string $id): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->with(['cancelRequest', 'items'])->find($id);

        if (!$order || !$order->cancelRequest) return $this->notFound();

        DB::transaction(function () use ($order, $user, $request, $businessId) {
            $order->cancelRequest->update([
                'status' => 'approved', 'reviewed_by' => $user->id, 'reviewed_at' => now(),
            ]);
            $order->update(['order_status' => 'cancelled']);

            // Restore stock
            $itemsForStock = $order->items->map(fn($i) => [
                'product_id' => $i->product_id,
                'qty'        => $i->qty,
            ])->toArray();
            StockService::restoreForCancel($order->id, $itemsForStock, $user->id, $order->outlet_id);

            AuditLog::create([
                'business_id' => $businessId, 'user_id' => $user->id,
                'role' => $request->get('_user_role'), 'action' => 'approve_cancel',
                'table_name' => 'orders', 'record_id' => $order->id,
                'ip_address' => $request->ip(),
            ]);
        });

        return $this->success(null, 'Cancel disetujui');
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/cancel-reject
    // ──────────────────────────────────────────
    public function cancelReject(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), ['note' => 'nullable|string']);
        if ($validator->fails()) return $this->validationError($validator->errors());

        $businessId = $request->get('_business_id');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->with('cancelRequest')->find($id);
        if (!$order || !$order->cancelRequest) return $this->notFound();

        DB::transaction(function () use ($order, $user, $request, $businessId) {
            $order->cancelRequest->update([
                'status' => 'rejected', 'reviewed_by' => $user->id,
                'reviewed_at' => now(), 'review_note' => $request->note,
            ]);
            $order->update(['order_status' => 'completed']);
            AuditLog::create([
                'business_id' => $businessId, 'user_id' => $user->id,
                'role' => $request->get('_user_role'), 'action' => 'reject_cancel',
                'table_name' => 'orders', 'record_id' => $order->id,
                'ip_address' => $request->ip(),
            ]);
        });

        return $this->success(null, 'Cancel ditolak');
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/refund-request
    // ──────────────────────────────────────────
    public function refundRequest(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'reason' => 'required|string',
            'type'   => 'required|in:full,partial',
            'amount' => 'nullable|integer|min:1',
        ]);
        if ($validator->fails()) return $this->validationError($validator->errors());

        $businessId = $request->get('_business_id');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->find($id);
        if (!$order) return $this->notFound();

        $req = RefundRequest::create([
            'order_id'     => $id,
            'requested_by' => $user->id,
            'type'         => $request->type,
            'amount'       => $request->type === 'partial' ? $request->amount : null,
            'reason'       => $request->reason,
            'status'       => 'pending',
        ]);
        $order->update(['order_status' => 'refund_requested']);

        // Notify owner & manager (PRD §32.1)
        NotificationService::refundRequested($businessId, $order->order_number ?? $id, $user->name, $id);

        AuditLog::create([
            'business_id' => $businessId, 'user_id' => $user->id,
            'role' => $request->get('_user_role'), 'action' => 'request_refund',
            'table_name' => 'orders', 'record_id' => $id,
            'new_data' => ['type' => $request->type, 'reason' => $request->reason],
            'ip_address' => $request->ip(),
        ]);

        return $this->success($req, 'Request refund terkirim', 201);
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/refund-approve
    // ──────────────────────────────────────────
    public function refundApprove(Request $request, string $id): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->with('refundRequest')->find($id);
        if (!$order || !$order->refundRequest) return $this->notFound();

        DB::transaction(function () use ($order, $user, $request, $businessId) {
            $order->refundRequest->update([
                'status' => 'approved', 'reviewed_by' => $user->id, 'reviewed_at' => now(),
            ]);
            $order->update(['order_status' => 'refunded', 'payment_status' => 'refunded']);
            AuditLog::create([
                'business_id' => $businessId, 'user_id' => $user->id,
                'role' => $request->get('_user_role'), 'action' => 'approve_refund',
                'table_name' => 'orders', 'record_id' => $order->id,
                'ip_address' => $request->ip(),
            ]);
        });

        return $this->success(null, 'Refund disetujui');
    }

    // ──────────────────────────────────────────
    // POST /api/orders/{id}/refund-reject
    // ──────────────────────────────────────────
    public function refundReject(Request $request, string $id): JsonResponse
    {
        $businessId = $request->get('_business_id');
        $user       = $request->user();
        $order      = Order::where('business_id', $businessId)->with('refundRequest')->find($id);
        if (!$order || !$order->refundRequest) return $this->notFound();

        DB::transaction(function () use ($order, $user, $request, $businessId) {
            $order->refundRequest->update([
                'status' => 'rejected', 'reviewed_by' => $user->id,
                'reviewed_at' => now(), 'review_note' => $request->note,
            ]);
            $order->update(['order_status' => 'completed']);
            AuditLog::create([
                'business_id' => $businessId, 'user_id' => $user->id,
                'role' => $request->get('_user_role'), 'action' => 'reject_refund',
                'table_name' => 'orders', 'record_id' => $order->id,
                'ip_address' => $request->ip(),
            ]);
        });

        return $this->success(null, 'Refund ditolak');
    }
}
