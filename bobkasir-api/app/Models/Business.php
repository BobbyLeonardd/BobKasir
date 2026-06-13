<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Business extends Model
{
    use HasUuids;

    protected $fillable = ['owner_id', 'name', 'address', 'phone', 'status'];

    public function owner(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class, 'owner_id'); }

    public function outlets(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Outlet::class); }

    public function subscription(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(Subscription::class); }

    public function members(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(UserBusinessRole::class); }

    public function categories(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Category::class); }

    public function products(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Product::class); }

    public function orders(): \Illuminate\Database\Eloquent\Relations\HasMany
    { return $this->hasMany(Order::class); }

    public function receiptSetting(): \Illuminate\Database\Eloquent\Relations\HasOne
    { return $this->hasOne(ReceiptSetting::class); }
}
