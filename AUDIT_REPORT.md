# Laporan Audit BobKasir v2.0

**Tanggal Audit:** 13 Juni 2026  
**Auditor:** Antigravity  
**Target:** Flutter App (Frontend) & Laravel 12 API (Backend)  
**Metodologi:** Read-Only Static Code Analysis  

Berikut adalah hasil audit kesesuaian proyek dengan PRD, Design System, serta best practices keamanan dan performa. Temuan diurutkan berdasarkan tingkat keparahan (severity).

---

## 🔴 CRITICAL (Kritis)

### 1. Restorasi Stok Cancel Salah Outlet (Cross-Outlet Data Leak)
* **File Terkait:** `bobkasir-api/app/Services/StockService.php` (Fungsi `restoreForCancel`) & `OrderController.php` (`cancelApprove`)
* **Bukti dari kode:** 
  Pada `StockService::restoreForCancel`, query yang digunakan adalah `$stock = Stock::where('product_id', $item['product_id'])->first();`. Fungsi ini sama sekali tidak menerima parameter `$outletId` maupun memfilter berdasarkan outlet.
* **Dampak real:** 
  Jika sebuah bisnis memiliki lebih dari 1 outlet (misal Outlet A dan Outlet B), dan karyawan Outlet A melakukan Cancel Order, sistem bisa saja merestore stok tersebut ke Outlet B (karena query hanya mengambil `.first()` yang ditemukan di tabel, tanpa mempedulikan milik outlet mana). Ini akan mengacaukan perhitungan stok fisik antar cabang.
* **Rekomendasi fix:** 
  Ubah parameter `restoreForCancel` di `StockService` agar menerima `$outletId` dari Order. Tambahkan kondisi `where('outlet_id', $outletId)` sebelum melakukan `.first()`.
* **Risiko jika difix:** 
  Jika ada Order lama yang datanya corrupt (tidak punya outlet_id padahal seharusnya punya), restorasi mungkin gagal. Perlu fallback ke `orWhereNull('outlet_id')` secara eksplisit.
* **Cara validasi manual:** 
  Buat 2 outlet. Lakukan transaksi di Outlet 2. Cancel order tersebut. Cek apakah stok Outlet 2 bertambah, atau malah stok Outlet 1 yang bertambah.

---

## 🟠 HIGH (Tinggi)

### 2. Prioritas Deduksi Stok Outlet vs Global Ambigu
* **File Terkait:** `bobkasir-api/app/Services/StockService.php` (Fungsi `deductForOrder`)
* **Bukti dari kode:** 
  ```php
  $q->where('outlet_id', $outletId)->orWhereNull('outlet_id');
  $stock = $q->first();
  ```
* **Dampak real:** 
  Jika database memiliki 2 record stok untuk produk yang sama (1 milik outlet spesifik, 1 bersifat global/null), query `.first()` tanpa `orderBy` tidak menjamin record spesifik outlet yang akan terpilih. Bisa jadi stok global yang terpotong meskipun transaksi terjadi di outlet spesifik.
* **Rekomendasi fix:** 
  Gunakan klausa `orderByRaw('outlet_id IS NULL ASC')` atau logic pemisahan pencarian agar stok dengan `outlet_id` yang spesifik lebih diutamakan ketimbang yang `null`.
* **Risiko jika difix:** Sangat minim, membuat alur menjadi deterministik.
* **Cara validasi manual:** Buat stok global dan stok outlet spesifik. Lakukan checkout di outlet spesifik dan periksa stok mana yang berkurang.

### 3. Kategori Dinonaktifkan (Soft Delete) Tidak Memfilter Produk di Kasir
* **File Terkait:** `bobkasir-api/app/Http/Controllers/Api/ProductController.php` (Fungsi `destroyCategory` dan `index`)
* **Bukti dari kode:** 
  `destroyCategory` mengubah `is_active = false`. Namun, di endpoint `index` (untuk produk), tidak ada pengecekan status kategori dari produk tersebut, hanya memfilter `is_active` milik tabel produk itu sendiri.
* **Dampak real:** 
  Produk yang berada di bawah kategori yang sudah dinonaktifkan (atau dihapus) akan tetap muncul di aplikasi Kasir. Karyawan masih bisa menjual produk dari menu yang seharusnya sudah "hilang".
* **Rekomendasi fix:** 
  Ubah fungsi `index` produk dengan `$q->whereHas('category', function($c) { $c->where('is_active', true); })` jika ingin menyembunyikan produk di kategori mati, atau cascade update `is_active = false` ke semua produk di kategori tersebut saat kategori dihapus.
* **Risiko jika difix:** Harus dipertimbangkan secara bisnis, apakah produk di kategori mati boleh dipindah kategori atau otomatis mati.
* **Cara validasi manual:** Nonaktifkan satu kategori di Dashboard. Buka halaman Kasir, cek apakah produk dari kategori tersebut masih muncul.

---

## 🟡 MEDIUM (Menengah)

