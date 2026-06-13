<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Usage: middleware('role:owner') or middleware('role:owner,manager')
 */
class RequireRole
{
    public function handle(Request $request, Closure $next, string ...$roles): mixed
    {
        $userRole = $request->get('_user_role');
        if (!$userRole || !in_array($userRole, $roles)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses untuk fitur ini',
            ], 403);
        }
        return $next($request);
    }
}
