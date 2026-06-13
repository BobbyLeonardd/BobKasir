<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Promo extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'name', 'code', 'type', 'discount_value', 'min_transaction', 'max_discount', 'usage_limit', 'usage_count', 'valid_from', 'valid_until', 'is_active', 'description'];
    protected $casts = ['is_active' => 'boolean', 'valid_from' => 'datetime', 'valid_until' => 'datetime'];

    public function isValid(): bool
    {
        if (!$this->is_active) return false;
        $now = now();
        if ($this->valid_from && $now->lt($this->valid_from)) return false;
        if ($this->valid_until && $now->gt($this->valid_until)) return false;
        if ($this->usage_limit && $this->usage_count >= $this->usage_limit) return false;
        return true;
    }

    public function calculateDiscount(int $subtotal): int
    {
        if ($this->type === 'percent') {
            $raw = (int) round($subtotal * $this->discount_value / 100);
            return $this->max_discount ? min($raw, $this->max_discount) : $raw;
        }
        return min((int) $this->discount_value, $subtotal);
    }
}
