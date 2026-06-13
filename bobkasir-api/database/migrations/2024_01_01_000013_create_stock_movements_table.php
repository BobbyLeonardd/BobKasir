<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('stock_id');
            $table->uuid('user_id')->nullable();
            $table->enum('type', ['in', 'out', 'adjustment', 'sale', 'cancel_return', 'refund_return']);
            $table->integer('quantity');
            $table->integer('quantity_before');
            $table->integer('quantity_after');
            $table->string('reference_id')->nullable();
            $table->string('reference_type')->nullable();
            $table->text('note')->nullable();
            $table->timestamps();
            $table->foreign('stock_id')->references('id')->on('stocks')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('stock_movements'); }
};
