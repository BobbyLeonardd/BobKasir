<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('open_bill_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('open_bill_id');
            $table->uuid('product_id')->nullable();
            $table->string('product_name');
            $table->integer('price');
            $table->integer('qty');
            $table->integer('discount')->default(0);
            $table->text('note')->nullable();
            $table->integer('subtotal');
            $table->timestamps();
            $table->foreign('open_bill_id')->references('id')->on('open_bills')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->nullOnDelete();
        });
    }
    public function down(): void { Schema::dropIfExists('open_bill_items'); }
};
