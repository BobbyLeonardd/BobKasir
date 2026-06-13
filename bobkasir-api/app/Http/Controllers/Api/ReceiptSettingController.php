<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ReceiptSetting;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReceiptSettingController extends Controller
{
    use ApiResponse;

    public function show(Request $request): JsonResponse
    {
        $setting = ReceiptSetting::firstOrCreate(['business_id' => $request->get('_business_id')]);
        return $this->success($setting);
    }

    public function update(Request $request): JsonResponse
    {
        $setting = ReceiptSetting::firstOrCreate(['business_id' => $request->get('_business_id')]);
        $setting->update($request->only('business_name','address','phone','footer','wifi_password','logo_text','show_table_number','show_customer_name','show_cashier_name','show_tax','show_service_charge'));
        AuditLog::create([
            'business_id' => $request->get('_business_id'), 'user_id' => $request->user()->id,
            'role' => $request->get('_user_role'), 'action' => 'ubah_struk',
            'table_name' => 'receipt_settings', 'record_id' => $setting->id,
            'ip_address' => $request->ip(),
        ]);
        return $this->success($setting, 'Pengaturan struk diperbarui');
    }
}
