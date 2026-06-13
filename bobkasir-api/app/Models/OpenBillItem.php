<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class OpenBillItem extends Model
{
    use HasUuids;

    protected $fillable = ['open_bill_id', 'product_id', 'product_name', 'price', 'qty', 'discount', 'note', 'subtotal'];
}
