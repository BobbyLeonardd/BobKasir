<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SyncLog;
use App\Services\OrderCreationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SyncController extends Controller
{
    use ApiResponse;

    // POST /api/sync/push — receive offline orders from device
    public function push(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'items' => 'required|array',
            'items.*.sync_id' => 'required|string',
            'items.*.local_id' => 'required|string',
            'items.*.type' => 'required|string',
            'items.*.payload' => 'required|array',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz = $request->get('_business_id');
        $results = [];

        foreach ($request->items as $item) {
            // Idempotency check (PRD §26.5) — already-synced items are skipped.
            $existing = SyncLog::where('sync_id', $item['sync_id'])->first();
            if ($existing && $existing->status === 'synced') {
                $results[] = ['sync_id' => $item['sync_id'], 'status' => 'already_synced'];
                continue;
            }

            $log = SyncLog::updateOrCreate(
                ['sync_id' => $item['sync_id']],
                [
                    'business_id' => $biz,
                    'device_id' => $request->device_id ?? 'unknown',
                    'local_id' => $item['local_id'],
                    'type' => $item['type'],
                    'payload' => $item['payload'],
                    'status' => 'pending',
                ]
            );

            // Process based on type
            try {
                if ($item['type'] === 'order') {
                    $result = OrderCreationService::create(
                        $item['payload'],
                        $request->user(),
                        $biz,
                        $request->get('_user_role'),
                        $request->get('_outlet_id'),
                        $request->device_id ?? ($item['payload']['device_id'] ?? null),
                        $request->ip(),
                    );
                    $order = $result['order'];

                    $log->update(['status' => 'synced']);
                    $results[] = [
                        'sync_id'      => $item['sync_id'],
                        'status'       => $result['duplicate'] ? 'already_synced' : 'synced',
                        'order_id'     => $order->id,
                        'order_number' => $order->order_number,
                    ];
                } else {
                    // Other queue types (open bill, shift, etc.) are not replayed yet —
                    // mark synced so they don't block the device queue.
                    $log->update(['status' => 'synced']);
                    $results[] = ['sync_id' => $item['sync_id'], 'status' => 'synced'];
                }
            } catch (\Exception $e) {
                $log->update(['status' => 'failed', 'error_message' => $e->getMessage()]);
                $results[] = ['sync_id' => $item['sync_id'], 'status' => 'failed', 'error' => $e->getMessage()];
            }
        }

        return $this->success(['results' => $results]);
    }

    // GET /api/sync/pull — get latest data for device
    public function pull(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $since = $request->input('since', now()->subDay()->toISOString());

        return $this->success([
            'orders' => Order::where('business_id', $biz)->where('updated_at', '>=', $since)->get(['id','order_number','order_status','sync_status','updated_at']),
        ]);
    }

    // GET /api/sync/status
    public function status(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $logs = SyncLog::where('business_id', $biz)->orderByDesc('created_at')->limit(20)->get();
        return $this->success($logs);
    }
}
