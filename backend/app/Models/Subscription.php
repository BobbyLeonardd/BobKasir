<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    protected $fillable = [
        'tenant_id', 'package', 'start_date', 'end_date', 'status',
        'payment_method', 'midtrans_order_id', 'midtrans_transaction_id',
        'manual_proof', 'webhook_retry_count',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'webhook_retry_count' => 'integer',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function getDurationDays(): int
    {
        return $this->package === 'weekly' ? 7 : 30;
    }
}
