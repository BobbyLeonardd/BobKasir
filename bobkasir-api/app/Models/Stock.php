<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Stock extends Model
{
    use HasUuids;

    protected $fillable = ['product_id', 'outlet_id', 'quantity', 'minimum_stock'];

    public function product(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Product::class); }

    public function movements(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(StockMovement::class); }
}
