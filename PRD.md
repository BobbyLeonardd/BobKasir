# PRD — BobKasir

> Dokumen kebutuhan produk (Product Requirements Document) untuk aplikasi POS/Kasir **BobKasir**.
> Versi: 1.2 · Terakhir diperbarui: 28 Juni 2026
> Identitas pembuat aplikasi: **StarCyberCompany**

---

## 1. Ringkasan Produk

**BobKasir** adalah aplikasi Point of Sale (POS) / kasir berbasis Flutter untuk kedai (kopi, minuman, makanan, dan sejenisnya). Aplikasi ditujukan untuk umum (multi-tenant), dapat dipakai banyak kedai sekaligus. Setiap kedai mendaftar sebagai tenant/owner, lalu mengelola admin dan kasir sendiri.

Target platform: Android & iOS (deploy ke Play Store & App Store). Aplikasi harus responsif dan dapat berjalan di beberapa device secara bersamaan (multi-device).

### 1.1 Tujuan
- Kasir cepat, minim hambatan operasional.
- Bisa jalan offline (kasir tetap hidup saat jaringan mati), sinkron otomatis saat online.
- Cetak struk Bluetooth ke printer umum + cash drawer opsional.
- Laporan lengkap untuk owner/admin.
- Sistem langganan berbayar (trial 7 hari, lalu per minggu / per bulan).

### 1.2 Identitas
- Nama aplikasi: **BobKasir**
- Pembuat / brand: **StarCyberCompany**
- Identitas ini harus tampil di splash screen (di bawah logo) dan di footer struk / halaman about.

---

## 2. Tech Stack

| Bagian | Teknologi |
|---|---|
| Mobile app | Flutter (Dart) |
| State management | **Riverpod** (keputusan final — konsisten, testable, tidak perlu boilerplate BLoC) |
| Local DB | **Drift** (keputusan final — type-safe, reactive, cocok untuk offline-first) |
| Backend API | Laravel (REST API) |
| Database | MySQL |
| Testing lokal | Laragon + phpMyAdmin |
| Email | Gmail SMTP (verifikasi email, reset sandi, notifikasi) |
| Pembayaran langganan | RevenueCat (Google Play / App Store In-App Purchases) |
| Login sosial | Google Sign-In |
| Cetak struk | Bluetooth printer (ESC/POS) |
| Push notification | Firebase Cloud Messaging (FCM) — Android & iOS |
| Cash drawer | Sambungan via printer (ESC/POS kick command) atau perangkat terpisah, opsional on/off |

---

## 3. Role & Hak Akses

Ada 3 role. Semua role memiliki label "terhubung ke owner" (akun admin & kasir tetap berada di bawah owner/kedai yang membuatnya, terlepas dari perubahan data diri mereka).

| Fitur / Menu | Owner (Superadmin) | Admin (Manager) | Kasir (Karyawan) |
|---|:--:|:--:|:--:|
| Kasir (utama, default landing) | ✅ | ✅ | ✅ |
| Riwayat Pesanan | Lihat + Cancel | Lihat + Cancel | Lihat + Request Cancel |
| Dashboard | ✅ | ✅ | ❌ |
| Produk & Kategori (CRUD) | ✅ | ✅ | ❌ |
| Pengaturan - Kelola Akun/Role | ✅ | ❌ | ❌ |
| Pengaturan - Langganan | ✅ | ❌ | ❌ |
| Pengaturan - Printer & Cash Drawer | ✅ | ✅ | ✅ |
| Pengaturan - Edit Struk | ✅ | ✅ | ❌ |
| Pengaturan - Kelola Akun Sendiri | ✅ | ✅ | ✅ |

Catatan:
- Default landing setelah login (semua role): **Tampilan Kasir**.
- Cancel order penuh: owner & admin. Kasir hanya **request cancel** (wajib isi alasan), menunggu persetujuan owner/admin.

---

## 4. Alur Autentikasi & Onboarding

### 4.1 Splash Screen
- Tampilkan logo BobKasir + versi aplikasi + identitas "StarCyberCompany".
- Durasi singkat, lalu arahkan ke login (jika belum login) atau ke home (jika masih punya sesi valid).
- Loading ringan, jangan terlalu lama (max 2 detik).

### 4.2 Halaman Login
Tersedia:
- Login email + sandi
- Login Google
- Link ke registrasi
- Link lupa sandi

Aturan verifikasi email saat login:
- Owner: **wajib verifikasi email** saat login (kecuali login Google).
- Admin: **wajib verifikasi email** saat login (kecuali login Google).
- Kasir: **tidak wajib verifikasi email** saat login (agar operasional cepat), kecuali login Google (tidak perlu verif).
- Login Google: tidak perlu verifikasi email untuk semua role.

