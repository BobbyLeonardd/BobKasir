<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('cashdrawer_settings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id')->unique();
            $table->enum('mode', ['off', 'auto_cash', 'manual', 'always_ask'])->default('off');
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('cashdrawer_settings'); }
};
