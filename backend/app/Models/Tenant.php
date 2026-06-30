<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tenant extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'owner_user_id', 'shop_name', 'shop_address', 'shop_phone',
        'subscription_status', 'subscription_expires_at', 'trial_until',
    ];

    protected $casts = [
        'subscription_expires_at' => 'datetime',
        'trial_until' => 'datetime',
    ];

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function receiptSettings()
    {
        return $this->hasOne(ReceiptSetting::class);
    }

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)->whereIn('status', ['active'])->latest();
    }

    /**
     * Check if tenant has full access (trial or active subscription within grace period).
     */
    public function hasFullAccess(): bool
    {
        $now = now();

        if ($this->subscription_status === 'trial' && $this->trial_until && $now->lte($this->trial_until)) {
            return true;
        }

        if ($this->subscription_status === 'active' && $this->subscription_expires_at) {
            // +1 day grace period
            return $now->lte($this->subscription_expires_at->addDay());
        }

        return false;
    }
}
