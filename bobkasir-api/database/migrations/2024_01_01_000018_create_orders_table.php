<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('outlet_id')->nullable();
            $table->uuid('user_id');
            $table->uuid('shift_id')->nullable();
            $table->uuid('device_id')->nullable();
            $table->string('order_number')->unique()->nullable();
            $table->string('local_order_id')->nullable();
            $table->string('customer_name')->nullable();
            $table->string('table_number')->nullable();
            $table->string('customer_phone', 30)->nullable();
            $table->text('note')->nullable();
            $table->text('kitchen_note')->nullable();
            $table->integer('subtotal')->default(0);
            $table->integer('discount_total')->default(0);
            $table->integer('tax_total')->default(0);
            $table->integer('service_charge_total')->default(0);
            $table->integer('grand_total')->default(0);
            $table->integer('paid_amount')->default(0);
            $table->integer('change_amount')->default(0);
            $table->enum('payment_status', ['unpaid', 'paid', 'partial', 'refunded'])->default('unpaid');
            $table->enum('order_status', ['completed', 'cancel_requested', 'cancelled', 'refund_requested', 'refunded'])->default('completed');
            $table->enum('sync_status', ['pending', 'synced', 'failed'])->default('synced');
            $table->string('cashier_name')->nullable();
            $table->string('cashier_role', 20)->nullable();
            $table->timestamp('ordered_at');
            $table->timestamps();
            $table->softDeletes();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('outlet_id')->references('id')->on('outlets')->nullOnDelete();
            $table->foreign('shift_id')->references('id')->on('shifts')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('orders'); }
};
