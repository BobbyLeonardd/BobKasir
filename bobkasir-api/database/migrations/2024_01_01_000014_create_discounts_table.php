<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('discounts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->string('name');
            $table->enum('type', ['percent', 'nominal']);
            $table->decimal('value', 10, 2);
            $table->integer('max_discount')->nullable();
            $table->integer('min_transaction')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('discounts'); }
};
