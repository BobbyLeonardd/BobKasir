<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipt_settings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tenant_id')->unique();
            $table->string('shop_name');
            $table->text('shop_address')->nullable();
            $table->text('footer_text')->nullable();
            $table->string('wifi_password')->nullable();
            $table->enum('paper_width', ['58', '80'])->default('58');
            $table->string('logo_url')->nullable();
            $table->boolean('cash_drawer_enabled')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipt_settings');
    }
};
