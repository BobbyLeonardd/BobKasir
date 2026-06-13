<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class SyncLog extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected $casts = ['payload' => 'array'];
}
