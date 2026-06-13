<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Reservation extends Model
{
    use HasUuids;

    protected $fillable = ['business_id', 'outlet_id', 'created_by', 'customer_name', 'customer_phone', 'reservation_date', 'reservation_time', 'party_size', 'table_number', 'note', 'status'];
    protected $casts = ['reservation_date' => 'date', 'reservation_time' => 'string'];

    public function creator(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(User::class, 'created_by'); }
}
