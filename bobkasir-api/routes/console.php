<?php

use App\Models\Subscription;
use App\Services\NotificationService;
use Illuminate\Support\Facades\Schedule;

/**
 * BobKasir scheduled commands — run via:
 * php artisan schedule:run   (every minute, called from OS cron/scheduler)
 *
 * Cron entry: * * * * * php /path/to/bobkasir-api/artisan schedule:run >> /dev/null 2>&1
 */

// ── Daily: Check subscription expiry & send notifications ──
Schedule::call(function () {
    $subscriptions = Subscription::whereIn('status', ['trial', 'active'])->get();

    foreach ($subscriptions as $sub) {
        $expiryDate = $sub->status === 'trial' ? $sub->trial_expired_at : $sub->expired_at;

        if (!$expiryDate) continue;

        $daysLeft = now()->diffInDays($expiryDate, false);

        if ($daysLeft <= 0) {
            // Already expired — update status
            $sub->update(['status' => 'expired']);
            NotificationService::subscriptionExpired($sub->business_id);
        } elseif ($daysLeft <= 3) {
            // Expiring soon — notify
            NotificationService::subscriptionExpiringSoon($sub->business_id, (int) $daysLeft);
        }
    }
})->dailyAt('08:00')->name('check-subscription-expiry')->withoutOverlapping();
