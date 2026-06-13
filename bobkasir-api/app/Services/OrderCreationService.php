<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\ServiceCharge;
use App\Models\Tax;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Single source of truth for creating an order.
 *
 * Money is computed server-side from authoritative product prices — the client
 * is never trusted for totals (PRD §38.3). Creation is idempotent on
 * (business_id, local_order_id) so retried offline syncs never duplicate an
 * order (PRD §26.5).
 *
 * Used by both OrderController::store (online checkout) and
 * SyncController::push (offline replay).
 */
class OrderCreationService
{
    /**
     * @param  array  $data  Normalized order payload (items, payments, totals, customer info).
     * @return array{order: Order, duplicate: bool, conflicts: array}
     */
    public static function create(
        array $data,
        User $user,
        string $businessId,
        ?string $role,
        ?string $outletId,
        ?string $deviceId,
        ?string $ipAddress = null,
        bool $isOnline = false
    ): array {
        // ── Idempotency guard (PRD §26.5) ──────────────────────────────
        $localOrderId = $data['local_order_id'] ?? null;
        if ($localOrderId) {
            $existing = Order::where('business_id', $businessId)
                ->where('local_order_id', $localOrderId)
                ->first();
            if ($existing) {
                return [
                    'order'     => $existing->load('items', 'payments'),
                    'duplicate' => true,
                    'conflicts' => [],
                ];
            }
        }

        $rawItems    = $data['items'] ?? [];
        $rawPayments = $data['payments'] ?? [];

        return DB::transaction(function () use (
            $data, $user, $businessId, $role, $outletId, $deviceId,
            $ipAddress, $localOrderId, $rawItems, $rawPayments, $isOnline
        ) {
            // ── Recompute item lines from authoritative product prices ──
            $items    = [];
            $subtotal = 0;
            foreach ($rawItems as $raw) {
                $qty       = max(1, (int) ($raw['qty'] ?? 1));
                $productId = $raw['product_id'] ?? null;

                // Default to client-provided values; overridden by DB price below.
                $price = max(0, (int) ($raw['price'] ?? 0));
                $name  = $raw['product_name'] ?? 'Item';

                if ($productId) {
                    // withTrashed: a product disabled/deleted while offline must
                    // still resolve to its real price for old transactions (PRD §26.6).
                    $product = Product::withTrashed()
                        ->where('business_id', $businessId)
                        ->find($productId);
                    if ($product) {
                        $price = (int) $product->price;   // authoritative snapshot
                        $name  = $product->name;
                    }
                }

                $discount     = max(0, (int) ($raw['discount'] ?? 0));
                $lineSubtotal = max(0, $price * $qty - $discount);
                $subtotal    += $lineSubtotal;

                $items[] = [
                    'product_id'            => $productId,
                    'product_name_snapshot' => $name,
                    'price_snapshot'        => $price,
                    'qty'                   => $qty,
                    'discount'              => $discount,
                    'note'                  => $raw['note'] ?? null,
                    'subtotal'              => $lineSubtotal,
                ];
            }

            // ── Totals (server-authoritative, PRD §15.5) ───────────────
            $discountTotal = min(max(0, (int) ($data['discount_total'] ?? 0)), $subtotal);

            // Tax & service charge come from the business's active config — never
            // trusted from the client. Both apply to the after-discount subtotal.
            $taxableBase  = $subtotal - $discountTotal;
            $taxRate      = (float) Tax::where('business_id', $businessId)
                ->where('is_active', true)->sum('rate');
            $serviceRate  = (float) ServiceCharge::where('business_id', $businessId)
                ->where('is_active', true)->sum('rate');
            $taxTotal     = (int) round($taxableBase * $taxRate / 100);
            $serviceTotal = (int) round($taxableBase * $serviceRate / 100);
            $grandTotal   = max(0, $subtotal - $discountTotal + $taxTotal + $serviceTotal);

            if ($isOnline && isset($data['grand_total'])) {
                $clientGrandTotal = (int) $data['grand_total'];
                if ($clientGrandTotal !== $grandTotal) {
                    throw new \Exception('Harga produk atau pajak telah berubah. Silakan muat ulang menu Kasir.', 409);
                }
            }

            // ── Payments (server-recomputed paid/change) ───────────────
            $payments   = [];
            $paidAmount = 0;
            foreach ($rawPayments as $p) {
                $amount = max(0, (int) ($p['amount'] ?? 0));
                if ($amount <= 0) {
                    continue;
                }
                $paidAmount += $amount;
                $payments[]  = ['method' => $p['method'] ?? 'cash', 'amount' => $amount];
            }
            $changeAmount  = max(0, $paidAmount - $grandTotal);
            $paymentMethod = count($payments) > 1
                ? 'Split'
                : ($payments[0]['method'] ?? 'cash');
            $paymentStatus = $paidAmount >= $grandTotal ? 'paid' : 'unpaid';

            // ── Server-authoritative order number (PRD §25.3) ──────────
            $count = Order::where('business_id', $businessId)
                ->whereDate('ordered_at', today())
                ->lockForUpdate()
                ->count();
            $orderNumber = 'BK-' . now()->format('Ymd') . '-'
                . str_pad($count + 1, 4, '0', STR_PAD_LEFT);

            $order = Order::create([
                'business_id'          => $businessId,
                'outlet_id'            => $outletId ?? ($data['outlet_id'] ?? null),
                'user_id'              => $user->id,
                'shift_id'             => $data['shift_id'] ?? null,
                'device_id'            => $deviceId ?? ($data['device_id'] ?? null),
                'order_number'         => $orderNumber,
                'local_order_id'       => $localOrderId,
                'customer_name'        => $data['customer_name'] ?? null,
                'table_number'         => $data['table_number'] ?? null,
                'customer_phone'       => $data['customer_phone'] ?? null,
                'note'                 => $data['note'] ?? null,
                'kitchen_note'         => $data['kitchen_note'] ?? null,
                'subtotal'             => $subtotal,
                'discount_total'       => $discountTotal,
                'tax_total'            => $taxTotal,
                'service_charge_total' => $serviceTotal,
                'grand_total'          => $grandTotal,
                'paid_amount'          => $paidAmount,
                'change_amount'        => $changeAmount,
                'payment_status'       => $paymentStatus,
                'order_status'         => 'completed',
                'sync_status'          => 'synced',
                'cashier_name'         => $user->name,
                'cashier_role'         => $role,
                'ordered_at'           => $data['ordered_at'] ?? now(),
            ]);

            foreach ($items as $it) {
                OrderItem::create(['order_id' => $order->id] + $it);
            }

            foreach ($payments as $p) {
                Payment::create([
                    'order_id' => $order->id,
                    'method'   => $p['method'],
                    'amount'   => $p['amount'],
                    'status'   => 'paid',
                    'paid_at'  => now(),
                ]);
            }

            // ── Stock deduction (StockService expects product_id/qty/name) ──
            $stockItems = array_map(fn ($it) => [
                'product_id'   => $it['product_id'],
                'product_name' => $it['product_name_snapshot'],
                'qty'          => $it['qty'],
            ], $items);
            $conflicts = StockService::deductForOrder($order->id, $stockItems, $user->id, $outletId);

            foreach ($conflicts as $conflict) {
                if (!empty($conflict['low_stock'])) {
                    NotificationService::lowStock(
                        $businessId,
                        $conflict['product_name'],
                        $conflict['remaining']
                    );
                }
            }

            AuditLog::create([
                'business_id' => $businessId,
                'user_id'     => $user->id,
                'role'        => $role,
                'device_id'   => $deviceId,
                'action'      => 'checkout',
                'table_name'  => 'orders',
                'record_id'   => $order->id,
                'new_data'    => ['order_number' => $orderNumber, 'grand_total' => $grandTotal],
                'ip_address'  => $ipAddress,
            ]);

            return [
                'order'     => $order->load('items', 'payments'),
                'duplicate' => false,
                'conflicts' => $conflicts,
            ];
        });
    }
}
