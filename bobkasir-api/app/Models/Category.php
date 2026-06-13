<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'name', 'description', 'sort_order', 'is_active'];
    protected $casts = ['is_active' => 'boolean'];

    public function products(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Product::class); }
}
