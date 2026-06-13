<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ReceiptSetting extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'business_name', 'address', 'phone', 'footer', 'wifi_password', 'logo_text', 'show_table_number', 'show_customer_name', 'show_cashier_name', 'show_tax', 'show_service_charge'];
    protected $casts = [
        'show_table_number' => 'boolean',
        'show_customer_name' => 'boolean',
        'show_cashier_name' => 'boolean',
        'show_tax' => 'boolean',
        'show_service_charge' => 'boolean',
    ];
}
