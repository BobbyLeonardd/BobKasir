<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('order_id');
            $table->string('method'); // cash, qris, transfer, debit, ewallet, other
            $table->integer('amount');
            $table->string('reference_number')->nullable();
            $table->enum('status', ['pending', 'paid', 'failed', 'refunded'])->default('paid');
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('payments'); }
};
