<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('sync_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->string('device_id');
            $table->string('sync_id')->unique();
            $table->string('local_id');
            $table->string('type');
            $table->enum('status', ['pending', 'synced', 'failed'])->default('pending');
            $table->json('payload')->nullable();
            $table->text('error_message')->nullable();
            $table->integer('retry_count')->default(0);
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('sync_logs'); }
};
