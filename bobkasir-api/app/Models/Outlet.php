<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Outlet extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'name', 'address', 'phone', 'is_active'];
    protected $casts = ['is_active' => 'boolean'];

    public function business(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Business::class); }
}
