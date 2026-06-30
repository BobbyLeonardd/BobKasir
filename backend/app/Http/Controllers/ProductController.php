<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::where('tenant_id', $request->user()->tenant_id)
            ->with('category:id,name');

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }
        if ($request->has('is_active')) {
            $query->where('is_active', (bool) $request->is_active);
        }

        return response()->json(['data' => $query->orderBy('name')->get()]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'category_id' => 'nullable|integer',
            'name' => 'required|string|max:200',
            'description' => 'nullable|string',
            'price' => 'required|string',
            'image' => 'nullable|image|max:2048',
            'stock' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        $tenantId = $request->user()->tenant_id;
        $imageUrl = null;

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store("products/{$tenantId}", 'public');
            $imageUrl = Storage::url($path);
        }

        $price = Product::normalizePrice($data['price']);
        if ($price < 0) {
            return response()->json(['message' => 'Harga tidak boleh negatif.'], 422);
        }

        $product = Product::create([
            'tenant_id' => $tenantId,
            'category_id' => $data['category_id'] ?? null,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'price' => $price,
            'image_url' => $imageUrl,
            'stock' => $data['stock'] ?? null,
            'is_active' => $data['is_active'] ?? true,
        ]);

        AuditLog::record('create_product', $product, [], ['name' => $product->name, 'price' => $product->price]);

        return response()->json(['message' => 'Produk dibuat.', 'data' => $product->load('category:id,name')], 201);
    }

    public function show(Request $request, int $id)
    {
        $product = Product::where('tenant_id', $request->user()->tenant_id)
            ->with('category:id,name')
            ->findOrFail($id);
        return response()->json(['data' => $product]);
    }

    public function update(Request $request, int $id)
    {
        $product = Product::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $old = ['name' => $product->name, 'price' => $product->price];

        $data = $request->validate([
            'category_id' => 'nullable|integer',
            'name' => 'sometimes|string|max:200',
            'description' => 'nullable|string',
            'price' => 'sometimes|string',
            'image' => 'nullable|image|max:2048',
            'stock' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        if (isset($data['price'])) {
            $data['price'] = Product::normalizePrice($data['price']);
            if ($data['price'] < 0) {
                return response()->json(['message' => 'Harga tidak boleh negatif.'], 422);
            }
        }

        if ($request->hasFile('image')) {
            // Delete old image
            if ($product->image_url) {
                $oldPath = str_replace('/storage/', '', $product->image_url);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('image')->store("products/{$product->tenant_id}", 'public');
            $data['image_url'] = Storage::url($path);
        }

        $product->update($data);
        AuditLog::record('update_product', $product, $old, ['name' => $product->name, 'price' => $product->price]);

        return response()->json(['message' => 'Produk diperbarui.', 'data' => $product->load('category:id,name')]);
    }

    public function destroy(Request $request, int $id)
    {
        $product = Product::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        AuditLog::record('delete_product', $product, $product->toArray());

        if ($product->image_url) {
            $path = str_replace('/storage/', '', $product->image_url);
            Storage::disk('public')->delete($path);
        }

        $product->delete();
        return response()->json(['message' => 'Produk dihapus.']);
    }
}
