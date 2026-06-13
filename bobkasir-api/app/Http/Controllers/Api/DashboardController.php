<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class DashboardController extends Controller
{
    use ApiResponse;

    // GET /api/dashboard/summary
    public function summary(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $today = today();

        $todaySales = Order::where('business_id', $biz)
            ->whereDate('ordered_at', $today)
            ->where('order_status', 'completed')
            ->selectRaw('SUM(grand_total) as total_sales, COUNT(*) as total_transactions, AVG(grand_total) as avg_transaction')
            ->first();

        $refunds = Order::where('business_id', $biz)->whereDate('ordered_at', $today)->where('order_status','refunded')->count();
        $cancels = Order::where('business_id', $biz)->whereDate('ordered_at', $today)->where('order_status','cancelled')->count();

        // Top products
        $topProducts = DB::table('order_items')
            ->join('orders','orders.id','=','order_items.order_id')
            ->where('orders.business_id', $biz)
            ->whereDate('orders.ordered_at', $today)
            ->selectRaw('order_items.product_name_snapshot as name, SUM(order_items.qty) as qty, SUM(order_items.subtotal) as revenue')
            ->groupBy('order_items.product_name_snapshot')
            ->orderByDesc('qty')
            ->limit(5)
            ->get();

        // Payment breakdown
        $paymentBreakdown = DB::table('payments')
            ->join('orders','orders.id','=','payments.order_id')
            ->where('orders.business_id', $biz)
            ->whereDate('orders.ordered_at', $today)
            ->selectRaw('payments.method, SUM(payments.amount) as total, COUNT(*) as count')
            ->groupBy('payments.method')
            ->get();

        return $this->success([
            'total_sales' => (int) ($todaySales->total_sales ?? 0),
            'total_transactions' => (int) ($todaySales->total_transactions ?? 0),
            'avg_transaction' => (int) ($todaySales->avg_transaction ?? 0),
            'total_refunds' => $refunds,
            'total_cancels' => $cancels,
            'top_products' => $topProducts,
            'payment_breakdown' => $paymentBreakdown,
        ]);
    }

    // GET /api/reports/daily
    public function daily(Request $request): JsonResponse { return $this->report($request, 'daily'); }
    public function weekly(Request $request): JsonResponse { return $this->report($request, 'weekly'); }
    public function monthly(Request $request): JsonResponse { return $this->report($request, 'monthly'); }
    public function yearly(Request $request): JsonResponse { return $this->report($request, 'yearly'); }

    // GET /api/reports/custom?date_from=2026-01-01&date_to=2026-01-31
    public function custom(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'date_from' => 'required|date',
            'date_to'   => 'required|date|after_or_equal:date_from',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz  = $request->get('_business_id');
        $from = $request->date_from;
        $to   = $request->date_to;

        $query = Order::where('business_id', $biz)
            ->where('order_status', 'completed')
            ->whereDate('ordered_at', '>=', $from)
            ->whereDate('ordered_at', '<=', $to);

        $summary = $query->selectRaw('
            SUM(grand_total) as total_sales,
            COUNT(*) as total_transactions,
            AVG(grand_total) as avg_transaction,
            SUM(discount_total) as total_discounts
        ')->first();

        $dailyBreakdown = DB::table('orders')
            ->where('business_id', $biz)
            ->where('order_status', 'completed')
            ->whereDate('ordered_at', '>=', $from)
            ->whereDate('ordered_at', '<=', $to)
            ->selectRaw('DATE(ordered_at) as date, SUM(grand_total) as sales, COUNT(*) as transactions')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $topProducts = DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->where('orders.business_id', $biz)
            ->where('orders.order_status', 'completed')
            ->whereDate('orders.ordered_at', '>=', $from)
            ->whereDate('orders.ordered_at', '<=', $to)
            ->selectRaw('order_items.product_name_snapshot as name, SUM(order_items.qty) as qty, SUM(order_items.subtotal) as revenue')
            ->groupBy('order_items.product_name_snapshot')
            ->orderByDesc('revenue')
            ->limit(10)
            ->get();

        $byCashier = DB::table('orders')
            ->where('business_id', $biz)
            ->where('order_status', 'completed')
            ->whereDate('ordered_at', '>=', $from)
            ->whereDate('ordered_at', '<=', $to)
            ->selectRaw('cashier_name, cashier_role, COUNT(*) as transactions, SUM(grand_total) as sales')
            ->groupBy('cashier_name', 'cashier_role')
            ->orderByDesc('sales')
            ->get();

        return $this->success([
            'period'          => compact('from', 'to'),
            'total_sales'     => (int)($summary->total_sales ?? 0),
            'total_transactions' => (int)($summary->total_transactions ?? 0),
            'avg_transaction' => (int)($summary->avg_transaction ?? 0),
            'total_discounts' => (int)($summary->total_discounts ?? 0),
            'daily_breakdown' => $dailyBreakdown,
            'top_products'    => $topProducts,
            'by_cashier'      => $byCashier,
        ]);
    }

    // GET /api/reports/export/pdf — returns download URL (actual PDF generated client-side or via job)
    public function exportPdf(Request $request): JsonResponse
    {
        // In production: dispatch a job to generate PDF and return a signed URL
        // For now: return the data for client-side generation
        return $this->success(['message' => 'PDF generation — use /reports/custom for data, generate PDF on client'], 'Export PDF');
    }

    // GET /api/reports/export/excel
    public function exportExcel(Request $request): JsonResponse
    {
        return $this->success(['message' => 'Excel generation — use /reports/custom for data'], 'Export Excel');
    }

    // GET /api/reports/export/image
    public function exportImage(Request $request): JsonResponse
    {
        return $this->success(['message' => 'Image generation — use /reports/custom for data'], 'Export Image');
    }

    private function report(Request $request, string $period): JsonResponse
    {
        $biz = $request->get('_business_id');
        $query = Order::where('business_id', $biz)->where('order_status', 'completed');

        switch ($period) {
            case 'daily': $query->whereDate('ordered_at', today()); break;
            case 'weekly': $query->whereBetween('ordered_at', [now()->startOfWeek(), now()->endOfWeek()]); break;
            case 'monthly': $query->whereMonth('ordered_at', now()->month)->whereYear('ordered_at', now()->year); break;
            case 'yearly': $query->whereYear('ordered_at', now()->year); break;
        }

        $data = $query->selectRaw('SUM(grand_total) as total_sales, COUNT(*) as total_transactions')->first();
        return $this->success(['period' => $period, 'total_sales' => (int)($data->total_sales ?? 0), 'total_transactions' => (int)($data->total_transactions ?? 0)]);
    }
}
