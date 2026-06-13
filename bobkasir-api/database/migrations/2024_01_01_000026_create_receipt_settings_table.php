<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('receipt_settings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id')->unique();
            $table->string('business_name')->nullable();
            $table->text('address')->nullable();
            $table->string('phone', 30)->nullable();
            $table->text('footer')->nullable();
            $table->string('wifi_password')->nullable();
            $table->string('logo_text')->nullable();
            $table->boolean('show_table_number')->default(true);
            $table->boolean('show_customer_name')->default(true);
            $table->boolean('show_cashier_name')->default(true);
            $table->boolean('show_tax')->default(true);
            $table->boolean('show_service_charge')->default(true);
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('receipt_settings'); }
};
