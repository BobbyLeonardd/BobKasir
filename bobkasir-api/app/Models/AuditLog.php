<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasUuids;

    public $timestamps = false;
    protected $fillable = ['business_id', 'outlet_id', 'user_id', 'role', 'device_id', 'action', 'table_name', 'record_id', 'old_data', 'new_data', 'ip_address', 'created_at'];
    protected $casts = ['old_data' => 'array', 'new_data' => 'array', 'created_at' => 'datetime'];
}
