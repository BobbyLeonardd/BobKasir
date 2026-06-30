<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OpenbillController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ReceiptSettingController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\ReservationController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

// ── Public routes (no auth) ───────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('google', [AuthController::class, 'googleAuth']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);
    Route::post('verify-email', [AuthController::class, 'verifyEmail']);
    Route::post('resend-verification', [AuthController::class, 'sendVerification']);
});

// Midtrans webhook is public (signature verified inside controller)
Route::post('subscriptions/webhook/midtrans', [SubscriptionController::class, 'webhook']);

// ── Authenticated routes ──────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::post('auth/refresh', [AuthController::class, 'refresh']);

    // Users — profile (all roles)
    Route::get('users/profile', [UserController::class, 'profile']);
    Route::put('users/profile', [UserController::class, 'updateProfile']);
    Route::put('users/profile/email', [UserController::class, 'requestEmailChange']);
    Route::post('users/profile/email/confirm', [UserController::class, 'confirmEmailChange']);
    Route::post('users/profile/password', [UserController::class, 'changePassword']);
    Route::delete('users/profile', [UserController::class, 'deleteProfile']);

    // Users — manage subordinates (owner only)
    Route::middleware('role:owner')->group(function () {
        Route::get('users', [UserController::class, 'index']);
        Route::post('users', [UserController::class, 'store']);
        Route::get('users/{id}', [UserController::class, 'show']);
        Route::put('users/{id}', [UserController::class, 'update']);
        Route::delete('users/{id}', [UserController::class, 'destroy']);
    });

    // Categories & Products (owner & admin only)
    Route::middleware(['subscription', 'role:owner,admin'])->group(function () {
        Route::apiResource('categories', CategoryController::class)->except(['show']);
        Route::apiResource('products', ProductController::class);
    });

    // Orders (all roles, with subscription check)
    Route::middleware('subscription')->group(function () {
        Route::get('orders', [OrderController::class, 'index']);
        Route::post('orders', [OrderController::class, 'store']);
        Route::get('orders/{id}', [OrderController::class, 'show']);
        Route::post('sync/orders', [OrderController::class, 'sync']);

        // Cancel — owner/admin only
        Route::middleware('role:owner,admin')->group(function () {
            Route::post('orders/{id}/cancel', [OrderController::class, 'cancel']);
            Route::post('orders/{id}/approve-cancel', [OrderController::class, 'approveCancel']);
            Route::post('orders/{id}/reject-cancel', [OrderController::class, 'rejectCancel']);
        });

        // Request cancel — cashier only
        Route::middleware('role:cashier')->group(function () {
            Route::post('orders/{id}/request-cancel', [OrderController::class, 'requestCancel']);
        });
    });

    // Openbills (all roles, with subscription)
    Route::middleware('subscription')->group(function () {
        Route::get('openbills', [OpenbillController::class, 'index']);
        Route::post('openbills', [OpenbillController::class, 'store']);
        Route::put('openbills/{id}', [OpenbillController::class, 'update']);
        Route::delete('openbills/{id}', [OpenbillController::class, 'destroy']);
        Route::post('openbills/{id}/checkout', [OpenbillController::class, 'checkout']);
    });

    // Reservations (all roles, with subscription)
    Route::middleware('subscription')->group(function () {
        Route::get('reservations', [ReservationController::class, 'index']);
        Route::post('reservations', [ReservationController::class, 'store']);
        Route::put('reservations/{id}', [ReservationController::class, 'update']);
        Route::post('reservations/{id}/arrive', [ReservationController::class, 'arrive']);
        Route::post('reservations/{id}/cancel', [ReservationController::class, 'cancel']);
    });

    // Reports (owner & admin only)
    Route::middleware(['subscription', 'role:owner,admin'])->prefix('reports')->group(function () {
        Route::get('daily', [ReportController::class, 'daily']);
        Route::get('weekly', [ReportController::class, 'weekly']);
        Route::get('monthly', [ReportController::class, 'monthly']);
        Route::get('yearly', [ReportController::class, 'yearly']);
        Route::get('compare', [ReportController::class, 'compare']);
        Route::get('chart', [ReportController::class, 'chartData']);
        Route::get('export/{type}', [ReportController::class, 'export']);
        Route::get('cashier-activity', [ReportController::class, 'cashierActivity']);
    });

    // Subscriptions (owner only)
    Route::middleware('role:owner')->group(function () {
        Route::get('subscriptions/current', [SubscriptionController::class, 'current']);
        Route::post('subscriptions/checkout', [SubscriptionController::class, 'checkout']);
        Route::post('subscriptions/manual', [SubscriptionController::class, 'manualPayment']);
        Route::post('subscriptions/cancel', [SubscriptionController::class, 'cancel']);
    });

    // Receipt settings (owner & admin for update, all for read)
    Route::get('receipt-settings', [ReceiptSettingController::class, 'show']);
    Route::middleware('role:owner,admin')->put('receipt-settings', [ReceiptSettingController::class, 'update']);

    // Notifications (all roles)
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::post('notifications/read/{id}', [NotificationController::class, 'markRead']);
    Route::post('notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::post('device-tokens', [NotificationController::class, 'registerDeviceToken']);
});