### 4.3 Registrasi Akun Owner (tenant baru)
- Registrasi via email: **wajib verifikasi email**.
- Registrasi via Google: tidak perlu verifikasi email.
- Email terverifikasi → akun aktif → lanjut ke onboarding kedai (nama kedai, dll).

### 4.4 Lupa Sandi
- Wajib verifikasi email (kode OTP / link via Gmail SMTP).
- Reset sandi setelah verifikasi sukses.

### 4.5 Registrasi Admin & Kasir (oleh owner)
- Hanya lewat email (tidak ada registrasi Google).
- Pendaftaran admin: **wajib verifikasi email**.
- Pendaftaran kasir: **wajib verifikasi email** (sekali saat dibuat), namun saat login sehari-hari tidak wajib verif ulang.
- Login admin & kasir bisa pakai Google (opsional), tidak perlu verif email.

### 4.6 Popup Berlangganan (setelah login owner)
- Setelah owner login pertama kali: popup berlangganan.
- **Trial 7 hari gratis** akses semua fitur.
- Setelah 7 hari: akses fitur penuh diblokir, hanya fitur dasar yang bisa dipakai. Wajib berlangganan untuk lanjut.
- Pilihan paket: **per minggu** atau **per bulan**.
- Pembayaran: In-App Purchases via RevenueCat (otomatis terhubung dengan Apple/Google akun pengguna).

---

## 5. Modul Kasir (Utama)

Tampilan default saat owner, admin, kasir login. Diterapkan sama untuk semua role.

### 5.1 Layout Kasir
- Tab/kategori produk (mis: Klasik Kopi, Non-Kopi, Makanan).
- Grid/list produk per kategori.
- Keranjang (cart) di samping / bawah.
- Aksi: **Openbill**, **Reservasi**, **Checkout**.

### 5.2 Alur Transaksi Standar
1. User klik produk (mis: Americano di kategori Klasik Kopi) 1x → produk masuk ke keranjang. Klik lagi menambah qty.
2. Di keranjang user bisa:
   - **Openbill** → simpan bill sementara, bisa dipanggil lagi nanti.
   - **Checkout** langsung.
3. Tampilan Checkout:
   - Nama customer (opsional)
   - Tempat duduk / meja (opsional)
   - Keterangan (opsional)
   - Daftar item + total
   - Pilih metode pembayaran (semua metode umum: tunai, QRIS, debit, e-wallet, dll — input manual/label, bukan gateway untuk transaksi kedai)
4. Konfirmasi pembayaran → simpan order.
5. Struk muncul di layar.
6. Tombol: **Cetak Struk Customer** & **Cetak Struk Dapur**.
7. Cetak bisa dilakukan **berkali-kali**.

### 5.3 Openbill
- Simpan transaksi yang belum selesai sebagai `openbill` dengan status `open`.
- Daftar openbill aktif bisa dipanggil dari tombol "Openbill" di layar kasir.
- Klik openbill → load kembali ke keranjang → lanjut checkout.
- Satu tenant bisa punya banyak openbill aktif bersamaan (mis: meja 1, meja 2, dst).
- Openbill tidak otomatis expired. Bisa dihapus manual oleh owner/admin, atau otomatis bersih saat dikonversi menjadi order selesai/cancel.
- Berguna saat customer pesan dulu, bayar nanti.

### 5.4 Reservasi
- Catat reservasi: nama customer, nomor meja (free text), waktu kedatangan, keterangan.
- Status reservasi: `pending` → `arrived` → `cancelled`.
- Saat customer datang: kasir buka daftar reservasi, pilih reservasi → klik **Konversi ke Order** → item reservasi (jika ada) masuk ke keranjang, reservasi berubah status `arrived`.
- Reservasi tanpa item tetap bisa dibuat (pure booking meja), kasir tambah item manual saat konversi.
- Bisa dibatalkan (`cancelled`) kapan saja oleh owner/admin/kasir dengan alasan opsional.

### 5.5 Split Bill
- Satu order bisa dibagi tagihan ke beberapa metode pembayaran / beberapa orang.
- Contoh: total Rp120.000 dibagi jadi Tunai Rp70.000 + QRIS Rp50.000.
- Tampilan input tiap bagian + validasi total bagian = total order (atau ditandai "belum lunas" jika kurang).
- Setelah split selesai, order tetap satu ID, tercatat metode pembayaran per bagian.

### 5.6 Pembayaran
- Pendukung semua metode umum (label/manual input nominal + metode).
- Input nominal tunai → otomatis hitung kembalian.
- Bisa multiple tender (split bill) seperti di atas.

---

