<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class UserBusinessRole extends Model
{
    use HasUuids;

    protected $table = 'user_business_roles';
    protected $fillable = ['user_id', 'business_id', 'outlet_id', 'role', 'status'];

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class); }

    public function business(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Business::class); }

    public function outlet(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Outlet::class); }
}
