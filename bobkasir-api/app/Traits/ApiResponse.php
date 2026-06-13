<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function success(mixed $data = null, string $message = 'Berhasil', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    protected function error(string $message = 'Terjadi kesalahan', int $code = 400, mixed $errors = null): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors'  => $errors,
        ], $code);
    }

    protected function unauthorized(string $message = 'Tidak memiliki akses'): JsonResponse
    {
        return $this->error($message, 403);
    }

    protected function notFound(string $message = 'Data tidak ditemukan'): JsonResponse
    {
        return $this->error($message, 404);
    }

    protected function validationError(mixed $errors): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Validasi gagal',
            'errors'  => $errors,
        ], 422);
    }
}
