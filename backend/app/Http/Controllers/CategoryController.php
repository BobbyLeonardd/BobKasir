<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $categories = Category::where('tenant_id', $request->user()->tenant_id)
            ->orderBy('order_index')
            ->get();
        return response()->json(['data' => $categories]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'order_index' => 'nullable|integer|min:0',
        ]);

        $category = Category::create([
            'tenant_id' => $request->user()->tenant_id,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'order_index' => $data['order_index'] ?? 0,
        ]);

        AuditLog::record('create_category', $category, [], $category->toArray());

        return response()->json(['message' => 'Kategori dibuat.', 'data' => $category], 201);
    }

    public function update(Request $request, int $id)
    {
        $category = Category::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        $old = $category->toArray();

        $data = $request->validate([
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'order_index' => 'nullable|integer|min:0',
        ]);

        $category->update($data);
        AuditLog::record('update_category', $category, $old, $data);

        return response()->json(['message' => 'Kategori diperbarui.', 'data' => $category]);
    }

    public function destroy(Request $request, int $id)
    {
        $category = Category::where('tenant_id', $request->user()->tenant_id)->findOrFail($id);
        AuditLog::record('delete_category', $category, $category->toArray());
        $category->delete();
        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
