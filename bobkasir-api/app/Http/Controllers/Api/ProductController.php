<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    use ApiResponse;

    // GET /api/categories
    public function indexCategories(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $categories = Category::where('business_id', $biz)->orderBy('sort_order')->get();
        return $this->success($categories);
    }

    // POST /api/categories
    public function storeCategory(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), ['name' => 'required|string|max:100']);
        if ($v->fails()) return $this->validationError($v->errors());
        $cat = Category::create([
            'business_id' => $request->get('_business_id'),
            'name' => $request->name,
            'description' => $request->description,
            'sort_order' => $request->sort_order ?? 0,
            'is_active' => $request->is_active ?? true,
        ]);
        return $this->success($cat, 'Kategori berhasil dibuat', 201);
    }

    // PUT /api/categories/{id}
    public function updateCategory(Request $request, string $id): JsonResponse
    {
        $v = Validator::make($request->all(), ['name' => 'required|string|max:100']);
        if ($v->fails()) return $this->validationError($v->errors());
        $cat = Category::where('business_id', $request->get('_business_id'))->find($id);
        if (!$cat) return $this->notFound('Kategori tidak ditemukan');
        $cat->update($request->only('name','description','sort_order','is_active'));
        return $this->success($cat, 'Kategori diperbarui');
    }

    // DELETE /api/categories/{id}
    public function destroyCategory(Request $request, string $id): JsonResponse
    {
        $cat = Category::where('business_id', $request->get('_business_id'))->find($id);
        if (!$cat) return $this->notFound('Kategori tidak ditemukan');
        $cat->update(['is_active' => false]);
        return $this->success(null, 'Kategori dinonaktifkan');
    }

    // GET /api/products
    public function index(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $q = Product::where('business_id', $biz)
            ->where(function ($query) {
                $query->whereHas('category', function ($c) {
                    $c->where('is_active', true);
                })->orWhereNull('category_id');
            })
            ->with(['category','primaryImage','stock']);
        if ($request->filled('category_id')) $q->where('category_id', $request->category_id);
        if ($request->filled('is_active')) $q->where('is_active', $request->boolean('is_active'));
        if ($request->filled('search')) $q->where('name','like','%'.$request->search.'%');
        return $this->success($q->paginate($request->get('per_page',50)));
    }

    // POST /api/products
    public function store(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'price' => 'required|integer|min:0',
            'category_id' => 'nullable|string',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());
        $product = Product::create([
            'business_id' => $request->get('_business_id'),
            'category_id' => $request->category_id,
            'name' => $request->name,
            'price' => $request->price,
            'cost' => $request->cost,
            'sku' => $request->sku,
            'barcode' => $request->barcode,
            'description' => $request->description,
            'is_active' => $request->is_active ?? true,
            'track_stock' => $request->track_stock ?? false,
        ]);
        return $this->success($product->load('category'), 'Produk berhasil dibuat', 201);
    }

    // GET /api/products/{id}
    public function show(Request $request, string $id): JsonResponse
    {
        $product = Product::where('business_id', $request->get('_business_id'))->with(['category','images','stock'])->find($id);
        if (!$product) return $this->notFound('Produk tidak ditemukan');
        return $this->success($product);
    }

    // PUT /api/products/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'price' => 'required|integer|min:0',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());
        $product = Product::where('business_id', $request->get('_business_id'))->find($id);
        if (!$product) return $this->notFound();
        $product->update($request->only('name','price','cost','category_id','sku','barcode','description','is_active','track_stock'));
        return $this->success($product->load('category'), 'Produk diperbarui');
    }

    // PATCH /api/products/{id}/status
    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $product = Product::where('business_id', $request->get('_business_id'))->find($id);
        if (!$product) return $this->notFound();
        $product->update(['is_active' => $request->boolean('is_active')]);
        return $this->success(null, 'Status produk diperbarui');
    }

    // DELETE /api/products/{id}
    public function destroy(Request $request, string $id): JsonResponse
    {
        $product = Product::where('business_id', $request->get('_business_id'))->find($id);
        if (!$product) return $this->notFound();
        // Soft delete — never permanently delete products with transactions
        $product->update(['is_active' => false]);
        $product->delete();
        return $this->success(null, 'Produk dinonaktifkan');
    }
}
