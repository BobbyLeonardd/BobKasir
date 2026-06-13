<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Discount;
use App\Models\ServiceCharge;
use App\Models\Tax;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Handles Discounts, Taxes, and Service Charges (PRD §15, §33.1)
 */
class DiscountTaxController extends Controller
{
    use ApiResponse;

    // ──────────────────────────────────────────
    // DISCOUNTS
    // ──────────────────────────────────────────

    public function indexDiscounts(Request $request): JsonResponse
    {
        $discounts = Discount::where('business_id', $request->get('_business_id'))->get();
        return $this->success($discounts);
    }

    public function storeDiscount(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name'  => 'required|string|max:100',
            'type'  => 'required|in:percent,nominal',
            'value' => 'required|numeric|min:0',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $discount = Discount::create([
            'business_id'   => $request->get('_business_id'),
            'name'          => $request->name,
            'type'          => $request->type,
            'value'         => $request->value,
            'max_discount'  => $request->max_discount,
            'min_transaction'=> $request->min_transaction,
            'is_active'     => $request->is_active ?? true,
        ]);
        return $this->success($discount, 'Diskon berhasil dibuat', 201);
    }

    public function updateDiscount(Request $request, string $id): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name'  => 'required|string|max:100',
            'type'  => 'required|in:percent,nominal',
            'value' => 'required|numeric|min:0',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $discount = Discount::where('business_id', $request->get('_business_id'))->find($id);
        if (!$discount) return $this->notFound();
        $discount->update($request->only('name', 'type', 'value', 'max_discount', 'min_transaction', 'is_active'));
        return $this->success($discount, 'Diskon diperbarui');
    }

    public function destroyDiscount(Request $request, string $id): JsonResponse
    {
        $discount = Discount::where('business_id', $request->get('_business_id'))->find($id);
        if (!$discount) return $this->notFound();
        $discount->delete();
        return $this->success(null, 'Diskon dihapus');
    }

    // ──────────────────────────────────────────
    // TAXES
    // ──────────────────────────────────────────

    public function indexTaxes(Request $request): JsonResponse
    {
        $taxes = Tax::where('business_id', $request->get('_business_id'))->get();
        return $this->success($taxes);
    }

    public function storeTax(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'rate' => 'required|numeric|min:0|max:100',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $tax = Tax::create([
            'business_id' => $request->get('_business_id'),
            'name'        => $request->name,
            'rate'        => $request->rate,
            'is_active'   => $request->is_active ?? false,
        ]);
        return $this->success($tax, 'Pajak berhasil ditambahkan', 201);
    }

    public function updateTax(Request $request, string $id): JsonResponse
    {
        $tax = Tax::where('business_id', $request->get('_business_id'))->find($id);
        if (!$tax) return $this->notFound();
        $tax->update($request->only('name', 'rate', 'is_active'));
        return $this->success($tax, 'Pajak diperbarui');
    }

    public function destroyTax(Request $request, string $id): JsonResponse
    {
        $tax = Tax::where('business_id', $request->get('_business_id'))->find($id);
        if (!$tax) return $this->notFound();
        $tax->delete();
        return $this->success(null, 'Pajak dihapus');
    }

    // ──────────────────────────────────────────
    // SERVICE CHARGES
    // ──────────────────────────────────────────

    public function indexServiceCharges(Request $request): JsonResponse
    {
        $charges = ServiceCharge::where('business_id', $request->get('_business_id'))->get();
        return $this->success($charges);
    }

    public function storeServiceCharge(Request $request): JsonResponse
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string|max:100',
            'rate' => 'required|numeric|min:0|max:100',
        ]);
        if ($v->fails()) return $this->validationError($v->errors());

        $charge = ServiceCharge::create([
            'business_id' => $request->get('_business_id'),
            'name'        => $request->name,
            'rate'        => $request->rate,
            'is_active'   => $request->is_active ?? false,
        ]);
        return $this->success($charge, 'Service charge ditambahkan', 201);
    }

    public function updateServiceCharge(Request $request, string $id): JsonResponse
    {
        $charge = ServiceCharge::where('business_id', $request->get('_business_id'))->find($id);
        if (!$charge) return $this->notFound();
        $charge->update($request->only('name', 'rate', 'is_active'));
        return $this->success($charge, 'Service charge diperbarui');
    }

    public function destroyServiceCharge(Request $request, string $id): JsonResponse
    {
        $charge = ServiceCharge::where('business_id', $request->get('_business_id'))->find($id);
        if (!$charge) return $this->notFound();
        $charge->delete();
        return $this->success(null, 'Service charge dihapus');
    }

    // ──────────────────────────────────────────
    // ACTIVE CONFIG — all in one (for cashier screen)
    // ──────────────────────────────────────────

    public function activeConfig(Request $request): JsonResponse
    {
        $biz = $request->get('_business_id');
        return $this->success([
            'discounts'       => Discount::where('business_id', $biz)->where('is_active', true)->get(),
            'taxes'           => Tax::where('business_id', $biz)->where('is_active', true)->get(),
            'service_charges' => ServiceCharge::where('business_id', $biz)->where('is_active', true)->get(),
        ]);
    }
}
