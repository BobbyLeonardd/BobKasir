<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Business;
use App\Models\User;
use App\Models\UserBusinessRole;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    use ApiResponse;

    // GET /api/users
    public function index(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $members = UserBusinessRole::where('business_id', $biz)
            ->with('user')
            ->where('role', '!=', 'owner')
            ->get()
            ->map(fn($m) => [
                'id' => $m->user->id,
                'name' => $m->user->name,
                'email' => $m->user->email,
                'role' => $m->role,
                'status' => $m->status,
                'avatar' => $m->user->avatar,
            ]);
        return $this->success($members);
    }

    // POST /api/users/manager
    public function createManager(Request $request): JsonResponse
    {
        return $this->createMember($request, 'manager');
    }

    // POST /api/users/employee
    public function createEmployee(Request $request): JsonResponse
    {
        return $this->createMember($request, 'karyawan');
    }

    private function createMember(Request $request, string $role): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz = $request->get('_business_id');
        // Check if user already exists
        $user = User::firstOrCreate(
            ['email' => $request->email],
            ['name' => $request->name, 'password' => Hash::make($request->password), 'status' => 'active']
        );

        // Check not already in this business
        $existing = UserBusinessRole::where('user_id', $user->id)->where('business_id', $biz)->first();
        if ($existing) return $this->error('User sudah terdaftar di bisnis ini');

        UserBusinessRole::create([
            'user_id' => $user->id,
            'business_id' => $biz,
            'role' => $role,
            'status' => 'active',
        ]);

        AuditLog::create([
            'business_id' => $biz, 'user_id' => $request->user()->id,
            'role' => $request->get('_user_role'), 'action' => 'ubah_role',
            'table_name' => 'user_business_roles', 'record_id' => $user->id,
            'new_data' => ['role' => $role, 'email' => $user->email],
            'ip_address' => $request->ip(),
        ]);

        return $this->success(['id' => $user->id, 'name' => $user->name, 'email' => $user->email, 'role' => $role], ucfirst($role) . ' berhasil ditambahkan', 201);
    }

    // PUT /api/users/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'role' => 'nullable|in:manager,karyawan',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz = $request->get('_business_id');
        $role = UserBusinessRole::where('user_id', $id)->where('business_id', $biz)->first();
        if (!$role) return $this->notFound('User tidak ditemukan di bisnis ini');
        // The owner account cannot be edited/demoted through this endpoint.
        if ($role->role === 'owner') return $this->error('Tidak dapat mengubah akun owner', 403);

        User::find($id)?->update(['name' => $request->name]);
        if ($request->filled('role')) $role->update(['role' => $request->role]);

        return $this->success(null, 'Data user diperbarui');
    }

    // PATCH /api/users/{id}/activate
    public function activate(Request $request, string $id): JsonResponse
    {
        $role = UserBusinessRole::where('user_id', $id)->where('business_id', $request->get('_business_id'))->first();
        if (!$role) return $this->notFound();
        $role->update(['status' => 'active']);
        return $this->success(null, 'Akun diaktifkan');
    }

    // PATCH /api/users/{id}/deactivate
    public function deactivate(Request $request, string $id): JsonResponse
    {
        $role = UserBusinessRole::where('user_id', $id)->where('business_id', $request->get('_business_id'))->first();
        if (!$role) return $this->notFound();
        $role->update(['status' => 'inactive']);
        return $this->success(null, 'Akun dinonaktifkan');
    }

    // DELETE /api/users/{id}/access
    public function removeAccess(Request $request, string $id): JsonResponse
    {
        $biz = $request->get('_business_id');
        $role = UserBusinessRole::where('user_id', $id)->where('business_id', $biz)->first();
        if (!$role) return $this->notFound();
        $role->delete();
        return $this->success(null, 'Akses user dihapus dari bisnis');
    }
}