## 6. Modul Riwayat Pesanan

Berlaku semua role, dengan batasan:
- Owner & Admin: lihat + **cancel order**.
- Kasir: lihat + cetak struk + **request cancel** (tidak bisa cancel langsung).

### 6.1 Daftar Riwayat
- Filter: tanggal, kasir, status (lunas / cancel / request cancel).
- Lihat detail order (item, metode bayar, nama kasir yang menangani, waktu).
- Cetak struk customer & dapur (berkali-kali).

### 6.2 Pelacakan Kasir
- Setiap order tercatat **kasir mana yang memproses** (nama user + role + waktu).
- Owner/admin bisa melihat daftar kasir yang bekerja hari ini + transaksi per kasir.
- Tujuan: kalau ada kesalahan input / pelanggaran, owner/admin bisa telusuri siapa pelakunya.

### 6.3 Cancel Order
- Owner & Admin: cancel langsung, wajib isi **alasan/keterangan**.
- Kasir: ajukan **request cancel** (wajib alasan) → muncul notifikasi ke owner & admin.
- Owner/admin setujui → cancel berhasil. Tolak → order tetap ada, tidak di-cancel.
- Request cancel yang menunggu: tampil badge/status di riwayat.

---

## 7. Modul Dashboard

Hanya owner & admin.

### 7.1 Grafik Penjualan
- Grafik omzet / jumlah transaksi.
- Rentang: harian, mingguan, bulanan, tahunan.

### 7.2 Laporan Komparatif
- Hari ini vs kemarin
- Minggu ini vs minggu lalu
- Bulan ini vs bulan lalu
- Tahun ini vs tahun lalu
- Tampilkan angka + persentase naik/turun.

### 7.3 Export Laporan
- Cetak via printer Bluetooth (format ringkas struk).
- Download:
  - Gambar (PNG/JPG)
  - PDF
  - Excel (.xlsx)
- Filter rentang waktu sebelum export.

---

## 8. Modul Produk & Kategori

Hanya owner & admin. CRUD penuh.

### 8.1 Kategori
- Buat / edit / hapus kategori (mis: Klasik Kopi, Non-Kopi, Makanan).
- Kategori dipakai sebagai filter di kasir.

### 8.2 Produk
Saat membuat/edit produk:
- Pilih kategori (dari kategori yang sudah ada).
- Nama produk (wajib).
- Gambar (opsional) — disimpan di server atau local. Bisa upload file.
- Harga — input fleksibel:
  - Terima `50000`, `50.000`, `Rp50000`, `Rp50.000` → dinormalisasi ke angka.
  - Tidak boleh negatif / non-numerik.
- Keterangan (opsional).

### 8.3 Stok (opsional / rekomendasi)
- Bisa tambahkan field stok opsional. Kalau 0 → produk ditandai "habis" di kasir. (Saran: mulai opsional, bisa dimatikan.)

---

## 9. Modul Pengaturan (Settings)

### 9.1 Kelola Akun / Role (owner only)
- Tambah admin (boleh lebih dari satu).
- Tambah kasir (banyak).
- Pendaftaran lewat email, wajib verifikasi email.
- Edit / nonaktifkan / hapus akun bawahan.
- Setiap akun tetap terhubung ke owner, terlepas dari perubahan data diri.

### 9.2 Langganan (owner only)
- Lihat status langganan aktif (paket, mulai, berakhir).
- Upgrade / downgrade paket (mingguan ↔ bulanan) dikelola langsung oleh platform (iOS/Android) via RevenueCat.
- Bayar:
  - Otomatis via RevenueCat In-App Purchases.
- Auto-renewal: ditangani oleh Apple/Google Subscription system.
- Jika langganan kedaluwarsa/tidak diperpanjang: blokir fitur penuh, hanya fitur dasar (lihat riwayat read-only & pengaturan akun sendiri) yang bisa dipakai.

### 9.3 Printer Struk Bluetooth & Cash Drawer
- Scan / pair printer Bluetooth dari dalam aplikasi.
- Target: mendukung **printer struk Bluetooth umum** (berbasis ESC/POS). Bukan hanya satu brand.
- Setelah terhubung: tombol **Test Cetak**.
- Cash Drawer:
  - Opsi **On / Off** (default Off).
  - Implementasi: lewat perintah ESC/POS kick drawer pada printer yang mendukung (kebanyakan printer Bluetooth thermal 58mm/80mm punya port RJ11 untuk drawer). Jika printer tidak mendukung, drawer off.
  - Saat checkout & cash drawer on → otomatis trigger kick drawer.
- Status koneksi printer tampil jelas (terhubung / putus). Kasir bisa sambungkan ulang sendiri tanpa panggil owner.

