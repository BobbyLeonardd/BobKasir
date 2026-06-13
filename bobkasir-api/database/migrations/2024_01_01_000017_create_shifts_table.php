<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('shifts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->uuid('outlet_id')->nullable();
            $table->uuid('user_id');
            $table->uuid('device_id')->nullable();
            $table->string('user_name');
            $table->string('user_role', 20);
            $table->integer('opening_cash')->default(0);
            $table->integer('closing_cash')->nullable();
            $table->integer('total_cash')->default(0);
            $table->integer('total_qris')->default(0);
            $table->integer('total_transfer')->default(0);
            $table->integer('total_debit')->default(0);
            $table->integer('total_ewallet')->default(0);
            $table->integer('total_other')->default(0);
            $table->integer('total_transactions')->default(0);
            $table->integer('total_cancels')->default(0);
            $table->integer('total_refunds')->default(0);
            $table->text('opening_note')->nullable();
            $table->text('closing_note')->nullable();
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->timestamp('opened_at');
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
            $table->foreign('user_id')->references('id')->on('users');
            $table->foreign('outlet_id')->references('id')->on('outlets')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('shifts'); }
};
