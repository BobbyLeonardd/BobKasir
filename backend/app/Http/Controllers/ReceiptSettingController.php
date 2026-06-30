<?php

namespace App\Http\Controllers;

use App\Models\ReceiptSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReceiptSettingController extends Controller
{
    public function show(Request $request)
    {
        $setting = ReceiptSetting::firstOrCreate(
            ['tenant_id' => $request->user()->tenant_id],
            ['shop_name' => $request->user()->tenant->shop_name ?? 'Kedai Saya', 'paper_width' => '58']
        );
        return response()->json(['data' => $setting]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'shop_name' => 'sometimes|string|max:100',
            'shop_address' => 'nullable|string',
            'footer_text' => 'nullable|string|max:300',
            'wifi_password' => 'nullable|string|max:100',
            'paper_width' => 'sometimes|in:58,80',
            'logo' => 'nullable|image|max:2048',
            'cash_drawer_enabled' => 'nullable|boolean',
        ]);

        $tenantId = $request->user()->tenant_id;
        $setting = ReceiptSetting::firstOrCreate(['tenant_id' => $tenantId]);

        if ($request->hasFile('logo')) {
            if ($setting->logo_url) {
                $old = str_replace('/storage/', '', $setting->logo_url);
                Storage::disk('public')->delete($old);
            }
            $path = $request->file('logo')->store("logos/{$tenantId}", 'public');
            $data['logo_url'] = Storage::url($path);
        }

        unset($data['logo']);
        $setting->update($data);

        return response()->json(['message' => 'Pengaturan struk diperbarui.', 'data' => $setting]);
    }
}
