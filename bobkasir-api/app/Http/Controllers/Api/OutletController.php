<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Outlet;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OutletController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $outlets = Outlet::where('business_id', $request->get('_business_id'))->get();
        return $this->success($outlets);
    }

    public function store(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['name' => 'required|string|max:100']);
        if ($v->fails()) return $this->validationError($v->errors());
        $outlet = Outlet::create(['business_id' => $request->get('_business_id'), 'name' => $request->name, 'address' => $request->address, 'phone' => $request->phone]);
        return $this->success($outlet, 'Outlet berhasil dibuat', 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $outlet = Outlet::where('business_id', $request->get('_business_id'))->find($id);
        if (!$outlet) return $this->notFound();
        $outlet->update($request->only('name','address','phone','is_active'));
        return $this->success($outlet, 'Outlet diperbarui');
    }
}
