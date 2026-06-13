# 🚀 Panduan Menjalankan BobKasir di Lokal (Emulator Android)

> Dibuat oleh **StarCyberCompany**  
> Stack: Flutter · Laravel 12 · MySQL · Midtrans Sandbox · Gmail SMTP

---

## 📋 Prasyarat

Pastikan software berikut sudah terinstall:

| Software | Versi Minimum | Cek |
|---|---|---|
| PHP | 8.2+ | `php --version` |
| Composer | 2.x | `composer --version` |
| MySQL | 8.0+ | via Laragon/XAMPP |
| Flutter SDK | 3.x | `flutter --version` |
| Android Studio | Hedgehog+ | Android Emulator |
| Java (JDK) | 17+ | `java -version` |
| Git | - | `git --version` |

> ✅ Proyek ini menggunakan **Laragon** untuk PHP + MySQL di Windows.

---

## 🗂️ Struktur Folder

```
c:\flutter\kiro\kasir\
├── bobkasir\           ← Flutter App
│   ├── android\
│   ├── lib\
│   ├── pubspec.yaml
│   └── MENJALANKAN_LOKAL.md   ← file ini
│
└── bobkasir\bobkasir-api\     ← Laravel Backend
    ├── app\
    ├── database\
    ├── routes\
    └── .env
```

---

## ⚙️ LANGKAH 1 — Setup Backend Laravel

### 1.1 Buka Terminal di folder backend

```bash
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api
```

### 1.2 Install dependencies (jika belum)

```bash
composer install
```

### 1.3 Pastikan file `.env` sudah ada

File `.env` sudah dikonfigurasi dengan:
- ✅ Gmail SMTP: `starcybercompany@gmail.com`
- ✅ Midtrans Sandbox: `Mid-client-tPgNA6HHSLs9lMwn`
- ✅ Google OAuth Client ID

Cek koneksi database di `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bobkasir
DB_USERNAME=root
DB_PASSWORD=
```

> Sesuaikan `DB_USERNAME` dan `DB_PASSWORD` dengan MySQL lokal kamu.

### 1.4 Buat database MySQL

Buka MySQL (via Laragon/phpMyAdmin/terminal):

```sql
CREATE DATABASE bobkasir CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Atau via terminal MySQL:

```bash
mysql -u root -e "CREATE DATABASE IF NOT EXISTS bobkasir CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 1.5 Jalankan migration + seeder

```bash
php artisan migrate --force
php artisan db:seed --force
```

Output yang diharapkan:
```
✓ Migrated: 2024_01_01_000001_create_businesses_table
✓ Migrated: 2024_01_01_000002_create_users_table
... (34 tabel)
BobKasir database seeded.
```

### 1.6 Generate App Key (jika belum)

```bash
php artisan key:generate
```

---

## 🖥️ LANGKAH 2 — Jalankan Backend Server

Buka **3 terminal terpisah** di folder `bobkasir-api`:

### Terminal 1 — API Server

```bash
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api
php artisan serve
```

Output:
```
INFO  Server running on [http://127.0.0.1:8000].
```

> 🔑 Biarkan terminal ini tetap berjalan.

### Terminal 2 — Queue Worker (Email Async)

```bash
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api
php artisan queue:work
```

Output:
```
INFO  Processing jobs from the [default] queue.
```

> Diperlukan untuk email verifikasi dan reset password.

### Terminal 3 — Scheduler (opsional, untuk notifikasi subscription)

```bash
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api
php artisan schedule:work
```

---

## 📱 LANGKAH 3 — Setup Emulator Android

### 3.1 Buka Android Studio → Device Manager

Klik **Virtual Device Manager** → pilih emulator atau buat baru:
- Rekomendasi: **Pixel 6** atau **Pixel 4**
- API Level: **33 (Android 13)** atau lebih tinggi
- RAM: minimal **2GB**

### 3.2 Jalankan emulator

Klik ▶️ di Device Manager, atau via terminal:

```bash
# Lihat daftar emulator
emulator -list-avds

# Jalankan emulator
emulator -avd Pixel_6_API_33
```

Tunggu hingga emulator fully booted (layar home Android muncul).

### 3.3 Verifikasi emulator terdeteksi Flutter

```bash
flutter devices
```

Output yang diharapkan:
```
emulator-5554 • sdk gphone64 x86 64 • android-x64 • Android 13 (API 33)
```

---

## 🌐 PENTING — Koneksi Emulator ke Backend

> **Emulator Android TIDAK bisa akses `localhost`.**  
> Gunakan alamat khusus: **`10.0.2.2`**

Alamat ini sudah dikonfigurasi di:

```
lib\core\constants\app_constants.dart
```

```dart
static const String apiBaseUrl = 'http://10.0.2.2:8000/api';
```

Artinya saat emulator mengakses `10.0.2.2:8000`, permintaan diteruskan ke `127.0.0.1:8000` di komputer host kamu.

---

## 🦋 LANGKAH 4 — Jalankan Flutter App

### 4.1 Buka Terminal di folder Flutter

