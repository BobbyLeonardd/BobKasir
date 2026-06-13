<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('user_id')->nullable();
            $table->string('device_id')->unique();
            $table->string('name')->nullable();
            $table->string('app_version', 20)->nullable();
            $table->boolean('is_active')->default(true);
            $table->string('printer_address')->nullable();
            $table->string('printer_name')->nullable();
            $table->string('paper_size', 10)->default('80mm');
            $table->timestamp('last_login_at')->nullable();
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('devices'); }
};