### 4. Tidak Ada Peringatan Perbedaan Harga Klien vs Server
* **File Terkait:** `bobkasir-api/app/Services/OrderCreationService.php`
* **Bukti dari kode:** 
  Server mengabaikan grand total yang dikirim client (`$price = (int) $product->price;`) dan menghitung ulang.
* **Dampak real:** 
  Aplikasi Kasir (Flutter) yang tidak terkoneksi lama mungkin menampilkan harga lama (misal Rp10.000). Karyawan menagih Rp10.000 ke pelanggan. Ketika disinkronisasi/di-push ke server, server menghitung berdasarkan harga baru (misal Rp15.000) dan mencatat piutang kurang bayar atau selisih setoran kasir.
* **Rekomendasi fix:** 
  Untuk order *online*, bandingkan `grand_total` client dengan server. Jika beda, return HTTP 409 Conflict agar Kasir bisa reload harga terbaru sebelum menagih customer. Untuk order *offline/sync*, tetap terima namun simpan flag `price_discrepancy` untuk audit Manager.
* **Risiko jika difix:** API checkout bisa gagal jika terjadi *race condition* (harga berubah pas detik checkout). Perlu UI handling di Flutter.
* **Cara validasi manual:** Ubah harga produk di database via raw query. Jangan refresh Flutter. Lakukan checkout. Cek total harga yang terpotong di database vs struk Flutter.

### 5. Role Karyawan Tidak Dapat Mengecek Stok di Aplikasi
* **File Terkait:** `bobkasir-api/routes/api.php`
* **Bukti dari kode:** 
  Route `api/stocks` dilindungi oleh `middleware('role:owner,manager')`. Padahal endpoint `api/products` (yang diakses Kasir) meload relasi `stock`.
* **Dampak real:** 
  Ini sudah setengah benar karena PRD melarang karyawan *mengelola* stok. Namun, jika relasi `stock` di `products` tidak cukup untuk UI Kasir mengetahui stok *real-time* (karena butuh memanggil `/stocks` terpisah), Karyawan tidak akan tahu jika barang habis sebelum di-checkout.
* **Rekomendasi fix:** 
  Pastikan Flutter mengambil data stok untuk validasi UI murni dari response payload `/products`, bukan melakukan call ke `/stocks`. Backend sudah menyertakan `with('stock')`, jadi hanya perlu dipastikan Flutter tidak mem-fetch route yang dilarang.
* **Risiko jika difix:** Tidak ada.

---

## 🟢 LOW (Rendah)

### 6. Desain Flutter Theme vs Elevasi (UI/UX)
* **File Terkait:** `lib/core/theme/app_theme.dart`
* **Bukti dari kode:** 
  Sesuai `design.md`, mode terang menggunakan `box-shadow: 0 20px 40px rgba(0, 0, 0, 0.04)` (sangat soft). Namun di implementasi `app_theme.dart`, `CardTheme` memiliki `shadowColor: const Color(0x0A000000)` dan `elevation: 0`. Elevation 0 di Material 3 menghilangkan shadow bawaan, jadi shadow tidak akan muncul kecuali menggunakan widget dekorasi kustom.
* **Dampak real:** 
  Elemen UI mungkin terlihat "flat" alih-alih memiliki kesan "elevasi mewah" yang direquest pada PRD/Design v2.0 Premium Edition.
* **Rekomendasi fix:** 
  Bungkus widget dengan `Container(decoration: BoxDecoration(boxShadow: [...]))` di komponen terkait daripada mengandalkan properti bawaan `Card` Material 3 yang `elevation: 0`.

### 7. Google Login Fallback
* **File Terkait:** `AuthController.php`
* **Bukti dari kode:** 
  Ada manual HTTP Get ke `https://oauth2.googleapis.com/tokeninfo`. Ini metode yang valid sebagai fallback, tetapi bisa menjadi titik kegagalan (*bottleneck*) jika Google rate limit, mengingat ini synchronous.
* **Rekomendasi fix:** 
  Pertimbangkan menggunakan JWT parsing lokal (seperti library `google/apiclient`) untuk memverifikasi signature ID Token Google tanpa harus hit network.

---

## 🗺️ Roadmap Fixing yang Aman

1. **Phase 1: Critical & High Backend Fix (Bisa langsung di-hotfix ke Production)**
   - Update `StockService.php` agar `restoreForCancel` dan `deductForOrder` selalu peduli pada `$outletId`.
   - Update `ProductController::index` agar membuang produk dari kategori yang mati.

2. **Phase 2: Logic Validation (Medium)**
   - Tambahkan *discrepancy warning* di `OrderCreationService`. Jika ada perbedaan grand_total > 0 saat transaksi *online*, lempar error agar Kasir update menu.

3. **Phase 3: Refinement UI/UX & Flutter (Low)**
   - Update komponen UI Flutter agar shadow (bayangan) mematuhi *Ivory Elegance* menggunakan `BoxDecoration`, bukan sekadar `Card` dengan `elevation: 0`.
   - Lakukan QA pada layar Karyawan untuk memastikan peringatan "Stok Habis" berfungsi tanpa harus memanggil endpoint `/stocks`.

---
*Laporan di-generate secara otomatis via Read-Only Audit.*
