<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('user_business_roles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id');
            $table->uuid('business_id');
            $table->uuid('outlet_id')->nullable();
            $table->enum('role', ['owner', 'manager', 'karyawan']);
            $table->enum('status', ['active', 'inactive', 'pending', 'blocked'])->default('active');
            $table->timestamps();
            $table->unique(['user_id', 'business_id']);
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('outlet_id')->references('id')->on('outlets')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('user_business_roles'); }
};
