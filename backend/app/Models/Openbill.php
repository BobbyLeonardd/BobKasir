<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Openbill extends Model
{
    protected $fillable = ['tenant_id', 'user_id', 'label', 'items_snapshot'];

    protected $casts = [
        'items_snapshot' => 'array',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