```bash
cd c:\flutter\kiro\kasir\bobkasir
```

### 4.2 Install dependencies

```bash
flutter pub get
```

### 4.3 Jalankan ke emulator

```bash
flutter run
```

Jika ada lebih dari 1 device:

```bash
# Lihat device yang tersedia
flutter devices

# Pilih device spesifik
flutter run -d emulator-5554
```

### 4.4 Mode debug dengan hot reload

Setelah app berjalan di emulator:
- `r` → Hot Reload (update UI tanpa restart)
- `R` → Hot Restart (restart app)
- `q` → Quit

---

## ✅ LANGKAH 5 — Test Fungsionalitas

### 5.1 Test Register

1. Buka app di emulator → halaman Login
2. Tap **"Daftar"**
3. Isi nama, email, password → tap **"Daftar"**
4. Cek inbox email `starcybercompany@gmail.com` untuk link verifikasi
5. Klik link verifikasi
6. Login dengan email + password

### 5.2 Test Google Sign-In

1. Di halaman Login → tap **"Masuk dengan Google"**
2. Pilih akun Google
3. Otomatis masuk → trial popup muncul

> ⚠️ Google Sign-In butuh SHA-1 terdaftar di Firebase.  
> SHA-1 debug sudah terdaftar: `FF:7E:0D:C0:D8:BB:55:97:14:70:2D:71:62:8D:36:0E:45:95:52:54`

### 5.3 Verifikasi koneksi berhasil

Setelah login, cek terminal `php artisan serve`:
```
2026-06-10 14:30:00 POST /api/auth/login ...... 200 OK
2026-06-10 14:30:01 GET  /api/auth/me ......... 200 OK
```

---

## 🔧 Troubleshooting

### ❌ "Connection refused" / "Network unreachable"

**Penyebab:** Backend belum jalan atau URL salah.

```bash
# Pastikan backend berjalan
curl http://127.0.0.1:8000/api/auth/me

# Dari dalam emulator (via adb shell)
adb shell curl http://10.0.2.2:8000/api/auth/me
```

**Solusi:**
1. Pastikan `php artisan serve` berjalan
2. Pastikan `apiBaseUrl = 'http://10.0.2.2:8000/api'` di `app_constants.dart`
3. Cek firewall Windows tidak memblokir port 8000

### ❌ "SQLSTATE: No such host" / Database error

**Solusi:**
```bash
# Pastikan MySQL running (Laragon: klik Start)
php artisan migrate:status
php artisan migrate --force
```

### ❌ Email verifikasi tidak masuk

**Solusi:**
1. Pastikan `php artisan queue:work` berjalan
2. Cek spam/junk folder
3. Cek `storage/logs/laravel.log` untuk error SMTP

```bash
tail -f storage/logs/laravel.log
```

### ❌ Google Sign-In gagal / error 10

**Penyebab:** SHA-1 debug keystore tidak sesuai.

```bash
# Generate SHA-1
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v ^
  -keystore "%USERPROFILE%\.android\debug.keystore" ^
  -alias androiddebugkey -storepass android -keypass android
```

Daftarkan SHA-1 di **Firebase Console → Project Settings → BobKasir App → Add fingerprint**.

### ❌ `flutter: The declared package name doesn't match`

**Solusi:**
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ Gradle build error

```bash
cd android
.\gradlew clean
cd ..
flutter run
```

---

## 📊 Ringkasan Port & Service

| Service | URL / Port | Keterangan |
|---|---|---|
| Laravel API | `http://127.0.0.1:8000` | Di komputer host |
| Laravel API (dari emulator) | `http://10.0.2.2:8000` | Diakses emulator |
| MySQL | `127.0.0.1:3306` | Database lokal |
| Midtrans Sandbox | `sandbox.midtrans.com` | Payment gateway |
| Gmail SMTP | `smtp.gmail.com:587` | Email service |

---

## 🏃 Quick Start (Setelah Setup Pertama)

Untuk menjalankan ulang setelah setup awal selesai:

```bash
# Terminal 1 — Backend
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api && php artisan serve

# Terminal 2 — Queue
cd c:\flutter\kiro\kasir\bobkasir\bobkasir-api && php artisan queue:work

# Terminal 3 — Flutter (pastikan emulator sudah berjalan)
cd c:\flutter\kiro\kasir\bobkasir && flutter run
```

---

## 📱 Menggunakan Device Fisik (Alternatif)

Jika menggunakan HP Android asli (bukan emulator):

1. **Enable Developer Options** di HP → Settings → About Phone → tap Build Number 7x
2. **Enable USB Debugging**
3. Sambungkan HP ke PC via USB
4. Ubah `apiBaseUrl` di `app_constants.dart`:

```dart
// Ganti dengan IP komputer kamu (cek via ipconfig)
static const String apiBaseUrl = 'http://192.168.1.xxx:8000/api';
```

5. Jalankan:
```bash
flutter run
```

> 💡 Cek IP komputer: buka CMD → ketik `ipconfig` → lihat IPv4 Address

---

*BobKasir v1.0.0 · Created by StarCyberCompany · 2026*
