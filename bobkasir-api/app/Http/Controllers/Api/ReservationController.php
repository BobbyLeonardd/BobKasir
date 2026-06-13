<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Reservation;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ReservationController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $q = Reservation::where('business_id', $request->get('_business_id'))->orderByDesc('reservation_date');
        if ($request->filled('date')) $q->where('reservation_date', $request->date);
        if ($request->filled('status')) $q->where('status', $request->status);
        return $this->success($q->paginate(20));
    }

    public function store(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['customer_name' => 'required|string', 'reservation_date' => 'required|date', 'reservation_time' => 'required', 'party_size' => 'required|integer|min:1']);
        if ($v->fails()) return $this->validationError($v->errors());
        $reservation = Reservation::create(array_merge($request->only('customer_name','customer_phone','reservation_date','reservation_time','party_size','table_number','note'), ['business_id' => $request->get('_business_id'), 'outlet_id' => $request->get('_outlet_id'), 'created_by' => $request->user()->id]));
        return $this->success($reservation, 'Reservasi dibuat', 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $reservation = Reservation::where('business_id', $request->get('_business_id'))->find($id);
        if (!$reservation) return $this->notFound();
        $reservation->update($request->only('customer_name','customer_phone','reservation_date','reservation_time','party_size','table_number','note','status'));
        return $this->success($reservation, 'Reservasi diperbarui');
    }
}
