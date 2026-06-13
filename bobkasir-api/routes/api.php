<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ShiftController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\SyncController;
use App\Http\Controllers\Api\OutletController;
use App\Http\Controllers\Api\ReceiptSettingController;
use App\Http\Controllers\Api\ReservationController;
use App\Http\Controllers\Api\OpenBillController;
use App\Http\Controllers\Api\StockController;
use App\Http\Controllers\Api\DiscountTaxController;

/*
|--------------------------------------------------------------------------
| BobKasir API Routes — PRD §34
|--------------------------------------------------------------------------
*/

// ──────────────────────────────────────────
// PUBLIC — Auth (no auth required)
// ──────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('register',            [AuthController::class, 'register']);
    Route::post('login',               [AuthController::class, 'login']);
    Route::post('google',              [AuthController::class, 'googleLogin']);
    Route::post('forgot-password',     [AuthController::class, 'forgotPassword']);
    Route::post('reset-password',      [AuthController::class, 'resetPassword']);
    Route::get('verify-email/{id}/{hash}', [AuthController::class, 'verifyEmail'])
        ->name('verification.verify')
        ->middleware('signed');
    Route::post('resend-verification', [AuthController::class, 'resendVerification']);
});

// Midtrans webhook (no auth — called by Midtrans server)
Route::post('midtrans/webhook', [SubscriptionController::class, 'webhook']);

