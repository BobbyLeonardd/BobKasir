<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('taxes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('business_id');
            $table->string('name');
            $table->decimal('rate', 5, 2);
            $table->boolean('is_active')->default(false);
            $table->timestamps();
            $table->foreign('business_id')->references('id')->on('businesses')->cascadeOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('taxes'); }
};