### 9.4 Edit Struk
- Edit template struk:
  - Nama kedai
  - Alamat / nama jalan
  - Keterangan (mis: password WiFi kedai)
  - Footer / ucapan terima kasih
  - Logo (opsional)
  - Ukuran kertas (58mm / 80mm)
- Preview struk sebelum simpan.

### 9.5 Kelola Akun Sendiri (semua role)
- Edit nama.
- Ganti email — wajib verifikasi email baru.
- Reset / ganti sandi — wajib verifikasi email (OTP/link).
- Perubahan ini tidak memutus hubungan ke owner (untuk admin & kasir).
- **Hapus akun** (owner bisa hapus akun sendiri = hapus tenant? → konfirmasi ganda). Admin & kasir bisa minta hapus / owner yang hapus.

---

## 10. Offline & Sinkronisasi

- Saat offline, **kasir tetap jalan**:
  - Bisa buka order, tambah item, checkout, cetak struk lokal.
  - Data tersimpan di local DB (Drift) dengan `sync_status = pending_sync`.
- Saat online kembali: **sinkron otomatis** via background worker ke endpoint `POST /sync/orders`.
- Field yang bisa konflik: `total`, `items`, `payment_method`, `status`.
- Konflik resolution: timestamp-based (`created_at` device vs server). Server sebagai source of truth.
  - Jika harga produk berubah di server saat device offline → order tetap disimpan dengan harga lama (snapshot), diflag `needs_review = true` untuk owner/admin. Tidak otomatis overwrite.
  - Jika produk dihapus di server saat device offline → item tetap tercatat dengan `product_id = null`, `product_name` dari snapshot. Order tetap valid, tidak gagal sync.
- Sinkron payload `/sync/orders`:
  - Request: `{ orders: [{ local_id, items, payments, ... }] }`
  - Response: `{ synced: [{ local_id, server_id }], failed: [{ local_id, reason }] }`
  - Setelah sync sukses, local DB update `local_id → server_id`, `sync_status = synced`.
- Data master (produk, kategori) di-cache lokal, di-refresh saat online.

---

## 11. Multi-Device & Responsif

- Akun/kedai bisa login dari beberapa device bersamaan.
- Sesi aman, refresh token.
- UI responsif: tablet / handset, portrait & landscape.
- Tablet: layout kasir dua kolom (katalog + keranjang). Handset: satu kolom, keranjang sebagai bottom sheet.

---

## 12. Email (Gmail SMTP)

- Verifikasi email: pendaftaran owner/admin/kasir, login owner/admin.
- Reset sandi.
- Notifikasi (request cancel, langganan akan kedaluwarsa, dst).
- Pakai Gmail SMTP (App Password). Konfigurasi di backend Laravel, jangan hardcode secret di app.

---

## 13. Pembayaran Langganan (RevenueCat)

- Pembayaran menggunakan standar platform: Google Play Billing (Android) & Apple In-App Purchases (iOS).
- Flow:
  1. Owner melihat _paywall_ (halaman langganan) dengan *offerings* (mingguan/bulanan) dari RevenueCat.
  2. Owner tap "Beli" → Muncul popup sistem Apple/Google.
  3. Konfirmasi via sidik jari / FaceID / sandi.
  4. Aplikasi menerima event sukses dari RevenueCat SDK dan membuka akses *premium*.
  5. Backend Laravel bisa menerima *webhook* opsional dari RevenueCat untuk mencatat riwayat di server.

---

## 14. Login & Register Google

- Google Sign-In untuk: owner, admin, kasir.
- Login Google = tanpa verifikasi email.
- Registrasi owner via Google = tanpa verifikasi email.
- Registrasi admin & kasir tetap lewat email oleh owner (tidak pakai Google saat pembuatan), tapi saat login bisa pakai Google.

---

## 15. Struk Cetak

### 15.1 Struk Customer
- Header: nama kedai, alamat, keterangan (WiFi).
- Body: item, qty, harga, subtotal.
- Footer: total, metode bayar, kembalian, nama kasir, waktu, nomor order.
- Tombol cetak berulang.

### 15.2 Struk Dapur
- Header: nomor order, waktu, nama customer, meja/tempat duduk, keterangan.
- Body: item + qty + keterangan per item.
- Tanpa harga.
- Tombol cetak berulang.

---

## 16. Alur Pengujian Lokal

1. Setup Laragon (Apache + MySQL + PHP).
2. Buat database via phpMyAdmin (mis: `bobkasir`).
3. Deploy backend Laravel ke folder Laragon, jalankan migration & seeder.
4. Flutter app arahkan base URL ke `http://<ip-lokal>/api` (bukan localhost saat pakai device fisik).
5. Test alur: register owner → verifikasi email (Mailtrap dulu / Gmail SMTP) → trial → buat kategori & produk → kasir transaksi → cetak struk Bluetooth → dashboard.
6. Test offline: matikan WiFi saat kasir → transaksi → nyalakan lagi → cek sinkron.

