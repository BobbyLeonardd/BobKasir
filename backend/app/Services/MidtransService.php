<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MidtransService
{
    private string $serverKey;
    private bool $isProduction;
    private string $snapUrl;
    private string $apiUrl;

    public function __construct()
    {
        $this->serverKey = config('services.midtrans.server_key', '');
        $this->isProduction = config('services.midtrans.is_production', false);
        $this->snapUrl = $this->isProduction
            ? 'https://app.midtrans.com/snap/v1/transactions'
            : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
        $this->apiUrl = $this->isProduction
            ? 'https://api.midtrans.com/v2'
            : 'https://api.sandbox.midtrans.com/v2';
    }

    public function createSnapTransaction(string $orderId, int $amount, array $customerDetails): array
    {
        $response = Http::withBasicAuth($this->serverKey, '')
            ->post($this->snapUrl, [
                'transaction_details' => [
                    'order_id' => $orderId,
                    'gross_amount' => $amount,
                ],
                'customer_details' => $customerDetails,
                'expiry' => ['duration' => 24, 'unit' => 'hours'],
            ]);

        if ($response->failed()) {
            Log::error('Midtrans createSnap failed: ' . $response->body());
            throw new \RuntimeException('Gagal membuat transaksi Midtrans.');
        }

        return $response->json();
    }

    public function verifySignature(string $orderId, string $statusCode, string $grossAmount, string $signatureKey): bool
    {
        $expected = hash('sha512', $orderId . $statusCode . $grossAmount . $this->serverKey);
        return hash_equals($expected, $signatureKey);
    }

    public function getTransactionStatus(string $orderId): array
    {
        $response = Http::withBasicAuth($this->serverKey, '')
            ->get("{$this->apiUrl}/{$orderId}/status");
        return $response->json();
    }
}
