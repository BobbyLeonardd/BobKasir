<?php

namespace App\Services;

use App\Models\EmailVerification;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    public function generate(string $email, string $type): string
    {
        // Delete any existing OTP for this email+type
        EmailVerification::where('email', $email)->where('type', $type)->delete();

        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        EmailVerification::create([
            'email' => $email,
            'otp' => $otp,
            'type' => $type,
            'expires_at' => now()->addMinutes(10),
        ]);

        return $otp;
    }

    public function verify(string $email, string $otp, string $type): bool
    {
        $record = EmailVerification::where('email', $email)
            ->where('otp', $otp)
            ->where('type', $type)
            ->first();

        if (!$record || $record->isExpired()) {
            return false;
        }

        $record->delete();
        return true;
    }

    public function sendVerification(string $email, string $name, string $otp): void
    {
        Mail::send('emails.otp', ['otp' => $otp, 'name' => $name, 'type' => 'verifikasi akun'], function ($m) use ($email) {
            $m->to($email)->subject('Kode Verifikasi BobKasir');
        });
    }

    public function sendPasswordReset(string $email, string $name, string $otp): void
    {
        Mail::send('emails.otp', ['otp' => $otp, 'name' => $name, 'type' => 'reset sandi'], function ($m) use ($email) {
            $m->to($email)->subject('Reset Sandi BobKasir');
        });
    }
}
