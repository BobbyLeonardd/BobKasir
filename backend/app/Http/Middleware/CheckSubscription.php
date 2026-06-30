<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckSubscription
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user || !$user->tenant) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if (!$user->tenant->hasFullAccess()) {
            return response()->json([
                'message' => 'Langganan tidak aktif. Silakan berlangganan untuk mengakses fitur ini.',
                'subscription_required' => true,
            ], 403);
        }

        return $next($request);
    }
}
