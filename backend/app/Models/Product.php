<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = [
        'tenant_id', 'category_id', 'name', 'description',
        'price', 'image_url', 'stock', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'price' => 'integer',
        'stock' => 'integer',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Normalize price input like "Rp50.000", "50.000", "50000" → integer
     */
    public static function normalizePrice(string|int|float $price): int
    {
        if (is_int($price)) {
            return $price;
        }
        $clean = preg_replace('/[^0-9]/', '', (string) $price);
        return (int) $clean;
    }
}
