<?php

namespace App\Http\Controllers;

use App\Models\Openbill;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OpenbillController extends Controller
{
    public function index(Request $request)
    {
        $bills = Openbill::where('tenant_id', $request->user()->tenant_id)
            ->with('user:id,name')
            ->latest()
            ->get();
        return response()->json(['data' => $bills]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'label' => 'nullable|string|max:100',
            'items_snapshot' => 'required|array|min:1',
            'items_snapshot.*.product_name' => 'required|string',
            'items_snapshot.*.qty' => 'required|integer|min:1',
            'items_snapshot.*.price' => 'required|integer|min:0',
        ]);

        $bill = Openbill::create([
            'tenant_id' => $request->user()->tenant_id,
            'user_id' => $request->user()->id,
            'label' => $data['label'] ?? 'Tanpa nama',
            'items_snapshot' => $data['items_snapshot'],
        ]);

        return response()->json(['message' => 'Openbill disimpan.', 'data' => $bill], 201);
    }

    public function update(Request $request, int $id)
    {
        $bill = Openbill::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $data = $request->validate([
            'label' => 'nullable|string|max:100',
            'items_snapshot' => 'required|array|min:1',
        ]);
        $bill->update($data);
        return response()->json(['message' => 'Openbill diperbarui.', 'data' => $bill]);
    }

    public function destroy(Request $request, int $id)
    {
        $bill = Openbill::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $bill->delete();
        return response()->json(['message' => 'Openbill dihapus.']);
    }

    /** POST /openbills/{id}/checkout — convert to order */
    public function checkout(Request $request, int $id)
    {
        $bill = Openbill::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $data = $request->validate([
            'customer_name' => 'nullable|string|max:100',
            'table_number' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'payments' => 'required|array|min:1',
            'payments.*.method' => 'required|string',
            'payments.*.amount' => 'required|integer|min:0',
            'payments.*.change_amount' => 'nullable|integer|min:0',
        ]);

        $user = $request->user();
        $items = $bill->items_snapshot;
        $total = collect($items)->sum(fn($i) => $i['qty'] * $i['price']);

        $order = DB::transaction(function () use ($data, $user, $items, $total, $bill) {
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
            ]);

            foreach ($items as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $item['product_id'] ?? null,
                    'product_name' => $item['product_name'],
                    'qty' => $item['qty'],
                    'price' => $item['price'],
                    'subtotal' => $item['qty'] * $item['price'],
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            foreach ($data['payments'] as $idx => $payment) {
                Payment::create([
                    'order_id' => $order->id,
                    'method' => $payment['method'],
                    'amount' => $payment['amount'],
                    'change_amount' => $payment['change_amount'] ?? 0,
                    'split_index' => $idx + 1,
                    'paid_at' => now(),
                ]);
            }

            $bill->delete();
            return $order;
        });

        return response()->json([
            'message' => 'Openbill berhasil di-checkout.',
            'data' => $order->load(['items', 'payments']),
        ], 201);
    }
}
