<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Kode OTP BobKasir</title>
<style>
  body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
  .container { max-width: 480px; margin: 40px auto; background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
  .header { background: #C8892A; padding: 24px; text-align: center; }
  .header h1 { color: #fff; margin: 0; font-size: 22px; }
  .body { padding: 32px 24px; }
  .otp { font-size: 36px; font-weight: bold; letter-spacing: 12px; color: #C8892A; text-align: center; margin: 24px 0; }
  .footer { background: #f7f5f2; padding: 16px 24px; text-align: center; color: #9e9489; font-size: 12px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>BobKasir</h1>
  </div>
  <div class="body">
    <p>Halo, <strong>{{ $name }}</strong>.</p>
    <p>Berikut kode OTP untuk <strong>{{ $type }}</strong> Anda:</p>
    <div class="otp">{{ $otp }}</div>
    <p>Kode berlaku selama <strong>10 menit</strong>. Jangan bagikan kode ini kepada siapa pun.</p>
    <p>Jika Anda tidak meminta kode ini, abaikan email ini.</p>
  </div>
  <div class="footer">
    &copy; {{ date('Y') }} BobKasir by StarCyberCompany
  </div>
</div>
</body>
</html>