---

## 17. Saran & Rekomendasi Tambahan

Berikut fitur/tambahan yang sebaiknya dipertimbangkan (belum eksplisit diminta, tapi relevan):

1. **Backup & Restore lokal** — ekspor data transaksi ke file (csv/json) dari device.
2. **Mode hemat / dark mode** — kasir sering dipakai lama, dark mode membantu mata.
3. **PIN cepat kasir** — login kasir pakai PIN 4-6 digit selain email/Google, untuk shift cepat.
4. **Shift & tutup kasir (X/Z report)** — ringkasan per shift kasir, penting untuk rekonsiliasi kas.
5. **Diskon & pajak** — input diskon per item / per order, PPN opsional.
6. **Modifier produk** — size (S/M/L), tingkat gula, extra shot, dll. Sangat umum di kedai kopi.
7. **Stok real-time** — kurangi stok otomatis saat order, alert stok menipis.
8. **Notifikasi push** — request cancel, langganan expiring, order masuk (untuk dapur).
9. **Multi-bahasa** — ID default, siap EN.
10. **Audit log** — catat siapa melakukan apa & kapan (CRUD produk, cancel order, ubah harga). Penting untuk akuntabilitas.
11. **Printer fallback** — kalau Bluetooth utama gagal, bisa pindah printer lain cepat.
12. **QR menu (opsional)** — customer scan QR lihat menu (read-only), bukan untuk pesan langsung (di luar scope v1, tapi good-to-have).
13. **Keamanan** — rate limit API, enkripsi data sensitif, token rotasi, validasi input ketat di Laravel.
14. **Telemetri error** — crash reporting (opsional, mis. Sentry) untuk stabil saat produksi.

---

## 18. Catatan Desain / UX

- Desain harus terlihat natural, dibuat manusia — **bukan** kesan generik AI.
- Hindari gradien norak, ilustrasi robot AI, ikon overused.
- Pakai palet warna nyaman untuk operasional kasir (kontras cukup, tidak silau).
- Tipografi jelas, angka besar di keranjang & total.
- Tombol aksi kasir besar, mudah disentuh (target ukuran min 48dp).
- Hierarki visual: kategori → produk → keranjang → checkout → bayar → struk.
- Konsistensi spacing & komponen (pakai design token / theme).

---

## 19. Out of Scope (v1)

- Pemesanan online / delivery pihak ketiga (GoFood/GrabFood integration).
- Inventory gudang multi-cabang.
- Loyalty program / membership customer.
- Kitchen Display System (KDS) terpisah (cetak dapur dulu lewat printer).

---

## 20. Acceptance Criteria (Ringkas)

- [ ] Splash screen tampil logo + versi + StarCyberCompany.
- [ ] Register owner (email verif & Google) jalan.
- [ ] Login owner wajib verif email (kecuali Google).
- [ ] Popup trial 7 hari + paket mingguan/bulanan via RevenueCat.
- [ ] Kasir: katalog → keranjang → openbill/reservasi/checkout → bayar → struk (customer & dapur, berulang).
- [ ] Openbill: simpan, recall, hapus manual, auto-close saat checkout.
- [ ] Reservasi: buat, konversi ke order, batalkan.
- [ ] Split bill berfungsi, total valid, tiap bagian tercatat di tabel payments.
- [ ] Riwayat: owner/admin cancel, kasir request cancel (wajib alasan), pelacakan kasir per hari.
- [ ] Dashboard: grafik + komparasi + export gambar/pdf/excel + cetak Bluetooth.
- [ ] Produk & kategori CRUD, harga fleksibel (`Rp50.000`/`50000`), gambar opsional.
- [ ] Pengaturan: kelola role (owner), langganan (owner), printer BT + cash drawer on/off + test cetak, edit struk, kelola akun sendiri (verif email).
- [ ] Offline: kasir jalan tanpa jaringan, sinkron saat online. Produk dihapus/harga berubah saat offline → order tetap valid, flag needs_review.
- [ ] Multi-device & responsif (handset & tablet).
- [ ] Gmail SMTP untuk verif & reset sandi.
- [ ] Push notifikasi FCM: request cancel, langganan expiring, pembayaran sukses/gagal.
- [ ] RevenueCat untuk pembayaran langganan (In-App Purchases).
- [ ] Grace period diatur oleh kebijakan Apple/Google Play (biasanya otomatis).
- [ ] Downgrade paket: tidak berlaku di tengah periode aktif, queue ke paket berikutnya.
- [ ] Cash drawer on/off + trigger saat checkout (jika on & printer dukung).
- [ ] Printer Bluetooth umum (ESC/POS) didukung.
- [ ] Tenant isolation: setiap query di-scope ke tenant_id, tidak ada data bocor antar tenant.
- [ ] Token disimpan di secure storage (flutter_secure_storage), bukan plain text.
- [ ] Identitas StarCyberCompany tampil di splash & struk.

