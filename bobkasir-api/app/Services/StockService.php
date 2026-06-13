<?php

namespace App\Services;

use App\Models\Stock;
use App\Models\StockMovement;

class StockService
{
    /**
     * Deduct stock for all items in an order.
     * Skips products that don't track stock (track_stock = false).
     */
    public static function deductForOrder(
        string $orderId,
        array $items,
        string $userId,
        ?string $outletId = null
    ): array {
        $conflicts = [];

        foreach ($items as $item) {
            if (empty($item['product_id'])) continue;

            $stock = Stock::where('product_id', $item['product_id'])
                ->where(function ($q) use ($outletId) {
                    if ($outletId) {
                        $q->where('outlet_id', $outletId)->orWhereNull('outlet_id');
                    } else {
                        $q->whereNull('outlet_id');
                    }
                })
                ->orderByRaw('outlet_id IS NULL ASC')
                ->first();

            if (!$stock) continue; // product doesn't track stock

            $qty        = $item['qty'] ?? 1;
            $before     = $stock->quantity;
            $after      = $before - $qty;

            if ($after < 0) {
                // Allow negative stock but flag as conflict
                $conflicts[] = [
                    'product_id'   => $item['product_id'],
                    'product_name' => $item['product_name'] ?? 'Unknown',
                    'requested'    => $qty,
                    'available'    => $before,
                ];
            }

            $stock->decrement('quantity', $qty);

            StockMovement::create([
                'stock_id'       => $stock->id,
                'user_id'        => $userId,
                'type'           => 'sale',
                'quantity'       => -$qty,
                'quantity_before'=> $before,
                'quantity_after' => max(0, $after),
                'reference_id'   => $orderId,
                'reference_type' => 'order',
            ]);

            // Check if stock is now below minimum — notify
            if ($stock->fresh()->quantity <= $stock->minimum_stock && $stock->minimum_stock > 0) {
                // Notification will be triggered by caller with business context
                $conflicts[] = [
                    'product_id'   => $item['product_id'],
                    'product_name' => $item['product_name'] ?? 'Unknown',
                    'low_stock'    => true,
                    'remaining'    => $stock->fresh()->quantity,
                ];
            }
        }

        return $conflicts;
    }

    /**
     * Restore stock when order is cancelled.
     */
    public static function restoreForCancel(
        string $orderId,
        array $items,
        string $userId,
        ?string $outletId = null
    ): void {
        foreach ($items as $item) {
            if (empty($item['product_id'])) continue;

            $stock = Stock::where('product_id', $item['product_id'])
                ->where(function ($q) use ($outletId) {
                    if ($outletId) {
                        $q->where('outlet_id', $outletId)->orWhereNull('outlet_id');
                    } else {
                        $q->whereNull('outlet_id');
                    }
                })
                ->orderByRaw('outlet_id IS NULL ASC')
                ->first();
            if (!$stock) continue;

            $qty    = $item['qty'] ?? 1;
            $before = $stock->quantity;

            $stock->increment('quantity', $qty);

            StockMovement::create([
                'stock_id'       => $stock->id,
                'user_id'        => $userId,
                'type'           => 'cancel_return',
                'quantity'       => $qty,
                'quantity_before'=> $before,
                'quantity_after' => $before + $qty,
                'reference_id'   => $orderId,
                'reference_type' => 'cancel',
            ]);
        }
    }

    /**
     * Adjust stock manually (add/subtract/set).
     */
    public static function adjust(
        string $productId,
        string $type,    // 'in' | 'out' | 'adjustment'
        int $quantity,
        string $userId,
        ?string $note = null,
        ?string $outletId = null
    ): array {
        $stock = Stock::firstOrCreate(
            ['product_id' => $productId, 'outlet_id' => $outletId],
            ['quantity' => 0, 'minimum_stock' => 0]
        );

        $before = $stock->quantity;

        $after = match ($type) {
            'in'         => $before + $quantity,
            'out'        => max(0, $before - $quantity),
            'adjustment' => $quantity, // set directly
            default      => $before,
        };

        $stock->update(['quantity' => $after]);

        StockMovement::create([
            'stock_id'       => $stock->id,
            'user_id'        => $userId,
            'type'           => 'adjustment',
            'quantity'       => $after - $before,
            'quantity_before'=> $before,
            'quantity_after' => $after,
            'note'           => $note,
        ]);

        return ['stock_id' => $stock->id, 'before' => $before, 'after' => $after];
    }
}
