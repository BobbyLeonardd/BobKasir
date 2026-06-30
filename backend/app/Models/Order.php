<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'tenant_id', 'user_id', 'cashier_name', 'customer_name',
        'table_number', 'notes', 'total', 'payment_status', 'status',
        'sync_status', 'local_id', 'needs_review',
    ];

    protected $casts = [
        'total' => 'integer',
        'needs_review' => 'boolean',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function cancelRequest()
    {
        return $this->hasOne(CancelRequest::class)->latest();
    }
}
