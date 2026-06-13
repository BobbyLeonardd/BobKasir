<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('owner_id');
            $table->string('plan')->nullable();
            $table->enum('status', ['trial', 'active', 'expired', 'pending_payment', 'payment_failed', 'cancelled'])->default('trial');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('expired_at')->nullable();
            $table->timestamp('trial_started_at')->nullable();
            $table->timestamp('trial_expired_at')->nullable();
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('owner_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('subscriptions'); }
};
