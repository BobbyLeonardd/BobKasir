<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('print_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('order_id');
            $table->uuid('user_id');
            $table->enum('type', ['customer', 'kitchen', 'report', 'shift']);
            $table->string('device_id')->nullable();
            $table->timestamp('printed_at')->useCurrent();
            $table->foreign('order_id')->references('id')->on('orders')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users');
        });
    }
    public function down(): void { Schema::dropIfExists('print_logs'); }
};
