<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'owner_id', 'plan', 'status', 'started_at', 'expired_at', 'trial_started_at', 'trial_expired_at'];
    protected $casts = [
        'started_at' => 'datetime', 'expired_at' => 'datetime',
        'trial_started_at' => 'datetime', 'trial_expired_at' => 'datetime',
    ];

    public function business(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Business::class); }

    public function payments(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(SubscriptionPayment::class); }

    public function isActive(): bool
    {
        return in_array($this->status, ['trial', 'active']) &&
               ($this->expired_at === null || $this->expired_at->isFuture());
    }
}
