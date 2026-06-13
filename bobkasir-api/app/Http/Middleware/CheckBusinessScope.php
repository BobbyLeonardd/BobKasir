<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Ensures authenticated user belongs to the current business context.
 * Prevents data leakage between businesses.
 */
class CheckBusinessScope
{
    public function handle(Request $request, Closure $next): mixed
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
        }

        $role = $user->businessRole;
        if (!$role || $role->status !== 'active') {
            return response()->json(['success' => false, 'message' => 'Akun tidak aktif atau tidak terhubung ke bisnis'], 403);
        }

        // Attach business_id to request for controllers
        $request->merge([
            '_business_id' => $role->business_id,
            '_user_role'   => $role->role,
            '_outlet_id'   => $role->outlet_id,
        ]);

        return $next($request);
    }
}
