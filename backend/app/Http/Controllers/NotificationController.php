<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = AppNotification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);
        return response()->json(['data' => $notifications]);
    }

    public function markRead(Request $request, int $id)
    {
        $notification = AppNotification::where('user_id', $request->user()->id)->findOrFail($id);
        $notification->update(['read_at' => now()]);
        return response()->json(['message' => 'Ditandai sudah dibaca.']);
    }

    public function markAllRead(Request $request)
    {
        AppNotification::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca.']);
    }

    public function registerDeviceToken(Request $request)
    {
        $data = $request->validate([
            'fcm_token' => 'required|string',
            'device_platform' => 'required|in:android,ios',
            'device_id' => 'nullable|string',
        ]);

        $user = $request->user();

        DeviceToken::updateOrCreate(
            ['user_id' => $user->id, 'device_id' => $data['device_id'] ?? null],
            [
                'tenant_id' => $user->tenant_id,
                'fcm_token' => $data['fcm_token'],
                'device_platform' => $data['device_platform'],
            ]
        );

        return response()->json(['message' => 'Device token terdaftar.']);
    }
}
