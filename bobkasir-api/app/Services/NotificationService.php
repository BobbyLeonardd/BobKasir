<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\UserBusinessRole;

/**
 * Creates in-app notifications for the right recipients based on role
 * and PRD §32 notification rules.
 */
class NotificationService
{
    /**
     * Notify owner and all managers of a business.
     */
    public static function notifyOwnerAndManagers(
        string $businessId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ): void {
        $recipients = UserBusinessRole::where('business_id', $businessId)
            ->whereIn('role', ['owner', 'manager'])
            ->where('status', 'active')
            ->pluck('user_id');

        foreach ($recipients as $userId) {
            Notification::create([
                'user_id'     => $userId,
                'business_id' => $businessId,
                'type'        => $type,
                'title'       => $title,
                'body'        => $body,
                'data'        => $data,
            ]);
        }
    }

    /**
     * Notify only owners of a business.
     */
    public static function notifyOwners(
        string $businessId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ): void {
        $owners = UserBusinessRole::where('business_id', $businessId)
            ->where('role', 'owner')
            ->where('status', 'active')
            ->pluck('user_id');

        foreach ($owners as $userId) {
            Notification::create([
                'user_id'     => $userId,
                'business_id' => $businessId,
                'type'        => $type,
                'title'       => $title,
                'body'        => $body,
                'data'        => $data,
            ]);
        }
    }

    /**
     * Notify a specific user.
     */
    public static function notifyUser(
        string $userId,
        string $businessId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ): void {
        Notification::create([
            'user_id'     => $userId,
            'business_id' => $businessId,
            'type'        => $type,
            'title'       => $title,
            'body'        => $body,
            'data'        => $data,
        ]);
    }

    // ──────────────────────────────────────────
    // Convenience methods for common notification types (PRD §32)
    // ──────────────────────────────────────────

    public static function cancelRequested(string $businessId, string $orderNumber, string $requestedByName, string $orderId): void
    {
        self::notifyOwnerAndManagers(
            $businessId,
            'cancel_request',
            'Request Cancel Order',
            "$requestedByName mengajukan pembatalan order #$orderNumber",
            ['order_id' => $orderId, 'order_number' => $orderNumber]
        );
    }

    public static function refundRequested(string $businessId, string $orderNumber, string $requestedByName, string $orderId): void
    {
        self::notifyOwnerAndManagers(
            $businessId,
            'refund_request',
            'Request Refund',
            "$requestedByName mengajukan refund untuk order #$orderNumber",
            ['order_id' => $orderId, 'order_number' => $orderNumber]
        );
    }

    public static function subscriptionExpiringSoon(string $businessId, int $daysLeft): void
    {
        self::notifyOwners(
            $businessId,
            'subscription_expiring',
            'Langganan Hampir Habis',
            "Langganan Anda akan berakhir dalam $daysLeft hari. Perpanjang sekarang.",
            ['days_left' => $daysLeft]
        );
    }

    public static function subscriptionExpired(string $businessId): void
    {
        self::notifyOwners(
            $businessId,
            'subscription_expired',
            'Langganan Habis',
            'Langganan Anda telah berakhir. Fitur premium dikunci.',
            []
        );
    }

    public static function paymentSuccess(string $businessId, string $plan, int $amount): void
    {
        self::notifyOwners(
            $businessId,
            'payment_success',
            'Pembayaran Berhasil',
            "Pembayaran paket $plan berhasil. Terima kasih!",
            ['plan' => $plan, 'amount' => $amount]
        );
    }

    public static function paymentFailed(string $businessId, string $plan, int $amount): void
    {
        self::notifyOwners(
            $businessId,
            'payment_failed',
            'Pembayaran Gagal',
            "Pembayaran paket $plan gagal. Coba lagi.",
            ['plan' => $plan, 'amount' => $amount]
        );
    }

    public static function lowStock(string $businessId, string $productName, int $remaining): void
    {
        self::notifyOwnerAndManagers(
            $businessId,
            'low_stock',
            'Stok Menipis',
            "Stok $productName tinggal $remaining. Segera restok.",
            ['product_name' => $productName, 'remaining' => $remaining]
        );
    }

    public static function syncFailed(string $businessId, string $userId, string $deviceId, string $message): void
    {
        // Notify owner + manager + the device's user (PRD §32.2)
        self::notifyOwnerAndManagers(
            $businessId,
            'sync_failed',
            'Sinkronisasi Gagal',
            "Sinkronisasi dari device $deviceId gagal: $message",
            ['device_id' => $deviceId, 'error' => $message]
        );
        // Also notify the device user directly
        self::notifyUser($userId, $businessId, 'sync_failed', 'Sinkronisasi Gagal', $message, ['device_id' => $deviceId]);
    }
}
