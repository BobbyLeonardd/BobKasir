<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('email_verifications', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('otp', 6);
            $table->string('type')->default('verify'); // verify | reset_password | change_email
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index(['email', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('email_verifications');
    }
};
