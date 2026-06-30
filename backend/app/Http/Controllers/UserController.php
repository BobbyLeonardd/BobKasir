<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rules\Password;

class UserController extends Controller
{
    public function __construct(private OtpService $otp) {}

    /** GET /users — list tenant users (owner only) */
    public function index(Request $request)
    {
        $users = User::where('tenant_id', $request->user()->tenant_id)
            ->where('id', '!=', $request->user()->id)
            ->get(['id', 'name', 'email', 'role', 'status', 'email_verified_at', 'created_at']);

        return response()->json(['data' => $users]);
    }

    /** POST /users — create admin or cashier (owner only) */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => ['required', Password::min(8)],
            'role' => 'required|in:admin,cashier',
        ]);

        $owner = $request->user();

        $user = User::create([
            'tenant_id' => $owner->tenant_id,
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => $data['role'],
            'status' => 'active',
            'created_by' => $owner->id,
        ]);

        // Send verification email
        $otp = $this->otp->generate($user->email, 'verify');
        $this->otp->sendVerification($user->email, $user->name, $otp);

        AuditLog::record('create_user', $user, [], ['role' => $user->role, 'email' => $user->email]);

        return response()->json(['message' => 'Akun berhasil dibuat.', 'data' => $user], 201);
    }

    /** GET /users/{id} */
    public function show(Request $request, int $id)
    {
        $user = User::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        return response()->json(['data' => $user]);
    }

    /** PUT /users/{id} — update role/status/name (owner only) */
    public function update(Request $request, int $id)
    {
        $target = User::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $old = $target->toArray();

        $data = $request->validate([
            'name' => 'sometimes|string|max:100',
            'role' => 'sometimes|in:admin,cashier',
            'status' => 'sometimes|in:active,inactive',
        ]);

        $target->update($data);
        AuditLog::record('update_user', $target, $old, $data);

        return response()->json(['message' => 'Berhasil diperbarui.', 'data' => $target]);
    }

    /** DELETE /users/{id} */
    public function destroy(Request $request, int $id)
    {
        $target = User::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        AuditLog::record('delete_user', $target, $target->toArray());
        $target->tokens()->delete();
        $target->delete();
        return response()->json(['message' => 'Akun dihapus.']);
    }

    /** GET /users/profile */
    public function profile(Request $request)
    {
        return response()->json(['data' => $request->user()->load('tenant')]);
    }

    /** PUT /users/profile */
    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => 'sometimes|string|max:100',
        ]);

        $old = $user->only(['name']);
        $user->update($data);
        AuditLog::record('update_profile', $user, $old, $data);

        return response()->json(['message' => 'Profil diperbarui.', 'data' => $user]);
    }

    /** PUT /users/profile/email — request email change */
    public function requestEmailChange(Request $request)
    {
        $data = $request->validate(['email' => 'required|email|unique:users,email']);
        $user = $request->user();

        $otp = $this->otp->generate($data['email'], 'change_email');
        Mail::send('emails.otp', [
            'otp' => $otp, 'name' => $user->name, 'type' => 'ganti email',
        ], fn($m) => $m->to($data['email'])->subject('Verifikasi Email Baru BobKasir'));

        // Store pending email temporarily in cache
        cache()->put("pending_email_{$user->id}", $data['email'], now()->addMinutes(10));

        return response()->json(['message' => 'Kode OTP dikirim ke email baru.']);
    }

    /** POST /users/profile/email/confirm */
    public function confirmEmailChange(Request $request)
    {
        $data = $request->validate(['otp' => 'required|string|size:6']);
        $user = $request->user();
        $pendingEmail = cache()->get("pending_email_{$user->id}");

        if (!$pendingEmail) {
            return response()->json(['message' => 'Tidak ada permintaan ganti email aktif.'], 422);
        }

        if (!$this->otp->verify($pendingEmail, $data['otp'], 'change_email')) {
            return response()->json(['message' => 'Kode OTP tidak valid.'], 422);
        }

        $old = ['email' => $user->email];
        $user->update(['email' => $pendingEmail, 'email_verified_at' => now()]);
        cache()->forget("pending_email_{$user->id}");

        AuditLog::record('change_email', $user, $old, ['email' => $pendingEmail]);

        return response()->json(['message' => 'Email berhasil diubah.']);
    }

    /** POST /users/profile/password */
    public function changePassword(Request $request)
    {
        $data = $request->validate([
            'current_password' => 'required|string',
            'password' => ['required', Password::min(8)],
        ]);

        $user = $request->user();
        if (!Hash::check($data['current_password'], $user->password ?? '')) {
            return response()->json(['message' => 'Sandi saat ini salah.'], 422);
        }

        $user->update(['password' => Hash::make($data['password'])]);
        // Revoke all other tokens
        $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        AuditLog::record('change_password', $user);

        return response()->json(['message' => 'Sandi berhasil diubah.']);
    }

    /** DELETE /users/profile — delete own account */
    public function deleteProfile(Request $request)
    {
        $data = $request->validate([
            'confirm_shop_name' => 'required_if:role,owner|string',
        ]);

        $user = $request->user();
        $tenant = $user->tenant;

        if ($user->isOwner()) {
            if ($data['confirm_shop_name'] !== $tenant->shop_name) {
                return response()->json(['message' => 'Nama kedai tidak cocok.'], 422);
            }
            // Soft delete tenant (30 day window before hard delete)
            $tenant->delete();
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Akun berhasil dihapus.']);
    }
}