---

## 21. Arsitektur & Alur Data Tinggi

```
[Flutter App]
   │
   ├── Local DB (Drift/Isar)
   │    ├── master data (kategori, produk, printer config)
   │    ├── antrian transaksi offline
   │    └── cache session/token
   │
   └── REST API (Laravel)
        ├── AuthController        (register, login, verif, forgot, Google)
        ├── ProductController     (kategori/produk CRUD)
        ├── OrderController       (transaksi, openbill, reservasi, cancel)
        ├── ReportController      (dashboard, export)
        ├── UserController        (kelola role & akun sendiri)
        ├── SubscriptionController (langganan & RevenueCat webhook)
        └── PrintConfigController (setting struk)
        │
        └── MySQL (data persistent)
```

### Alur sinkronisasi offline → online
1. Kasir offline: order disimpan dengan status `pending_sync` di local DB.
2. Saat online, worker background mengirim antrian ke endpoint `/sync`.
3. Server validasi, balikkan `server_id` dan status `synced`.
4. Local DB update order_id menjadi ID server untuk integritas riwayat.
5. Jika konflik (misal harga produk sudah berubah di server saat offline): flag order untuk review owner/admin, tidak langsung overwrite.

### Alur verifikasi email login owner/admin
1. User login email/password.
2. Server cek password benar & email belum terverifikasi → kirim kode OTP/link ke Gmail.
3. Aplikasi tampilkan input OTP/link; user konfirmasi.
4. Server set `email_verified_at` & issue token.
5. Jika verifikasi gagal: user tetap belum bisa akses fitur penuh.

---

## 22. Skema Database Utama (MySQL)

> Tabel-tabel utama. Detail kolom & relasi disesuaikan saat TRD.

### 22.1 tenants
- `id`, `owner_user_id`, `shop_name`, `shop_address`, `shop_phone`, `subscription_status`, `subscription_expires_at`, `trial_until`, `created_at`, `updated_at`

### 22.2 users
- `id`, `tenant_id`, `role` (owner/admin/cashier), `name`, `email`, `email_verified_at`, `password`, `google_id`, `status` (active/inactive), `created_by`, `created_at`, `updated_at`

### 22.3 categories
- `id`, `tenant_id`, `name`, `description`, `order_index`, `created_at`, `updated_at`

### 22.4 products
- `id`, `tenant_id`, `category_id`, `name`, `description`, `price`, `image_url`, `stock` (nullable), `is_active`, `created_at`, `updated_at`

### 22.5 orders
- `id`, `tenant_id`, `user_id`, `cashier_name`, `customer_name`, `table_number`, `notes`, `total`, `payment_status`, `status` (open/completed/cancelled/request_cancel), `sync_status` (pending_sync/synced), `local_id` (UUID, untuk integritas saat offline), `created_at`, `updated_at`

### 22.5a openbills
- `id`, `tenant_id`, `user_id`, `label` (nama bebas, mis: "Meja 3"), `items_snapshot` (JSON), `created_at`, `updated_at`
- Catatan: `items_snapshot` menyimpan item sementara. Saat dikonversi jadi order, baris ini dihapus.

### 22.5b reservations
- `id`, `tenant_id`, `user_id`, `customer_name`, `table_number`, `arrival_time`, `notes`, `status` (pending/arrived/cancelled), `cancel_reason` (nullable), `created_at`, `updated_at`

### 22.6 order_items
- `id`, `order_id`, `product_id`, `product_name`, `qty`, `price`, `subtotal`, `notes` (keterangan per item, mis: "less sugar", opsional)

### 22.7 payments
- `id`, `order_id`, `method`, `amount`, `change_amount`, `reference`, `paid_at`, `split_index` (integer, urutan bagian dalam split bill; 1 jika tidak split)

### 22.7a device_tokens
- `id`, `user_id`, `tenant_id`, `fcm_token`, `device_platform` (android/ios), `created_at`, `updated_at`
- Catatan: satu user bisa punya beberapa token (multi-device). Token lama di-replace jika login ulang di device yang sama.

### 22.8 cancel_requests
- `id`, `order_id`, `requester_user_id`, `reason`, `status` (pending/approved/rejected), `approved_by`, `created_at`, `updated_at`

