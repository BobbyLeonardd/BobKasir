<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\CancelRequest;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function __construct(private FcmService $fcm) {}

    public function index(Request $request)
    {
        $query = Order::where('tenant_id', $request->user()->tenant_id)
            ->with(['user:id,name', 'items', 'payments', 'cancelRequest']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('cashier_id')) {
            $query->where('user_id', $request->cashier_id);
        }
        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        return response()->json(['data' => $query->latest()->paginate(30)]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'customer_name' => 'nullable|string|max:100',
            'table_number' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'local_id' => 'nullable|string|unique:orders,local_id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'nullable|integer',
            'items.*.product_name' => 'required|string',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.price' => 'required|integer|min:0',
            'items.*.subtotal' => 'required|integer|min:0',
            'items.*.notes' => 'nullable|string',
            'payments' => 'required|array|min:1',
            'payments.*.method' => 'required|string',
            'payments.*.amount' => 'required|integer|min:0',
            'payments.*.change_amount' => 'nullable|integer|min:0',
            'payments.*.split_index' => 'nullable|integer|min:1',
        ]);

        $user = $request->user();
        $total = collect($data['items'])->sum('subtotal');

        $order = DB::transaction(function () use ($data, $user, $total) {
            $order = Order::create([
                'tenant_id' => $user->tenant_id,
                'user_id' => $user->id,
                'cashier_name' => $user->name,
                'customer_name' => $data['customer_name'] ?? null,
                'table_number' => $data['table_number'] ?? null,
                'notes' => $data['notes'] ?? null,
                'total' => $total,
                'payment_status' => 'paid',
                'status' => 'completed',
                'sync_status' => 'synced',
                'local_id' => $data['local_id'] ?? null,
            ]);

            foreach ($data['items'] as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'] ?? null,
                    'product_name' => $item['product_name'],
                    'qty' => $item['qty'],
                    'price' => $item['price'],
                    'subtotal' => $item['subtotal'],
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            foreach ($data['payments'] as $idx => $payment) {
                Payment::create([
                    'order_id' => $order->id,
                    'method' => $payment['method'],
                    'amount' => $payment['amount'],
                    'change_amount' => $payment['change_amount'] ?? 0,
                    'split_index' => $payment['split_index'] ?? ($idx + 1),
                    'paid_at' => now(),
                ]);
            }

            return $order;
        });

        AuditLog::record('create_order', $order);

        return response()->json([
            'message' => 'Order berhasil disimpan.',
            'data' => $order->load(['items', 'payments']),
        ], 201);
    }

    public function show(Request $request, int $id)
    {
        $order = Order::where('tenant_id', $request->user()->tenant_id)
            ->with(['user:id,name,role', 'items', 'payments', 'cancelRequest.requester:id,name'])
            ->findOrFail($id);
        return response()->json(['data' => $order]);
    }

    public function cancel(Request $request, int $id)
    {
        $data = $request->validate(['reason' => 'required|string']);
        $order = Order::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);

        if ($order->status === 'cancelled') {
            return response()->json(['message' => 'Order sudah dibatalkan.'], 422);
        }

        $old = ['status' => $order->status];
        $order->update(['status' => 'cancelled']);
        AuditLog::record('cancel_order', $order, $old, ['reason' => $data['reason']]);

        return response()->json(['message' => 'Order dibatalkan.']);
    }

    public function requestCancel(Request $request, int $id)
    {
        $data = $request->validate(['reason' => 'required|string']);
        $order = Order::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);

        if ($order->status !== 'completed') {
            return response()->json(['message' => 'Hanya order selesai yang bisa diminta cancel.'], 422);
        }

        $existing = CancelRequest::where('order_id', $id)->where('status', 'pending')->first();
        if ($existing) {
            return response()->json(['message' => 'Request cancel sudah ada dan menunggu persetujuan.'], 422);
        }

        $cancelReq = CancelRequest::create([
            'order_id' => $id,
            'requester_user_id' => $request->user()->id,
            'reason' => $data['reason'],
            'status' => 'pending',
        ]);

        $order->update(['status' => 'request_cancel']);

        // Notify owner and admin
        $this->fcm->sendToTenantAdmins(
            $request->user()->tenant_id,
            'Request Cancel Order',
            "Kasir {$request->user()->name} meminta cancel order #{$id}: {$data['reason']}",
            ['type' => 'cancel_request', 'order_id' => (string) $id]
        );

        return response()->json(['message' => 'Request cancel dikirim.', 'data' => $cancelReq]);
    }

    public function approveCancel(Request $request, int $id)
    {
        $order = Order::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $cancelReq = CancelRequest::where('order_id', $id)->where('status', 'pending')->firstOrFail();

        $cancelReq->update(['status' => 'approved', 'approved_by' => $request->user()->id]);
        $order->update(['status' => 'cancelled']);

        AuditLog::record('approve_cancel', $order);

        // Notify cashier
        $this->fcm->sendToUsers(
            [$cancelReq->requester_user_id],
            'Request Cancel Disetujui',
            "Request cancel order #{$id} telah disetujui.",
            ['type' => 'cancel_approved', 'order_id' => (string) $id]
        );

        return response()->json(['message' => 'Cancel disetujui.']);
    }

    public function rejectCancel(Request $request, int $id)
    {
        $order = Order::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $cancelReq = CancelRequest::where('order_id', $id)->where('status', 'pending')->firstOrFail();

        $cancelReq->update(['status' => 'rejected', 'approved_by' => $request->user()->id]);
        $order->update(['status' => 'completed']);

        AuditLog::record('reject_cancel', $order);

        $this->fcm->sendToUsers(
            [$cancelReq->requester_user_id],
            'Request Cancel Ditolak',
            "Request cancel order #{$id} ditolak.",
            ['type' => 'cancel_rejected', 'order_id' => (string) $id]
        );

        return response()->json(['message' => 'Cancel ditolak.']);
    }

    /** POST /sync/orders — batch sync from offline device */
    public function sync(Request $request)
    {
        $data = $request->validate([
            'orders' => 'required|array',
            'orders.*.local_id' => 'required|string',
            'orders.*.customer_name' => 'nullable|string',
            'orders.*.table_number' => 'nullable|string',
            'orders.*.notes' => 'nullable|string',
            'orders.*.items' => 'required|array|min:1',
            'orders.*.items.*.product_name' => 'required|string',
            'orders.*.items.*.qty' => 'required|integer|min:1',
            'orders.*.items.*.price' => 'required|integer|min:0',
            'orders.*.items.*.subtotal' => 'required|integer|min:0',
            'orders.*.payments' => 'required|array|min:1',
            'orders.*.payments.*.method' => 'required|string',
            'orders.*.payments.*.amount' => 'required|integer|min:0',
            'orders.*.needs_review' => 'nullable|boolean',
            'orders.*.created_at' => 'nullable|date',
        ]);

        $user = $request->user();
        $synced = [];
        $failed = [];

        foreach ($data['orders'] as $rawOrder) {
            try {
                $existing = Order::where('local_id', $rawOrder['local_id'])->first();
                if ($existing) {
                    $synced[] = ['local_id' => $rawOrder['local_id'], 'server_id' => $existing->id];
                    continue;
                }

                $total = collect($rawOrder['items'])->sum('subtotal');

                $order = DB::transaction(function () use ($rawOrder, $user, $total) {
                    $order = Order::create([
                        'tenant_id' => $user->tenant_id,
                        'user_id' => $user->id,
                        'cashier_name' => $user->name,
                        'customer_name' => $rawOrder['customer_name'] ?? null,
                        'table_number' => $rawOrder['table_number'] ?? null,
                        'notes' => $rawOrder['notes'] ?? null,
                        'total' => $total,
                        'payment_status' => 'paid',
                        'status' => 'completed',
                        'sync_status' => 'synced',
                        'local_id' => $rawOrder['local_id'],
                        'needs_review' => $rawOrder['needs_review'] ?? false,
                        'created_at' => $rawOrder['created_at'] ?? now(),
                    ]);

                    foreach ($rawOrder['items'] as $item) {
                        OrderItem::create([
                            'order_id' => $order->id,
                            'product_id' => $item['product_id'] ?? null,
                            'product_name' => $item['product_name'],
                            'qty' => $item['qty'],
                            'price' => $item['price'],
                            'subtotal' => $item['subtotal'],
                            'notes' => $item['notes'] ?? null,
                        ]);
                    }

                    foreach ($rawOrder['payments'] as $idx => $payment) {
                        Payment::create([
                            'order_id' => $order->id,
                            'method' => $payment['method'],
                            'amount' => $payment['amount'],
                            'change_amount' => $payment['change_amount'] ?? 0,
                            'split_index' => $idx + 1,
                            'paid_at' => now(),
                        ]);
                    }

                    return $order;
                });

                $synced[] = ['local_id' => $rawOrder['local_id'], 'server_id' => $order->id];
            } catch (\Throwable $e) {
                $failed[] = ['local_id' => $rawOrder['local_id'], 'reason' => $e->getMessage()];
            }
        }

        return response()->json(['synced' => $synced, 'failed' => $failed]);
    }
}
