<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id');
            $table->unsignedBigInteger('user_id');
            $table->string('cashier_name');
            $table->string('customer_name')->nullable();
            $table->string('table_number')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('total')->default(0);
            $table->enum('payment_status', ['unpaid', 'paid', 'partial'])->default('unpaid');
            $table->enum('status', ['open', 'completed', 'cancelled', 'request_cancel'])->default('open');
            $table->enum('sync_status', ['pending_sync', 'synced'])->default('synced');
            $table->string('local_id')->nullable()->unique(); // UUID from device
            $table->boolean('needs_review')->default(false);
            $table->timestamps();

            $table->index('tenant_id');
            $table->index(['tenant_id', 'status']);
            $table->index(['tenant_id', 'user_id']);
            $table->index('local_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
