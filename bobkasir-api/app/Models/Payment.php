<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasUuids;

    protected $fillable = ['order_id', 'method', 'amount', 'reference_number', 'status', 'paid_at'];
    protected $casts = ['paid_at' => 'datetime'];

    public function order(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Order::class); }
}
