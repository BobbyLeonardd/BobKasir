<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Password;

class SendPasswordResetEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(private readonly string $email) {}

    public function handle(): void
    {
        Password::sendResetLink(['email' => $this->email]);
    }

    public function failed(\Throwable $e): void
    {
        \Log::error('Password reset email job failed', [
            'email' => $this->email,
            'error' => $e->getMessage(),
        ]);
    }
}
