<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    protected $fillable = [
        'tenant_id', 'user_id', 'customer_name', 'table_number',
        'arrival_time', 'notes', 'status', 'cancel_reason',
    ];

    protected $casts = [
        'arrival_time' => 'datetime',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
