<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasUuids;

    protected $fillable = ['order_id', 'product_id', 'product_name_snapshot', 'price_snapshot', 'qty', 'discount', 'note', 'subtotal'];

    public function order(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Order::class); }

    public function product(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Product::class); }
}
