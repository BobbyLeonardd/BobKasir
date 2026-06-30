<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\Tenant;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Laravel\Socialite\Facades\Socialite;

class AuthController extends Controller
{
    public function __construct(private OtpService $otp) {}

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => ['required', Password::min(8)],
            'shop_name' => 'required|string|max:100',
            'shop_address' => 'nullable|string',
            'shop_phone' => 'nullable|string|max:20',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => 'owner',
            'status' => 'active',
        ]);

        // Create tenant
        $tenant = Tenant::create([
            'owner_user_id' => $user->id,
            'shop_name' => $data['shop_name'],
            'shop_address' => $data['shop_address'] ?? null,
            'shop_phone' => $data['shop_phone'] ?? null,
            'subscription_status' => 'trial',
            'trial_until' => now()->addDays(7),
        ]);

        $user->update(['tenant_id' => $tenant->id]);

        // Send email verification OTP
        $otp = $this->otp->generate($user->email, 'verify');
        $this->otp->sendVerification($user->email, $user->name, $otp);

        AuditLog::record('register_owner', $user);

        return response()->json([
            'message' => 'Registrasi berhasil. Cek email untuk kode verifikasi.',
            'user_id' => $user->id,
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_id' => 'nullable|string',
        ]);

        $user = User::where('email', $data['email'])->first();

        if (!$user || !Hash::check($data['password'], $user->password ?? '')) {
            return response()->json(['message' => 'Email atau sandi salah.'], 401);
        }

        if ($user->status !== 'active') {
            return response()->json(['message' => 'Akun tidak aktif.'], 403);
        }

        // Cashier doesn't need email verification on daily login
        if (in_array($user->role, ['owner', 'admin']) && !$user->email_verified_at) {
            $otp = $this->otp->generate($user->email, 'verify');
            $this->otp->sendVerification($user->email, $user->name, $otp);
            return response()->json([
                'message' => 'Verifikasi email diperlukan. Kode OTP telah dikirim.',
                'requires_verification' => true,
                'email' => $user->email,
            ], 403);
        }

        $token = $user->createToken('access_token', ['*'], now()->addMinutes(15))->plainTextToken;
        $refreshToken = $user->createToken('refresh_token', ['refresh'], now()->addDays(30))->plainTextToken;

        AuditLog::record('login', $user);

        return response()->json([
            'token' => $token,
            'refresh_token' => $refreshToken,
            'user' => $this->userResource($user),
        ]);
    }

    public function googleAuth(Request $request)
    {
        $data = $request->validate([
            'id_token' => 'required|string',
            'shop_name' => 'nullable|string|max:100', // for new owner registration
        ]);

        // Verify Google token
        $googleUser = $this->verifyGoogleToken($data['id_token']);
        if (!$googleUser) {
            return response()->json(['message' => 'Token Google tidak valid.'], 401);
        }

        $user = User::where('google_id', $googleUser['sub'])
            ->orWhere('email', $googleUser['email'])
            ->first();

        if (!$user) {
            // New owner registration via Google
            if (empty($data['shop_name'])) {
                return response()->json([
                    'message' => 'Akun baru. Masukkan nama kedai untuk melanjutkan.',
                    'requires_shop_name' => true,
                    'email' => $googleUser['email'],
                    'name' => $googleUser['name'],
                ], 200);
            }

            $user = User::create([
                'name' => $googleUser['name'],
                'email' => $googleUser['email'],
                'google_id' => $googleUser['sub'],
                'role' => 'owner',
                'email_verified_at' => now(),
                'status' => 'active',
            ]);

            $tenant = Tenant::create([
                'owner_user_id' => $user->id,
                'shop_name' => $data['shop_name'],
                'subscription_status' => 'trial',
                'trial_until' => now()->addDays(7),
            ]);

            $user->update(['tenant_id' => $tenant->id]);
        } else {
            if ($user->status !== 'active') {
                return response()->json(['message' => 'Akun tidak aktif.'], 403);
            }
            // Update google_id if not set
            if (!$user->google_id) {
                $user->update(['google_id' => $googleUser['sub'], 'email_verified_at' => $user->email_verified_at ?? now()]);
            }
        }

        $token = $user->createToken('access_token', ['*'], now()->addMinutes(15))->plainTextToken;
        $refreshToken = $user->createToken('refresh_token', ['refresh'], now()->addDays(30))->plainTextToken;

        AuditLog::record('login_google', $user);

        return response()->json([
            'token' => $token,
            'refresh_token' => $refreshToken,
            'user' => $this->userResource($user),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logout berhasil.']);
    }

    public function refresh(Request $request)
    {
        $user = $request->user();
        // Delete current token and issue new access token
        $request->user()->currentAccessToken()->delete();
        $token = $user->createToken('access_token', ['*'], now()->addMinutes(15))->plainTextToken;
        $refreshToken = $user->createToken('refresh_token', ['refresh'], now()->addDays(30))->plainTextToken;

        return response()->json([
            'token' => $token,
            'refresh_token' => $refreshToken,
        ]);
    }

    public function sendVerification(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $user = User::where('email', $data['email'])->first();
        if (!$user) {
            return response()->json(['message' => 'Email tidak ditemukan.'], 404);
        }
        $otp = $this->otp->generate($user->email, 'verify');
        $this->otp->sendVerification($user->email, $user->name, $otp);
        return response()->json(['message' => 'Kode OTP dikirim ke email.']);
    }

    public function verifyEmail(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        if (!$this->otp->verify($data['email'], $data['otp'], 'verify')) {
            return response()->json(['message' => 'Kode OTP tidak valid atau sudah kedaluwarsa.'], 422);
        }

        $user = User::where('email', $data['email'])->firstOrFail();
        $user->update(['email_verified_at' => now()]);

        $token = $user->createToken('access_token', ['*'], now()->addMinutes(15))->plainTextToken;
        $refreshToken = $user->createToken('refresh_token', ['refresh'], now()->addDays(30))->plainTextToken;

        return response()->json([
            'message' => 'Email berhasil diverifikasi.',
            'token' => $token,
            'refresh_token' => $refreshToken,
            'user' => $this->userResource($user),
        ]);
    }

    public function forgotPassword(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $user = User::where('email', $data['email'])->first();
        if (!$user) {
            // Don't reveal if email exists
            return response()->json(['message' => 'Jika email terdaftar, OTP akan dikirim.']);
        }
        $otp = $this->otp->generate($user->email, 'reset_password');
        $this->otp->sendPasswordReset($user->email, $user->name, $otp);
        return response()->json(['message' => 'Kode OTP reset sandi dikirim ke email.']);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
            'password' => ['required', Password::min(8)],
        ]);

        if (!$this->otp->verify($data['email'], $data['otp'], 'reset_password')) {
            return response()->json(['message' => 'Kode OTP tidak valid atau kedaluwarsa.'], 422);
        }

        $user = User::where('email', $data['email'])->firstOrFail();
        $user->update(['password' => Hash::make($data['password'])]);

        // Revoke all tokens
        $user->tokens()->delete();

        AuditLog::record('reset_password', $user);

        return response()->json(['message' => 'Sandi berhasil diubah. Silakan login kembali.']);
    }

    private function verifyGoogleToken(string $idToken): ?array
    {
        try {
            $response = \Illuminate\Support\Facades\Http::get(
                'https://oauth2.googleapis.com/tokeninfo',
                ['id_token' => $idToken]
            );
            if ($response->failed()) {
                return null;
            }
            $payload = $response->json();
            // Optionally verify aud matches your client ID
            return $payload;
        } catch (\Throwable $e) {
            return null;
        }
    }

    private function userResource(User $user): array
    {
        $user->load('tenant');
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'email_verified_at' => $user->email_verified_at,
            'tenant_id' => $user->tenant_id,
            'tenant' => $user->tenant ? [
                'id' => $user->tenant->id,
                'shop_name' => $user->tenant->shop_name,
                'subscription_status' => $user->tenant->subscription_status,
                'trial_until' => $user->tenant->trial_until,
                'subscription_expires_at' => $user->tenant->subscription_expires_at,
                'has_full_access' => $user->tenant->hasFullAccess(),
            ] : null,
        ];
    }
}
