<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasUuids;

    protected $fillable = [
        'business_id', 'outlet_id', 'user_id', 'device_id', 'user_name', 'user_role',
        'opening_cash', 'closing_cash', 'total_cash', 'total_qris', 'total_transfer',
        'total_debit', 'total_ewallet', 'total_other', 'total_transactions',
        'total_cancels', 'total_refunds', 'opening_note', 'closing_note',
        'status', 'opened_at', 'closed_at',
    ];
    protected $casts = ['opened_at' => 'datetime', 'closed_at' => 'datetime'];

    public function orders(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Order::class); }

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class); }
}
