<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class SubscriptionPayment extends Model
{
    use HasUuids;

    protected $fillable = ['subscription_id', 'business_id', 'plan', 'amount', 'midtrans_order_id', 'midtrans_transaction_id', 'payment_type', 'status', 'midtrans_response', 'paid_at'];
    protected $casts = ['midtrans_response' => 'array', 'paid_at' => 'datetime'];

    public function subscription(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Subscription::class); }
}
