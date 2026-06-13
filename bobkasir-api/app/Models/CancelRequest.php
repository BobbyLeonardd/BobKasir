<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class CancelRequest extends Model
{
    use HasUuids;

    protected $fillable = ['order_id', 'requested_by', 'reviewed_by', 'reason', 'status', 'review_note', 'reviewed_at'];
    protected $casts = ['reviewed_at' => 'datetime'];

    public function order(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Order::class); }

    public function requester(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class, 'requested_by'); }

    public function reviewer(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class, 'reviewed_by'); }
}