### 22.9 subscriptions
- `id`, `tenant_id`, `package` (weekly/monthly), `start_date`, `end_date`, `status`, `revenuecat_entitlement_id`, `original_transaction_id`, `created_at`, `updated_at`

### 22.10 receipt_settings
- `id`, `tenant_id`, `shop_name`, `shop_address`, `footer_text`, `wifi_password`, `paper_width` (58/80), `logo_url`, `cash_drawer_enabled`

### 22.11 audit_logs
- `id`, `tenant_id`, `user_id`, `action`, `entity_type`, `entity_id`, `old_value`, `new_value`, `ip_address`, `created_at`

---

## 23. Endpoint API Laravel (Outline)

### Auth
- `POST /auth/register` — register owner
- `POST /auth/login` — login email
- `POST /auth/google` — login/register Google
- `POST /auth/logout`
- `POST /auth/refresh`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `POST /auth/verify-email` (send & confirm)
- `POST /auth/resend-verification`

### Users (owner only untuk create/update bawahan)
- `GET /users`
- `POST /users` (admin/kasir)
- `GET /users/{id}`
- `PUT /users/{id}`
- `DELETE /users/{id}`
- `GET /users/profile`
- `PUT /users/profile`
- `DELETE /users/profile`

### Categories & Products
- `GET /categories`
- `POST /categories`
- `PUT /categories/{id}`
- `DELETE /categories/{id}`
- `GET /products`
- `POST /products`
- `GET /products/{id}`
- `PUT /products/{id}`
- `DELETE /products/{id}`

### Orders
- `POST /orders` (buat order)
- `GET /orders`
- `GET /orders/{id}`
- `POST /orders/{id}/cancel` (owner/admin)
- `POST /orders/{id}/request-cancel` (kasir)
- `POST /orders/{id}/approve-cancel`
- `POST /orders/{id}/reject-cancel`
- `POST /sync/orders` (batch sync offline)

### Reports
- `GET /reports/daily`
- `GET /reports/weekly`
- `GET /reports/monthly`
- `GET /reports/yearly`
- `GET /reports/compare`
- `GET /reports/export/{type}`

### Subscriptions
- `GET /subscriptions/current`
- `POST /subscriptions/webhook/revenuecat` (opsional untuk sinkronisasi DB lokal dengan RevenueCat)

### Openbills
- `GET /openbills` — daftar openbill aktif tenant
- `POST /openbills` — simpan openbill baru
- `PUT /openbills/{id}` — update item openbill
- `DELETE /openbills/{id}` — hapus openbill
- `POST /openbills/{id}/checkout` — konversi openbill jadi order

### Reservations
- `GET /reservations` — daftar reservasi (filter: status, tanggal)
- `POST /reservations` — buat reservasi baru
- `PUT /reservations/{id}` — edit reservasi
- `POST /reservations/{id}/arrive` — konversi ke order (ubah status arrived)
- `POST /reservations/{id}/cancel` — batalkan reservasi

### Cashier Activity
- `GET /reports/cashier-activity` — transaksi per kasir hari ini (owner/admin only)

### Notifications
- `GET /notifications` — daftar notifikasi user
- `POST /notifications/read/{id}` — tandai dibaca
- `POST /notifications/read-all` — tandai semua dibaca
- `POST /device-tokens` — register/update FCM token device

### Sync
- `POST /sync/orders` — batch sync offline orders

### Receipt & Printer
- `GET /receipt-settings`
- `PUT /receipt-settings`

---

## 24. Mekanisme Cash Drawer

### Kompatibilitas
- Printer thermal Bluetooth 58mm/80mm ESC/POS umum memiliki port RJ11/RJ12 untuk cash drawer.
- Printer menerima perintah kick drawer: byte `0x1B 0x70 0x00 0x19 0xFA` (pin 0) atau `0x1B 0x70 0x01 0x19 0xFA` (pin 1).
- Kebanyakan printer default pin 0.

### Setting
- Setting aplikasi: **Cash Drawer On/Off** (default Off).
- Jika On: setiap checkout sukses otomatis kirim kick command sebelum/memutar setelah struk customer.
- Jika printer tidak mendukung kick drawer: perintah tetap dikirim, drawer tidak bereaksi (tidak crash).

### Fallback Manual
- Tambahkan tombol **Buka Cash Drawer** manual di pengaturan printer.
- Tombol ini kirim kick command kapan saja untuk test/buka manual.

---

## 25. Sistem Langganan Detail

### Status Langganan
- `trial` — 7 hari pertama, semua fitur aktif.
- `active` — langganan berbayar masih berlaku.
- `expired` — tidak ada langganan aktif, fitur terbatas.

