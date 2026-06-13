<?php

namespace App\Http\Middleware;

use App\Models\Subscription;
use Closure;
use Illuminate\Http\Request;

/**
 * Blocks premium endpoints when the business has no active/trial subscription
 * (PRD §10.6). Basic cashier flows (orders, shifts, sync, catalog reads) are
 * intentionally NOT wrapped with this middleware so the kasir keeps working.
 *
 * Requires CheckBusinessScope to have run first (sets `_business_id`).
 */
class EnsureSubscriptionActive
{
    public function handle(Request $request, Closure $next): mixed
    {
        $businessId = $request->get('_business_id');
        $subscription = Subscription::where('business_id', $businessId)->first();

        if (!$subscription || !$subscription->isActive()) {
            return response()->json([
                'success' => false,
                'message' => 'Langganan tidak aktif. Perpanjang langganan untuk membuka fitur ini.',
                'errors'  => ['subscription_inactive' => true],
            ], 403);
        }

        return $next($request);
    }
}
