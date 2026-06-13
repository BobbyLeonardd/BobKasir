<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\SendEmailVerification;
use App\Jobs\SendPasswordResetEmail;
use App\Models\AuditLog;
use App\Models\Business;
use App\Models\Subscription;
use App\Models\User;
use App\Models\UserBusinessRole;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Laravel\Socialite\Facades\Socialite;

class AuthController extends Controller
{
    use ApiResponse;

    /** API token lifetime in days (H2 — tokens must expire). */
    private const tokenTtlDays = 30;

    // ──────────────────────────────────────────
    // POST /api/auth/register
    // ──────────────────────────────────────────
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        // Create user
        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'status'   => 'pending',
        ]);

        // Create business
        $business = Business::create([
            'owner_id' => $user->id,
            'name'     => $request->name . "'s Business",
            'status'   => 'active',
        ]);

        // Create owner role
        UserBusinessRole::create([
            'user_id'     => $user->id,
            'business_id' => $business->id,
            'role'        => 'owner',
            'status'      => 'active',
        ]);

        // Create trial subscription (7 days)
        Subscription::create([
            'business_id'       => $business->id,
            'owner_id'          => $user->id,
            'status'            => 'trial',
            'trial_started_at'  => now(),
            'trial_expired_at'  => now()->addDays(7),
        ]);

        // Send email verification via queue (async)
        SendEmailVerification::dispatch($user);

        return $this->success(
            ['user_id' => $user->id, 'email' => $user->email],
            'Registrasi berhasil. Cek email untuk verifikasi.',
            201
        );
    }

    // ──────────────────────────────────────────
    // POST /api/auth/login
    // ──────────────────────────────────────────
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->error('Email atau password salah', 401);
        }

        if ($user->status !== 'active' && $user->status !== 'pending') {
            return $this->error('Akun diblokir atau tidak aktif', 403);
        }

        // Load role
        $roleRecord = $user->businessRole;

        // Owner & Manager: require email verified
        if ($roleRecord && in_array($roleRecord->role, ['owner', 'manager'])) {
            if (!$user->hasVerifiedEmail()) {
                return $this->error('Email belum diverifikasi. Cek inbox email Anda.', 403, [
                    'email_unverified' => true,
                    'email' => $user->email,
                ]);
            }
        }

        $user->update(['status' => 'active']);

        $token = $user->createToken('api-token', ['*'], now()->addDays(self::tokenTtlDays))->plainTextToken;

        return $this->success([
            'token'         => $token,
            'user'          => $this->userPayload($user, $roleRecord),
        ], 'Login berhasil');
    }

    // ──────────────────────────────────────────
    // POST /api/auth/google
    // Flutter mengirim access_token atau id_token dari Google Sign-In SDK
    // ──────────────────────────────────────────
    public function googleLogin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'access_token' => 'nullable|string',
            'id_token'     => 'nullable|string',
        ]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        if (!$request->filled('access_token') && !$request->filled('id_token')) {
            return $this->error('access_token atau id_token diperlukan', 422);
        }

        // Validasi token Google via Google API secara manual jika Socialite gagal
        $googleUser = null;
        $lastError  = '';

        // Coba via access_token dulu
        if ($request->filled('access_token')) {
            try {
                $googleUser = Socialite::driver('google')->stateless()->userFromToken($request->access_token);
            } catch (\Exception $e) {
                $lastError = $e->getMessage();
            }
        }

        // Fallback: validasi id_token langsung via Google tokeninfo endpoint
        if (!$googleUser && $request->filled('id_token')) {
            try {
                $idToken  = $request->id_token;
                $response = \Illuminate\Support\Facades\Http::get(
                    'https://oauth2.googleapis.com/tokeninfo',
                    ['id_token' => $idToken]
                );

                if ($response->successful()) {
                    $payload = $response->json();
                    // Verify audience matches our client ID
                    $clientId = config('services.google.client_id');
                    if (isset($payload['aud']) && $payload['aud'] === $clientId) {
                        // Build a simple user object
                        $googleUser = (object) [
                            'id'       => $payload['sub'],
                            'name'     => $payload['name'] ?? '',
                            'email'    => $payload['email'] ?? '',
                            'avatar'   => $payload['picture'] ?? null,
                        ];
                        // Override getId/getName/etc with closures won't work — use array instead
                        $googleUserData = [
                            'id'     => $payload['sub'],
                            'name'   => $payload['name'] ?? '',
                            'email'  => $payload['email'] ?? '',
                            'avatar' => $payload['picture'] ?? null,
                        ];
                        $googleUser = null; // reset, use array below
                    }
                }
            } catch (\Exception $e) {
                $lastError = $e->getMessage();
            }
        }

        // Process with Socialite user object
        if ($googleUser) {
            $googleUserData = [
                'id'     => $googleUser->getId(),
                'name'   => $googleUser->getName(),
                'email'  => $googleUser->getEmail(),
                'avatar' => $googleUser->getAvatar(),
            ];
        }

        if (empty($googleUserData)) {
            return $this->error('Token Google tidak valid: ' . $lastError, 401);
        }

        $isNewUser = false;
        $user = User::where('google_id', $googleUserData['id'])
            ->orWhere('email', $googleUserData['email'])
            ->first();

        if (!$user) {
            $isNewUser = true;
            $user = User::create([
                'name'              => $googleUserData['name'],
                'email'             => $googleUserData['email'],
                'google_id'         => $googleUserData['id'],
                'avatar'            => $googleUserData['avatar'],
                'email_verified_at' => now(),
                'status'            => 'active',
            ]);

            $business = Business::create([
                'owner_id' => $user->id,
                'name'     => $user->name . "'s Business",
                'status'   => 'active',
            ]);

            UserBusinessRole::create([
                'user_id'     => $user->id,
                'business_id' => $business->id,
                'role'        => 'owner',
                'status'      => 'active',
            ]);

            Subscription::create([
                'business_id'      => $business->id,
                'owner_id'         => $user->id,
                'status'           => 'trial',
                'trial_started_at' => now(),
                'trial_expired_at' => now()->addDays(7),
            ]);

            // Audit log register
            AuditLog::create([
                'business_id' => $business->id,
                'user_id'     => $user->id,
                'role'        => 'owner',
                'action'      => 'register',
                'table_name'  => 'users',
                'record_id'   => $user->id,
                'new_data'    => ['method' => 'google', 'email' => $user->email],
                'ip_address'  => $request->ip(),
            ]);
        } else {
            // Update google_id dan verifikasi email jika belum
            $user->update([
                'google_id'         => $googleUserData['id'],
                'email_verified_at' => $user->email_verified_at ?? now(),
                'status'            => 'active',
            ]);

            // Audit log login
            AuditLog::create([
                'user_id'    => $user->id,
                'action'     => 'login',
                'table_name' => 'users',
                'record_id'  => $user->id,
                'new_data'   => ['method' => 'google'],
                'ip_address' => $request->ip(),
            ]);
        }

        $roleRecord = $user->businessRole;
        $token      = $user->createToken('api-token', ['*'], now()->addDays(self::tokenTtlDays))->plainTextToken;

        $payload        = $this->userPayload($user, $roleRecord);
        $payload['is_new_user'] = $isNewUser;

        return $this->success([
            'token' => $token,
            'user'  => $payload,
        ], $isNewUser ? 'Akun berhasil dibuat via Google' : 'Login Google berhasil');
    }

    // ──────────────────────────────────────────
    // POST /api/auth/logout
    // ──────────────────────────────────────────
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return $this->success(null, 'Logout berhasil');
    }

    // ──────────────────────────────────────────
    // GET /api/auth/me
    // ──────────────────────────────────────────
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('businessRole.business');
        $roleRecord = $user->businessRole;
        return $this->success($this->userPayload($user, $roleRecord));
    }

    // ──────────────────────────────────────────
    // POST /api/auth/forgot-password
    // ──────────────────────────────────────────
    public function forgotPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), ['email' => 'required|email']);
        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        $status = Password::sendResetLink(['email' => $request->email]);

        return $status === Password::RESET_LINK_SENT
            ? $this->success(null, 'Link reset password dikirim ke email Anda')
            : $this->error('Email tidak ditemukan', 404);
    }

    // ──────────────────────────────────────────
    // POST /api/auth/reset-password
    // ──────────────────────────────────────────
    public function resetPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'token'    => 'required',
            'email'    => 'required|email',
            'password' => 'required|string|min:8|confirmed',
        ]);
        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        $status = Password::reset($request->only('email', 'password', 'password_confirmation', 'token'), function (User $user, string $password) {
            $user->forceFill(['password' => Hash::make($password)])->save();
            $user->tokens()->delete();
        });

        return $status === Password::PASSWORD_RESET
            ? $this->success(null, 'Password berhasil direset')
            : $this->error('Token tidak valid atau kadaluarsa', 400);
    }

    // ──────────────────────────────────────────
    // GET /api/auth/verify-email/{id}/{hash}  (name: verification.verify)
    // Protected by the `signed` middleware → the URL is HMAC-signed with
    // APP_KEY and carries an expiry, so it cannot be forged (C2).
    // ──────────────────────────────────────────
    public function verifyEmail(Request $request, string $id, string $hash): JsonResponse
    {
        $user = User::find($id);
        if (!$user) {
            return $this->notFound('User tidak ditemukan');
        }

        // Defense-in-depth: confirm the hash matches this user's email.
        if (!hash_equals(sha1($user->getEmailForVerification()), (string) $hash)) {
            return $this->error('Link verifikasi tidak valid', 400);
        }

        if (!$user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
            $user->update(['status' => 'active']);
        }

        return $this->success(null, 'Email berhasil diverifikasi');
    }

    // ──────────────────────────────────────────
    // POST /api/auth/resend-verification
    // ──────────────────────────────────────────
    public function resendVerification(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), ['email' => 'required|email']);
        if ($validator->fails()) {
            return $this->validationError($validator->errors());
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return $this->error('Email tidak ditemukan', 404);
        }

        if ($user->hasVerifiedEmail()) {
            return $this->error('Email sudah diverifikasi', 400);
        }

        SendEmailVerification::dispatch($user);
        return $this->success(null, 'Email verifikasi dikirim ulang');
    }

    // ──────────────────────────────────────────
    // Helper
    // ──────────────────────────────────────────
    private function userPayload(User $user, mixed $roleRecord): array
    {
        $business = $roleRecord?->business ?? Business::where('owner_id', $user->id)->first();
        $sub = $business?->subscription;

        return [
            'id'            => $user->id,
            'name'          => $user->name,
            'email'         => $user->email,
            'avatar'        => $user->avatar,
            'role'          => $roleRecord?->role ?? 'owner',
            'business_id'   => $business?->id,
            'business_name' => $business?->name,
            'outlet_id'     => $roleRecord?->outlet_id,
            'subscription'  => $sub ? [
                'status'     => $sub->status,
                'expired_at' => $sub->expired_at?->toISOString(),
            ] : null,
        ];
    }
}
