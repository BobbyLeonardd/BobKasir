<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Reservation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReservationController extends Controller
{
    public function index(Request $request)
    {
        $query = Reservation::where('tenant_id', $request->user()->tenant_id)
            ->with('user:id,name');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('date')) {
            $query->whereDate('arrival_time', $request->date);
        }

        return response()->json(['data' => $query->orderBy('arrival_time')->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'customer_name' => 'required|string|max:100',
            'table_number' => 'nullable|string|max:50',
            'arrival_time' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $reservation = Reservation::create([
            'tenant_id' => $request->user()->tenant_id,
            'user_id' => $request->user()->id,
            'customer_name' => $data['customer_name'],
            'table_number' => $data['table_number'] ?? null,
            'arrival_time' => $data['arrival_time'],
            'notes' => $data['notes'] ?? null,
            'status' => 'pending',
        ]);

        return response()->json(['message' => 'Reservasi dibuat.', 'data' => $reservation], 201);
    }

    public function update(Request $request, int $id)
    {
        $reservation = Reservation::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);

        $data = $request->validate([
            'customer_name' => 'sometimes|string|max:100',
            'table_number' => 'nullable|string|max:50',
            'arrival_time' => 'sometimes|date',
            'notes' => 'nullable|string',
        ]);

        $reservation->update($data);
        return response()->json(['message' => 'Reservasi diperbarui.', 'data' => $reservation]);
    }

    /** POST /reservations/{id}/arrive — convert to order */
    public function arrive(Request $request, int $id)
    {
        $reservation = Reservation::where('tenant_id', $request->user()->tenant_id)
            ->where('status', 'pending')
            ->findOrFail($id);

        $reservation->update(['status' => 'arrived']);

        return response()->json([
            'message' => 'Reservasi dikonversi. Tambahkan item ke keranjang.',
            'data' => $reservation,
        ]);
    }

    /** POST /reservations/{id}/cancel */
    public function cancel(Request $request, int $id)
    {
        $reservation = Reservation::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $data = $request->validate(['reason' => 'nullable|string']);
        $reservation->update(['status' => 'cancelled', 'cancel_reason' => $data['reason'] ?? null]);
        return response()->json(['message' => 'Reservasi dibatalkan.']);
    }
}
