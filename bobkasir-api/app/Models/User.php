<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Auth\MustVerifyEmail as MustVerifyEmailTrait;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasUuids, Notifiable, MustVerifyEmailTrait;

    protected $fillable = ['name', 'email', 'password', 'google_id', 'email_verified_at', 'phone', 'avatar', 'status'];
    protected $hidden = ['password', 'remember_token'];
    protected $casts = ['email_verified_at' => 'datetime', 'password' => 'hashed'];

    public function businessRole(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(UserBusinessRole::class);
    }

    public function business(): \Illuminate\Database\Eloquent\Relations\HasOneThrough
    {
        return $this->hasOneThrough(Business::class, UserBusinessRole::class, 'user_id', 'id', 'id', 'business_id');
    }

    public function getRoleForBusiness(string $businessId): ?string
    {
        return $this->businessRole?->role;
    }
}
