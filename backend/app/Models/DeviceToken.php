<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceToken extends Model
{
    protected $fillable = ['user_id', 'tenant_id', 'fcm_token', 'device_platform', 'device_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