// ──────────────────────────────────────────
// PROTECTED — Sanctum auth required
// ──────────────────────────────────────────
Route::middleware(['auth:sanctum', 'business.scope'])->group(function () {

    // Auth
    Route::get('auth/me',      [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);

    // Subscription (owner only)
    Route::prefix('subscription')->middleware('role:owner')->group(function () {
        Route::get('status',   [SubscriptionController::class, 'status']);
        Route::get('plans',    [SubscriptionController::class, 'plans']);
        Route::post('checkout',[SubscriptionController::class, 'checkout']);
        Route::get('history',  [SubscriptionController::class, 'history']);
    });

    // Also allow manager/karyawan to read subscription status (for UI)
    Route::get('subscription/status', [SubscriptionController::class, 'status']);

    // Users / Role management (owner only) — premium (locked when expired)
    Route::prefix('users')->middleware(['role:owner', 'subscription'])->group(function () {
        Route::get('/',              [UserController::class, 'index']);
        Route::post('manager',       [UserController::class, 'createManager']);
        Route::post('employee',      [UserController::class, 'createEmployee']);
        Route::put('{id}',           [UserController::class, 'update']);
        Route::patch('{id}/activate',[UserController::class, 'activate']);
        Route::patch('{id}/deactivate',[UserController::class, 'deactivate']);
        Route::delete('{id}/access', [UserController::class, 'removeAccess']);
    });

    // Catalog reads — all roles (cashier needs the product list, incl. karyawan)
    Route::get('categories',    [ProductController::class, 'indexCategories']);
    Route::get('products',      [ProductController::class, 'index']);
    Route::get('products/{id}', [ProductController::class, 'show']);

    // Categories (owner + manager) — premium features (locked when subscription expired, PRD §10.6)
    Route::middleware(['role:owner,manager', 'subscription'])->group(function () {
        Route::post('categories',        [ProductController::class, 'storeCategory']);
        Route::put('categories/{id}',    [ProductController::class, 'updateCategory']);
        Route::delete('categories/{id}', [ProductController::class, 'destroyCategory']);

        // Products
        Route::post('products',             [ProductController::class, 'store']);
        Route::put('products/{id}',         [ProductController::class, 'update']);
        Route::patch('products/{id}/status',[ProductController::class, 'updateStatus']);
        Route::delete('products/{id}',      [ProductController::class, 'destroy']);

        // Dashboard & Reports (owner + manager only)
        Route::get('dashboard/summary', [DashboardController::class, 'summary']);
        Route::get('reports/daily',     [DashboardController::class, 'daily']);
        Route::get('reports/weekly',    [DashboardController::class, 'weekly']);
        Route::get('reports/monthly',   [DashboardController::class, 'monthly']);
        Route::get('reports/yearly',    [DashboardController::class, 'yearly']);
        Route::get('reports/custom',    [DashboardController::class, 'custom']);
        Route::get('reports/export/pdf',   [DashboardController::class, 'exportPdf']);
        Route::get('reports/export/excel', [DashboardController::class, 'exportExcel']);
        Route::get('reports/export/image', [DashboardController::class, 'exportImage']);

        // Outlets (owner only for write, manager can read)
        Route::get('outlets',        [OutletController::class, 'index']);

        // Receipt settings (owner + manager)
        Route::get('receipt-settings',  [ReceiptSettingController::class, 'show']);
        Route::put('receipt-settings',  [ReceiptSettingController::class, 'update']);

        // Audit log (owner + manager)
        Route::get('audit-logs', function (\Illuminate\Http\Request $request) {
            $logs = \App\Models\AuditLog::where('business_id', $request->get('_business_id'))
                ->orderByDesc('created_at')
                ->paginate(50);
            return response()->json(['success' => true, 'data' => $logs]);
        });

        // Discounts (owner + manager)
        Route::get('discounts',         [DiscountTaxController::class, 'indexDiscounts']);
        Route::post('discounts',        [DiscountTaxController::class, 'storeDiscount']);
        Route::put('discounts/{id}',    [DiscountTaxController::class, 'updateDiscount']);
        Route::delete('discounts/{id}', [DiscountTaxController::class, 'destroyDiscount']);

        // Taxes (owner + manager)
        Route::get('taxes',             [DiscountTaxController::class, 'indexTaxes']);
        Route::post('taxes',            [DiscountTaxController::class, 'storeTax']);
        Route::put('taxes/{id}',        [DiscountTaxController::class, 'updateTax']);
        Route::delete('taxes/{id}',     [DiscountTaxController::class, 'destroyTax']);

        // Service Charges (owner + manager)
        Route::get('service-charges',           [DiscountTaxController::class, 'indexServiceCharges']);
        Route::post('service-charges',          [DiscountTaxController::class, 'storeServiceCharge']);
        Route::put('service-charges/{id}',      [DiscountTaxController::class, 'updateServiceCharge']);
        Route::delete('service-charges/{id}',   [DiscountTaxController::class, 'destroyServiceCharge']);

        // Stock management (owner + manager)
        Route::get('stocks',                          [StockController::class, 'index']);
        Route::post('stocks',                         [StockController::class, 'store']);
        Route::get('stocks/{productId}',              [StockController::class, 'show']);
        Route::patch('stocks/{productId}/adjust',     [StockController::class, 'adjust']);
        Route::get('stocks/{productId}/movements',    [StockController::class, 'movements']);
    });

    // Outlet write (owner only) — premium
    Route::middleware(['role:owner', 'subscription'])->group(function () {
        Route::post('outlets',       [OutletController::class, 'store']);
        Route::put('outlets/{id}',   [OutletController::class, 'update']);
    });

    // Orders (all roles)
    Route::prefix('orders')->group(function () {
        Route::get('/',                          [OrderController::class, 'index']);
        Route::post('/',                         [OrderController::class, 'store']);
        Route::get('{id}',                       [OrderController::class, 'show']);
        Route::post('{id}/print-log',            [OrderController::class, 'printLog']);
        Route::post('{id}/cancel-request',       [OrderController::class, 'cancelRequest']);
        Route::post('{id}/cancel-approve',       [OrderController::class, 'cancelApprove'])
             ->middleware('role:owner,manager');
        Route::post('{id}/cancel-reject',        [OrderController::class, 'cancelReject'])
             ->middleware('role:owner,manager');
        Route::post('{id}/refund-request',       [OrderController::class, 'refundRequest']);
        Route::post('{id}/refund-approve',       [OrderController::class, 'refundApprove'])
             ->middleware('role:owner,manager');
        Route::post('{id}/refund-reject',        [OrderController::class, 'refundReject'])
             ->middleware('role:owner,manager');
    });

    // Shifts (all roles)
    Route::prefix('shifts')->group(function () {
        Route::post('open',    [ShiftController::class, 'open']);
        Route::post('close',   [ShiftController::class, 'close']);
        Route::get('current',  [ShiftController::class, 'current']);
        Route::get('history',  [ShiftController::class, 'history']);
        Route::get('{id}',     [ShiftController::class, 'show']);
    });

    // Open Bills (all roles)
    Route::prefix('open-bills')->group(function () {
        Route::get('/',                      [OpenBillController::class, 'index']);
        Route::post('/',                     [OpenBillController::class, 'store']);
        Route::get('{id}',                   [OpenBillController::class, 'show']);
        Route::post('{id}/items',            [OpenBillController::class, 'addItem']);
        Route::delete('{id}/items/{itemId}', [OpenBillController::class, 'removeItem']);
        Route::post('{id}/cancel',           [OpenBillController::class, 'cancel']);
    });

    // Reservations (all roles, karyawan limited)
    Route::prefix('reservations')->group(function () {
        Route::get('/',      [ReservationController::class, 'index']);
        Route::post('/',     [ReservationController::class, 'store']);
        Route::put('{id}',   [ReservationController::class, 'update'])
             ->middleware('role:owner,manager');
    });

    // Sync (all roles, device-scoped)
    Route::prefix('sync')->group(function () {
        Route::post('push',  [SyncController::class, 'push']);
        Route::get('pull',   [SyncController::class, 'pull']);
        Route::post('retry', [SyncController::class, 'push']); // retry = same as push (idempotent)
        Route::get('status', [SyncController::class, 'status']);
    });

    // Active config for cashier (all roles — discounts/taxes/charges usable in kasir)
    Route::get('config/active', [DiscountTaxController::class, 'activeConfig']);

    // Notifications
    Route::get('notifications', function (\Illuminate\Http\Request $request) {
        $notifications = \App\Models\Notification::where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();
        return response()->json(['success' => true, 'data' => $notifications]);
    });

    Route::patch('notifications/{id}/read', function (string $id, \Illuminate\Http\Request $request) {
        \App\Models\Notification::where('user_id', $request->user()->id)->find($id)?->update(['is_read' => true, 'read_at' => now()]);
        return response()->json(['success' => true]);
    });
});
