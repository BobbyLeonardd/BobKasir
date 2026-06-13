<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Shift;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ShiftController extends Controller
{
    use ApiResponse;

    // POST /api/shifts/open
    public function open(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['opening_cash' => 'required|integer|min:0']);
        if ($v->fails()) return $this->validationError($v->errors());
        $biz = $request->get('_business_id');
        $user = $request->user();
        // Check if there's already an open shift for this user
        $existing = Shift::where('business_id', $biz)->where('user_id', $user->id)->where('status','open')->first();
        if ($existing) return $this->error('Sudah ada shift aktif. Tutup shift sebelumnya terlebih dahulu.');
        $shift = Shift::create([
            'business_id' => $biz,
            'outlet_id' => $request->get('_outlet_id'),
            'user_id' => $user->id,
            'device_id' => $request->device_id,
            'user_name' => $user->name,
            'user_role' => $request->get('_user_role'),
            'opening_cash' => $request->opening_cash,
            'opening_note' => $request->note,
            'status' => 'open',
            'opened_at' => now(),
        ]);
        AuditLog::create([
            'business_id'=>$biz,'user_id'=>$user->id,'role'=>$request->get('_user_role'),
            'action'=>'buka_shift','table_name'=>'shifts','record_id'=>$shift->id,
            'new_data'=>['opening_cash'=>$request->opening_cash],'ip_address'=>$request->ip(),
        ]);
        return $this->success($shift, 'Shift dibuka', 201);
    }

    // POST /api/shifts/close
    public function close(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['closing_cash' => 'required|integer|min:0']);
        if ($v->fails()) return $this->validationError($v->errors());
        $biz = $request->get('_business_id');
        $user = $request->user();
        $shift = Shift::where('business_id', $biz)->where('user_id', $user->id)->where('status','open')->latest('opened_at')->first();
        if (!$shift) return $this->notFound('Tidak ada shift aktif');
        $shift->update([
            'closing_cash' => $request->closing_cash,
            'closing_note' => $request->note,
            'status' => 'closed',
            'closed_at' => now(),
        ]);
        AuditLog::create([
            'business_id'=>$biz,'user_id'=>$user->id,'role'=>$request->get('_user_role'),
            'action'=>'tutup_shift','table_name'=>'shifts','record_id'=>$shift->id,
            'new_data'=>['closing_cash'=>$request->closing_cash],'ip_address'=>$request->ip(),
        ]);
        return $this->success($shift, 'Shift ditutup');
    }

    // GET /api/shifts/current
    public function current(Request $request): JsonResponse
    {
        $shift = Shift::where('business_id', $request->get('_business_id'))
            ->where('user_id', $request->user()->id)
            ->where('status','open')
            ->latest('opened_at')->first();
        return $this->success($shift);
    }

    // GET /api/shifts/history
    public function history(Request $request): JsonResponse
    {
        $shifts = Shift::where('business_id', $request->get('_business_id'))
            ->orderByDesc('opened_at')
            ->paginate($request->get('per_page', 20));
        return $this->success($shifts);
    }

    // GET /api/shifts/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $shift = Shift::where('business_id', $request->get('_business_id'))->find($id);
        if (!$shift) return $this->notFound();
        return $this->success($shift);
    }
}