### Perhitungan Waktu
- Saat owner register, `trial_until` = now + 7 hari.
- Setelah bayar, `subscription_expires_at` = max(subscription_expires_at, now) + durasi paket (7 hari / 30 hari).
- Contoh: owner trial habis hari ini, bayar bulanan → langganan aktif 30 hari mulai hari ini (bukan dari akhir trial + 30 hari, agar tidak ada gap).

### Fitur yang Tetap Bisa Diakses Saat Expired
- Lihat riwayat pesanan (read-only).
- Kelola akun sendiri (owner bisa ganti password/email, tapi untuk akses fitur harus bayar).
- Tidak bisa: transaksi baru, CRUD produk, CRUD role, dashboard, edit struk.

### Grace Period
- Setelah expired: **grace period 1 hari** sebelum fitur benar-benar diblokir, agar owner punya waktu bayar tanpa operasional terganggu.
- Setelah grace period habis: akses fitur terbatas seperti di atas.

### Renewal / Upgrade / Downgrade
- Bayar paket yang sama = perpanjang dari tanggal expired (atau sekarang jika sudah lewat).
- **Upgrade** (mingguan → bulanan): durasi baru = now + 30 hari (menimpa sisa waktu lama).
- **Downgrade** (bulanan → mingguan): dikelola otomatis oleh Google/Apple Store (prorata atau mulai di siklus berikutnya).
- RevenueCat webhook opsional untuk backup data, *source of truth* ada di SDK RevenueCat di dalam aplikasi.

### Owner Hapus Akun
- Owner hapus akun = hapus tenant beserta semua data (user, produk, order, dll).
- Wajib konfirmasi ganda (ketik ulang nama kedai).
- Jika langganan aktif: tampilkan peringatan "Langganan aktif akan hangus, tidak ada refund."
- Soft delete dulu (30 hari), setelah itu hard delete. Selama soft delete, owner bisa batalkan penghapusan.

---

## 26. Notifikasi & Email Detail

| Event | Email ke | Push | Catatan |
|---|---|---|---|
| Register owner via email | Owner | - | Link verifikasi |
| Register admin/kasir oleh owner | Admin/kasir | - | Link verifikasi + info login |
| Login owner/admin perlu verif | Owner/admin | - | Kode OTP/link |
| Lupa sandi | User | - | Link reset |
| Request cancel order | Owner & admin | Ya (owner/admin) | Alasan cancel |
| Approved/rejected cancel | Kasir | - | Status persetujuan |
| Langganan akan kedaluwarsa | Owner | Ya | H-3, H-1 |
| Langganan kedaluwarsa | Owner | Ya | Saat expired |
| Pembayaran sukses | Owner | Ya | Invoice singkat |
| Pembayaran gagal/pending | Owner | Ya | Minta selesaikan pembayaran |

---

## 27. Keamanan

- **Auth**: Laravel Sanctum, access token 15 menit, refresh token 30 hari. Token di-revoke saat password diganti atau logout.
- **Session concurrent**: tidak ada batasan jumlah device login bersamaan, tapi setiap device punya token sendiri. Logout dari satu device tidak mempengaruhi device lain (kecuali "logout semua device").
- **Role middleware**: setiap endpoint dilindungi middleware role, tidak bisa diakses lintas tenant.
- **Tenant isolation (wajib)**: setiap query ke DB **harus** di-scope ke `tenant_id` user yang sedang login. Ini mandatory di semua controller — gunakan global scope Eloquent atau trait khusus. Satu middleware yang terlewat bisa expose data antar tenant.
- **Rate limiting**: login max 5x per menit per IP. API umum max 60 req/menit per token.
- **Password**: bcrypt, min 8 karakter.
- **Validasi input**: Laravel Form Request untuk semua endpoint, reject input yang tidak sesuai tipe/format.
- **SQL injection**: pakai Eloquent / Query Builder, tidak ada raw query dengan input user langsung.
- **Secrets**: tidak hardcode API key, Midtrans key, FCM key, atau Gmail credential di kode. Simpan di `.env`, tidak di-commit ke repo.
- **Data lokal**: token yang disimpan di local DB (Drift) tidak boleh disimpan sebagai plain text — simpan di secure storage (flutter_secure_storage).
- **Gambar produk**: validasi tipe file (hanya image), max size 2MB, simpan di server dengan nama acak (bukan nama asli upload).
- **XSS/CSRF**: aktifkan proteksi Laravel default untuk semua route web.
- **Audit log**: catat aksi sensitif (login, CRUD produk, cancel order, ubah harga, ubah role, hapus akun) ke tabel `audit_logs`.
