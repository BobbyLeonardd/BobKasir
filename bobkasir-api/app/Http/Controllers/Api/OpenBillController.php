<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\OpenBill;
use App\Models\OpenBillItem;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OpenBillController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $bills = OpenBill::where('business_id', $request->get('_business_id'))
            ->whereIn('status',['open','updated'])
            ->with('items')
            ->orderByDesc('updated_at')
            ->get();
        return $this->success($bills);
    }

    public function store(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        $count = OpenBill::where('business_id', $biz)->whereDate('created_at', today())->count();
        $billNumber = 'OB-' . now()->format('Ymd') . '-' . str_pad($count + 1, 3, '0', STR_PAD_LEFT);
        $bill = OpenBill::create([
            'business_id' => $biz,
            'outlet_id' => $request->get('_outlet_id'),
            'user_id' => $request->user()->id,
            'bill_number' => $billNumber,
            'customer_name' => $request->customer_name,
            'table_number' => $request->table_number,
            'note' => $request->note,
        ]);
        return $this->success($bill->load('items'), 'Open bill dibuat', 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $bill = OpenBill::where('business_id', $request->get('_business_id'))->with('items')->find($id);
        if (!$bill) return $this->notFound();
        return $this->success($bill);
    }

    public function addItem(Request $request, string $id): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'product_id'   => 'nullable|string',
            'product_name' => 'required|string',
            'price'        => 'required|integer|min:0',
            'qty'          => 'required|integer|min:1',
            'discount'     => 'nullable|integer|min:0',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $biz = $request->get('_business_id');
        $bill = OpenBill::where('business_id', $biz)->find($id);
        if (!$bill) return $this->notFound();

        // Money is server-authoritative: take price/name from the catalog when a
        // product is referenced; never trust the client price (H6).
        $price = max(0, (int) $request->price);
        $name  = $request->product_name;
        $productId = $request->product_id;
        if ($productId) {
            $product = Product::withTrashed()->where('business_id', $biz)->find($productId);
            if (!$product) return $this->notFound('Produk tidak ditemukan');
            $price = (int) $product->price;
            $name  = $product->name;
        }

        $qty      = max(1, (int) $request->qty);
        $discount = min(max(0, (int) ($request->discount ?? 0)), $price * $qty);
        $subtotal = max(0, $price * $qty - $discount);

        $item = OpenBillItem::create([
            'open_bill_id' => $id,
            'product_id'   => $productId,
            'product_name' => $name,
            'price'        => $price,
            'qty'          => $qty,
            'discount'     => $discount,
            'note'         => $request->note,
            'subtotal'     => $subtotal,
        ]);
        $bill->update(['status' => 'updated']);
        return $this->success($item, 'Item ditambahkan', 201);
    }

    public function removeItem(Request $request, string $id, string $itemId): JsonResponse
    {
        $bill = OpenBill::where('business_id', $request->get('_business_id'))->find($id);
        if (!$bill) return $this->notFound();
        OpenBillItem::where('open_bill_id', $id)->find($itemId)?->delete();
        $bill->update(['status' => 'updated']);
        return $this->success(null, 'Item dihapus');
    }

    public function cancel(Request $request, string $id): JsonResponse
    {
        $bill = OpenBill::where('business_id', $request->get('_business_id'))->find($id);
        if (!$bill) return $this->notFound();
        $bill->update(['status' => 'cancelled']);
        return $this->success(null, 'Open bill dibatalkan');
    }
}
