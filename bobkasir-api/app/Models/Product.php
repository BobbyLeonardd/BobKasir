<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = ['business_id', 'category_id', 'name', 'price', 'cost', 'sku', 'barcode', 'description', 'is_active', 'track_stock'];
    protected $casts = ['is_active' => 'boolean', 'track_stock' => 'boolean'];

    public function category(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Category::class); }

    public function images(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(ProductImage::class); }

    public function stock(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(Stock::class); }

    public function primaryImage(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(ProductImage::class)->where('is_primary', true); }
}
