<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('reservations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('outlet_id')->nullable();
            $table->uuid('created_by');
            $table->string('customer_name');
            $table->string('customer_phone', 30)->nullable();
            $table->date('reservation_date');
            $table->time('reservation_time');
            $table->integer('party_size');
            $table->string('table_number')->nullable();
            $table->text('note')->nullable();
            $table->enum('status', ['pending', 'confirmed', 'arrived', 'completed', 'cancelled', 'no_show'])->default('pending');
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('created_by')->references('id')->on('users');
        });
    }
    public function down(): void { Schema::dropIfExists('reservations'); }
};
