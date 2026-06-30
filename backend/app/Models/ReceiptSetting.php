<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReceiptSetting extends Model
{
    protected $fillable = [
        'tenant_id', 'shop_name', 'shop_address', 'footer_text',
        'wifi_password', 'paper_width', 'logo_url', 'cash_drawer_enabled',
    ];

    protected $casts = [
        'cash_drawer_enabled' => 'boolean',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
