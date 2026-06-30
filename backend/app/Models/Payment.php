<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'order_id', 'method', 'amount', 'change_amount', 'reference', 'paid_at', 'split_index',
    ];

    protected $casts = [
        'amount' => 'integer',
        'change_amount' => 'integer',
        'paid_at' => 'datetime',
        'split_index' => 'integer',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
