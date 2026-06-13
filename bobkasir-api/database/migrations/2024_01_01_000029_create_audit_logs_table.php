<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id')->nullable();
            $table->uuid('outlet_id')->nullable();
            $table->uuid('user_id')->nullable();
            $table->string('role', 20)->nullable();
            $table->string('device_id')->nullable();
            $table->string('action');
            $table->string('table_name')->nullable();
            $table->string('record_id')->nullable();
            $table->json('old_data')->nullable();
            $table->json('new_data')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }
    public function down(): void { Schema::dropIfExists('audit_logs'); }
};
