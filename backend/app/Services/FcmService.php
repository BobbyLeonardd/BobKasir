<?php

namespace App\Services;

use App\Models\DeviceToken;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $projectId;
    private ?string $serviceAccountPath;

    public function __construct()
    {
        $this->projectId = config('services.fcm.project_id', '');
        $this->serviceAccountPath = config('services.fcm.service_account_path');
    }

    /**
     * Send notification to all device tokens of given user IDs.
     */
    public function sendToUsers(array $userIds, string $title, string $body, array $data = []): void
    {
        $tokens = DeviceToken::whereIn('user_id', $userIds)->pluck('fcm_token')->all();
        foreach ($tokens as $token) {
            $this->sendToToken($token, $title, $body, $data);
        }
    }

    /**
     * Send to tenant's owner and admin users.
     */
    public function sendToTenantAdmins(int $tenantId, string $title, string $body, array $data = []): void
    {
        $userIds = \App\Models\User::where('tenant_id', $tenantId)
            ->whereIn('role', ['owner', 'admin'])
            ->pluck('id')
            ->all();
        $this->sendToUsers($userIds, $title, $body, $data);
    }

    public function sendToToken(string $token, string $title, string $body, array $data = []): void
    {
        if (empty($this->projectId)) {
            Log::info("FCM: project_id not configured, skipping push notification.");
            return;
        }

        try {
            $accessToken = $this->getAccessToken();
            if (!$accessToken) {
                return;
            }

            Http::withToken($accessToken)
                ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => ['title' => $title, 'body' => $body],
                        'data' => array_map('strval', $data),
                    ],
                ]);
        } catch (\Throwable $e) {
            Log::error("FCM send failed: " . $e->getMessage());
        }
    }

    private function getAccessToken(): ?string
    {
        if (!$this->serviceAccountPath || !file_exists($this->serviceAccountPath)) {
            return null;
        }
        // Use Google OAuth2 service account JWT to get access token
        $credentials = json_decode(file_get_contents($this->serviceAccountPath), true);
        $now = time();
        $payload = [
            'iss' => $credentials['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ];
        $jwt = $this->createJwt($payload, $credentials['private_key']);
        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);
        return $response->json('access_token');
    }

    private function createJwt(array $payload, string $privateKey): string
    {
        $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = base64_encode(json_encode($payload));
        $data = "$header.$payload";
        openssl_sign($data, $signature, $privateKey, 'SHA256');
        return "$data." . base64_encode($signature);
    }
}
