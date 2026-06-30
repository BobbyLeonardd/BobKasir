<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'tenant_id', 'user_id', 'action', 'entity_type',
        'entity_id', 'old_value', 'new_value', 'ip_address',
    ];

    protected $casts = [
        'old_value' => 'array',
        'new_value' => 'array',
        'created_at' => 'datetime',
    ];

    public static function record(string $action, ?Model $entity = null, array $old = [], array $new = []): void
    {
        $user = auth()->user();
        static::create([
            'tenant_id' => $user?->tenant_id,
            'user_id' => $user?->id,
            'action' => $action,
            'entity_type' => $entity ? class_basename($entity) : null,
            'entity_id' => $entity?->id,
            'old_value' => $old ?: null,
            'new_value' => $new ?: null,
            'ip_address' => request()->ip(),
        ]);
    }
}
