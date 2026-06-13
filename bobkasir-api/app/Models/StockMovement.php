<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class StockMovement extends Model
{
    use HasUuids;

    protected $fillable = ['stock_id', 'user_id', 'type', 'quantity', 'quantity_before', 'quantity_after', 'reference_id', 'reference_type', 'note'];

    public function stock(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    { return $this->belongsTo(Stock::class); }
}
