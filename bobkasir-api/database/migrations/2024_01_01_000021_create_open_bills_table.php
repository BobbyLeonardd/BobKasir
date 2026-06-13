<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('open_bills', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('outlet_id')->nullable();
            $table->uuid('user_id');
            $table->string('bill_number')->unique();
            $table->string('customer_name')->nullable();
            $table->string('table_number')->nullable();
            $table->text('note')->nullable();
            $table->enum('status', ['open', 'updated', 'checked_out', 'cancelled'])->default('open');
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users');
        });
    }
    public function down(): void { Schema::dropIfExists('open_bills'); }
};
