<?php

namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendEmailVerification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60; // seconds between retries

    public function __construct(private readonly User $user) {}

    public function handle(): void
    {
        $this->user->sendEmailVerificationNotification();
    }

    public function failed(\Throwable $e): void
    {
        \Log::error('Email verification job failed', [
            'user_id' => $this->user->id,
            'error'   => $e->getMessage(),
        ]);
    }
}
