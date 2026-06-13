<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class OpenBill extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'outlet_id', 'user_id', 'bill_number', 'customer_name', 'table_number', 'note', 'status'];

    public function items(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(OpenBillItem::class); }

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class); }

    public function getSubtotalAttribute(): int
    { return $this->items->sum('subtotal'); }
}
