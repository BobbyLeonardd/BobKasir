<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Stock;
use App\Models\StockMovement;
use App\Services\NotificationService;
use App\Services\StockService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class StockController extends Controller
{
    use ApiResponse;

    // GET /api/stocks — list all products with their stock levels
    public function index(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');

        $stocks = Stock::whereHas('product', fn($q) => $q->where('business_id', $biz))
            ->with(['product:id,name,category_id,is_active', 'product.category:id,name'])
            ->get()
            ->map(fn($s) => [
                'id'            => $s->id,
                'product_id'    => $s->product_id,
                'product_name'  => $s->product?->name,
                'category_name' => $s->product?->category?->name,
                'quantity'      => $s->quantity,
                'minimum_stock' => $s->minimum_stock,
                'is_low'        => $s->quantity <= $s->minimum_stock && $s->minimum_stock > 0,
                'outlet_id'     => $s->outlet_id,
            ]);

        return $this->success($stocks);
    }

    // GET /api/stocks/{productId} — stock for specific product
    public function show(Request $request, string $productId): JsonResponse
    {
        $biz = $request->get('_business_id');
        $stock = Stock::whereHas('product', fn($q) => $q->where('business_id', $biz))
            ->where('product_id', $productId)
            ->with(['movements' => fn($q) => $q->orderByDesc('created_at')->limit(20)])
            ->first();

        if (!$stock) {
            return $this->success([
                'product_id' => $productId,
                'quantity'   => null,
                'movements'  => [],
            ]);
        }

        return $this->success($stock);
    }

    // POST /api/stocks — set initial stock for a product
    public function store(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'product_id'    => 'required|string',
            'quantity'      => 'required|integer|min:0',
            'minimum_stock' => 'nullable|integer|min:0',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz = $request->get('_business_id');
        $user = $request->user();

        // Ensure the product belongs to this business (prevent cross-tenant write).
        if (!Product::where('business_id', $biz)->where('id', $request->product_id)->exists()) {
            return $this->notFound('Produk tidak ditemukan');
        }

        $result = StockService::adjust(
            $request->product_id,
            'adjustment',
            $request->quantity,
            $user->id,
            'Stok awal',
            $request->get('_outlet_id')
        );

        // Update minimum stock if provided
        if ($request->filled('minimum_stock')) {
            Stock::where('id', $result['stock_id'])
                ->update(['minimum_stock' => $request->minimum_stock]);
        }

        return $this->success($result, 'Stok berhasil diset', 201);
    }

    // PATCH /api/stocks/{productId}/adjust — add/subtract/set stock
    public function adjust(Request $request, string $productId): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'type'     => 'required|in:in,out,adjustment',
            'quantity' => 'required|integer|min:0',
            'note'     => 'nullable|string',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz  = $request->get('_business_id');
        $user = $request->user();

        // Ensure the product belongs to this business (prevent cross-tenant write).
        if (!Product::where('business_id', $biz)->where('id', $productId)->exists()) {
            return $this->notFound('Produk tidak ditemukan');
        }

        $result = StockService::adjust(
            $productId,
            $request->type,
            $request->quantity,
            $user->id,
            $request->note,
            $request->get('_outlet_id')
        );

        // Check for low stock after adjustment
        $stock = Stock::find($result['stock_id']);
        if ($stock && $stock->quantity <= $stock->minimum_stock && $stock->minimum_stock > 0) {
            NotificationService::lowStock(
                $biz,
                $stock->product?->name ?? 'Produk',
                $stock->quantity
            );
        }

        return $this->success($result, 'Stok diperbarui');
    }

    // GET /api/stocks/{productId}/movements — stock movement history
    public function movements(Request $request, string $productId): JsonResponse
    {
        $stock = Stock::whereHas('product', fn($q) => $q->where('business_id', $request->get('_business_id')))
            ->where('product_id', $productId)
            ->first();

        if (!$stock) return $this->notFound('Stok tidak ditemukan');

        $movements = StockMovement::where('stock_id', $stock->id)
            ->with('user:id,name')
            ->orderByDesc('created_at')
            ->paginate(20);

        return $this->success($movements);
    }
}
