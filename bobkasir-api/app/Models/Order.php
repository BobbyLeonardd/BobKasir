<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = [
        'business_id', 'outlet_id', 'user_id', 'shift_id', 'device_id',
        'order_number', 'local_order_id', 'customer_name', 'table_number',
        'customer_phone', 'note', 'kitchen_note', 'subtotal', 'discount_total',
        'tax_total', 'service_charge_total', 'grand_total', 'paid_amount',
        'change_amount', 'payment_status', 'order_status', 'sync_status',
        'cashier_name', 'cashier_role', 'ordered_at',
    ];
    protected $casts = ['ordered_at' => 'datetime'];

    public function items(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(OrderItem::class); }

    public function payments(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Payment::class); }

    public function cancelRequest(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(CancelRequest::class); }

    public function refundRequest(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(RefundRequest::class); }

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class); }

    public function shift(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Shift::class); }
}
