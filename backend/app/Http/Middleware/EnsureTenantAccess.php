<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureTenantAccess
{
    // Confirms the authenticated user belongs to a tenant.
    // Tenant isolation is enforced per-query in each controller (tenant_id scoping).
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user || !$user->tenant_id) {
            return response()->json(['message' => 'Tenant not found.'], 403);
        }
        return $next($request);
    }
}
