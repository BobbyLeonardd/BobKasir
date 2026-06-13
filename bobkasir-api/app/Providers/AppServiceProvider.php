<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Support\Facades\Queue;
use App\Services\NotificationService;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Force HTTPS in production
        if (config('app.env') === 'production') {
            URL::forceScheme('https');
        }

        // Listen for failed queue jobs and notify via in-app notification
        Queue::failing(function (JobFailed $event) {
            \Log::error('Queue job failed', [
                'job'       => $event->job->getName(),
                'exception' => $event->exception->getMessage(),
            ]);
        });

        // Scheduled subscription expiry check (called by queue worker or cron)
        // php artisan schedule:run — every day at 08:00
        // See: routes/console.php
    }
}
