<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('printer_settings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('device_id')->nullable();
            $table->string('printer_name')->nullable();
            $table->string('printer_address')->nullable();
            $table->string('paper_size', 10)->default('80mm');
            $table->boolean('auto_cut')->default(true);
            $table->integer('feed_lines')->default(3);
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('printer_settings'); }
};
