<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    private function tenantId(Request $request): int
    {
        return $request->user()->tenant_id;
    }

    public function daily(Request $request)
    {
        $date = $request->get('date', now()->toDateString());
        return response()->json(['data' => $this->summary($this->tenantId($request), $date, $date)]);
    }

    public function weekly(Request $request)
    {
        $from = now()->startOfWeek()->toDateString();
        $to = now()->endOfWeek()->toDateString();
        return response()->json(['data' => $this->summary($this->tenantId($request), $from, $to)]);
    }

    public function monthly(Request $request)
    {
        $from = now()->startOfMonth()->toDateString();
        $to = now()->endOfMonth()->toDateString();
        return response()->json(['data' => $this->summary($this->tenantId($request), $from, $to)]);
    }

    public function yearly(Request $request)
    {
        $from = now()->startOfYear()->toDateString();
        $to = now()->endOfYear()->toDateString();
        return response()->json(['data' => $this->summary($this->tenantId($request), $from, $to)]);
    }

    public function compare(Request $request)
    {
        $tenantId = $this->tenantId($request);
        $now = now();

        $today = $this->summary($tenantId, $now->toDateString(), $now->toDateString());
        $yesterday = $this->summary($tenantId, $now->copy()->subDay()->toDateString(), $now->copy()->subDay()->toDateString());

        $thisWeekFrom = $now->copy()->startOfWeek()->toDateString();
        $thisWeekTo = $now->copy()->endOfWeek()->toDateString();
        $lastWeekFrom = $now->copy()->subWeek()->startOfWeek()->toDateString();
        $lastWeekTo = $now->copy()->subWeek()->endOfWeek()->toDateString();

        $thisMonthFrom = $now->copy()->startOfMonth()->toDateString();
        $thisMonthTo = $now->copy()->endOfMonth()->toDateString();
        $lastMonthFrom = $now->copy()->subMonth()->startOfMonth()->toDateString();
        $lastMonthTo = $now->copy()->subMonth()->endOfMonth()->toDateString();

        $thisYearFrom = $now->copy()->startOfYear()->toDateString();
        $thisYearTo = $now->copy()->endOfYear()->toDateString();
        $lastYearFrom = $now->copy()->subYear()->startOfYear()->toDateString();
        $lastYearTo = $now->copy()->subYear()->endOfYear()->toDateString();

        return response()->json([
            'data' => [
                'today_vs_yesterday' => $this->compareTwo($today, $yesterday),
                'this_week_vs_last' => $this->compareTwo(
                    $this->summary($tenantId, $thisWeekFrom, $thisWeekTo),
                    $this->summary($tenantId, $lastWeekFrom, $lastWeekTo)
                ),
                'this_month_vs_last' => $this->compareTwo(
                    $this->summary($tenantId, $thisMonthFrom, $thisMonthTo),
                    $this->summary($tenantId, $lastMonthFrom, $lastMonthTo)
                ),
                'this_year_vs_last' => $this->compareTwo(
                    $this->summary($tenantId, $thisYearFrom, $thisYearTo),
                    $this->summary($tenantId, $lastYearFrom, $lastYearTo)
                ),
            ],
        ]);
    }

    public function cashierActivity(Request $request)
    {
        $date = $request->get('date', now()->toDateString());
        $tenantId = $this->tenantId($request);

        $activity = Order::where('tenant_id', $tenantId)
            ->whereDate('created_at', $date)
            ->where('status', 'completed')
            ->select('user_id', 'cashier_name', DB::raw('COUNT(*) as total_orders'), DB::raw('SUM(total) as total_revenue'))
            ->groupBy('user_id', 'cashier_name')
            ->get();

        return response()->json(['data' => $activity]);
    }

    public function chartData(Request $request)
    {
        $request->validate([
            'period' => 'required|in:daily,weekly,monthly,yearly',
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date',
        ]);

        $tenantId = $this->tenantId($request);
        $period = $request->period;
        $from = $request->get('date_from', now()->startOfMonth()->toDateString());
        $to = $request->get('date_to', now()->toDateString());

        $groupFormat = match ($period) {
            'daily' => '%Y-%m-%d',
            'weekly' => '%Y-%u',
            'monthly' => '%Y-%m',
            'yearly' => '%Y',
        };

        $data = Order::where('tenant_id', $tenantId)
            ->whereBetween(DB::raw('DATE(created_at)'), [$from, $to])
            ->where('status', 'completed')
            ->select(
                DB::raw("DATE_FORMAT(created_at, '{$groupFormat}') as period"),
                DB::raw('SUM(total) as revenue'),
                DB::raw('COUNT(*) as transactions')
            )
            ->groupBy('period')
            ->orderBy('period')
            ->get();

        return response()->json(['data' => $data]);
    }

    public function export(Request $request, string $type)
    {
        // Returns data for client-side export generation
        // Actual PDF/Excel generation can be done in the Flutter app or via dedicated export service
        $request->validate([
            'date_from' => 'required|date',
            'date_to' => 'required|date',
        ]);

        $tenantId = $this->tenantId($request);
        $from = $request->date_from;
        $to = $request->date_to;

        $orders = Order::where('tenant_id', $tenantId)
            ->whereBetween(DB::raw('DATE(created_at)'), [$from, $to])
            ->where('status', 'completed')
            ->with(['items', 'payments', 'user:id,name'])
            ->get();

        return response()->json([
            'type' => $type,
            'date_from' => $from,
            'date_to' => $to,
            'summary' => $this->summary($tenantId, $from, $to),
            'orders' => $orders,
        ]);
    }

    private function summary(int $tenantId, string $from, string $to): array
    {
        $result = Order::where('tenant_id', $tenantId)
            ->whereBetween(DB::raw('DATE(created_at)'), [$from, $to])
            ->where('status', 'completed')
            ->select(DB::raw('COUNT(*) as total_orders'), DB::raw('SUM(total) as total_revenue'))
            ->first();

        return [
            'from' => $from,
            'to' => $to,
            'total_orders' => (int) ($result->total_orders ?? 0),
            'total_revenue' => (int) ($result->total_revenue ?? 0),
        ];
    }

    private function compareTwo(array $current, array $previous): array
    {
        $prevRevenue = $previous['total_revenue'] ?: 0;
        $revenueChange = $prevRevenue > 0
            ? round((($current['total_revenue'] - $prevRevenue) / $prevRevenue) * 100, 1)
            : null;

        $prevOrders = $previous['total_orders'] ?: 0;
        $orderChange = $prevOrders > 0
            ? round((($current['total_orders'] - $prevOrders) / $prevOrders) * 100, 1)
            : null;

        return [
            'current' => $current,
            'previous' => $previous,
            'revenue_change_pct' => $revenueChange,
            'orders_change' => $current['total_orders'] - $prevOrders,
        ];
    }
}
