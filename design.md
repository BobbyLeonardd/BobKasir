# Design — BobKasir

> Dokumen desain UI/UX untuk aplikasi POS/Kasir **BobKasir**.
> Versi: 1.0 · Terakhir diperbarui: 28 Juni 2026
> Referensi: PRD v1.2

---

## 1. Prinsip Desain

Desain BobKasir dibangun di atas empat prinsip:

**1. Operasional dulu.** Kasir dipakai saat sibuk — antrian pelanggan panjang, waktu terbatas. Setiap aksi utama harus bisa dilakukan dalam 1-3 tap. Tidak ada langkah tersembunyi.

**2. Bersih tanpa hambar.** Simple bukan berarti membosankan. Warna hangat, tipografi tegas, whitespace cukup — terasa seperti aplikasi buatan manusia, bukan template.

**3. Jelas di semua kondisi.** Angka harga, total, kembalian harus terbaca dari jarak 50cm di bawah cahaya toko. Kontras WCAG AA minimum wajib di semua teks penting.

**4. Konsisten sampai detail.** Radius, shadow, spacing, warna status — semua pakai token. Tidak ada "kira-kira". Developer dan designer bicara bahasa yang sama.

## 2. Design Token (Warna, Tipografi, Spacing)

### 2.1 Palet Warna

Tema utama: **warm neutral + amber accent**. Cocok untuk suasana kedai kopi, tidak silau saat dipakai seharian.

```
// Light Mode
--color-primary:       #C8892A   // amber warm — tombol utama, aksen aktif
--color-primary-dark:  #A06B18   // hover / pressed state
--color-primary-light: #F5DEB3   // background chip kategori aktif

--color-surface:       #FFFFFF
--color-surface-2:     #F7F5F2   // background kasir, card produk
--color-surface-3:     #EEEBE6   // divider, border ringan

--color-on-surface:    #1A1714   // teks utama
--color-on-surface-2:  #5C554D   // teks sekunder (label, placeholder)
--color-on-surface-3:  #9E9489   // teks disable / hint

--color-success:       #2E7D32
--color-warning:       #F57C00
--color-error:         #C62828
--color-info:          #1565C0

--color-success-bg:    #E8F5E9
--color-warning-bg:    #FFF3E0
--color-error-bg:      #FFEBEE
--color-info-bg:       #E3F2FD

// Overlay / Scrim
--color-scrim:         rgba(26,23,20,0.48)
```

> Dark mode token ada di section 15.

### 2.2 Tipografi

Font: **Inter** (Google Fonts, sudah tersedia di Flutter via `google_fonts`).

| Token | Size | Weight | Line Height | Pakai untuk |
|---|---|---|---|---|
| `display` | 28sp | 700 | 1.2 | Total harga di checkout, angka besar |
| `headline` | 22sp | 600 | 1.3 | Judul halaman |
| `title` | 18sp | 600 | 1.4 | Nama produk besar, header card |
| `body` | 15sp | 400 | 1.5 | Teks umum |
| `body-medium` | 15sp | 500 | 1.5 | Label form, item list |
| `caption` | 12sp | 400 | 1.4 | Keterangan kecil, timestamp |
| `label` | 13sp | 500 | 1.3 | Chip, badge, tombol kecil |

Angka harga selalu pakai **tabular nums** (`fontFeatures: [FontFeature.tabularFigures()]`) agar kolom rata.

### 2.3 Spacing & Radius

```
// Base unit: 4dp
--space-1:   4dp
--space-2:   8dp
--space-3:  12dp
--space-4:  16dp   // padding standar dalam card/form
--space-5:  20dp
--space-6:  24dp   // padding halaman
--space-8:  32dp
--space-10: 40dp

// Border Radius
--radius-sm:  8dp   // chip, badge, input
--radius-md: 12dp   // card produk, card keranjang
--radius-lg: 16dp   // bottom sheet, modal
--radius-xl: 24dp   // FAB, tombol besar
--radius-full: 999dp // pill chip
```

### 2.4 Elevasi & Shadow

```
// Pakai shadow alih-alih elevation Material default agar lebih halus
--shadow-sm: 0 1dp 3dp rgba(0,0,0,0.08)   // card produk
--shadow-md: 0 2dp 8dp rgba(0,0,0,0.12)   // bottom sheet handle, keranjang
--shadow-lg: 0 4dp 16dp rgba(0,0,0,0.16)  // modal, dialog
```

### 2.5 Ukuran Touch Target

Minimum **48×48dp** untuk semua elemen interaktif (tombol, ikon aksi, chip). Tidak ada tombol ikon telanjang di bawah 44dp.

## 3. Komponen Global

### 3.1 Tombol

| Variant | Pakai untuk | Spesifikasi |
|---|---|---|
| `ButtonPrimary` | Aksi utama (Checkout, Simpan, Bayar) | bg `primary`, teks putih, radius `xl`, height 52dp, full-width |
| `ButtonSecondary` | Aksi sekunder (Openbill, Tambah Produk) | border `primary`, teks `primary`, bg transparan, height 52dp |
| `ButtonGhost` | Aksi tersier (Batal, Lewati) | teks `on-surface-2`, bg transparan, height 44dp |
| `ButtonDanger` | Cancel order, hapus | bg `error`, teks putih, height 52dp |
| `ButtonIcon` | Ikon tunggal (edit, hapus di list) | min 48×48dp, radius `full` |

State: `default` → `hover` (opacity 0.9) → `pressed` (scale 0.97) → `disabled` (opacity 0.4).

### 3.2 Input Field

- Height: 56dp, radius `sm`, border `surface-3`, border aktif `primary` 2dp.
- Label floating (Material 3 style).
- Teks error di bawah field, warna `error`, ikon ⚠️.
- Input harga: prefix "Rp", format otomatis ribuan saat ketik.
- Password: toggle show/hide.

### 3.3 Card Produk

```
┌─────────────────┐
│  [Gambar/Emoji] │  ← aspect ratio 1:1, object-fit cover
│                 │     jika tidak ada gambar: bg surface-3 + ikon 🍵
├─────────────────┤
│ Nama Produk     │  ← title, max 2 baris, ellipsis
│ Rp 25.000       │  ← body-medium, warna primary
│ [HABIS]         │  ← chip merah jika stok 0 (opsional)
└─────────────────┘
```

Tap → tambah ke keranjang + animasi scale bounce. Long press → lihat detail.

### 3.4 Badge & Chip

- `ChipKategori`: pill, bg `surface-3`, aktif bg `primary-light` border `primary`.
- `BadgeCount`: bulat merah kecil di pojok ikon keranjang.
- `StatusChip`: `lunas` (hijau), `cancel` (merah), `pending` (oranye), `open` (biru).

### 3.5 Bottom Sheet

- Handle bar di atas, radius `lg` hanya di pojok atas.
- Background `surface`, shadow `md`.
- Dipakai untuk: detail keranjang (handset), konfirmasi aksi, pilih metode bayar.
- Drag to dismiss diaktifkan.

### 3.6 Dialog / Modal

- Radius `lg`, shadow `lg`, max width 400dp di tengah layar.
- Pakai untuk: konfirmasi cancel, konfirmasi hapus, popup langganan.
- Selalu ada tombol "Batal" (ghost) + tombol aksi (primary/danger).

### 3.7 Snackbar & Toast

- Muncul di bawah layar, di atas bottom navigation.
- Durasi: sukses 2 detik, error 4 detik (ada tombol "Coba Lagi").
- Warna: sukses `success-bg`, error `error-bg`, info `info-bg`.

### 3.8 Offline Banner

- Banner tipis kuning di bagian atas layar saat `sync_status` offline.
- Teks: "Offline — transaksi disimpan lokal, sinkron saat online".
- Hilang otomatis saat kembali online + muncul toast "Sinkronisasi selesai".

## 4. Navigasi & Layout

### 4.1 Struktur Navigasi

Navigasi utama pakai **Bottom Navigation Bar** (handset) atau **Rail Navigation** (tablet landscape).

```
Bottom Nav (handset):
  [Kasir]  [Riwayat]  [Dashboard*]  [Pengaturan]
  (* hanya tampil untuk owner & admin)

Rail Nav (tablet landscape):
  Ikon + label vertikal di sisi kiri, lebar 80dp
```

Kasir adalah tab default saat login. Tab yang tidak tersedia untuk role disembunyikan, bukan di-grey-out.

### 4.2 App Bar

- Tinggi standar 56dp.
- Judul halaman: `headline`, rata kiri.
- Ikon kanan: notifikasi (dengan badge jika ada), avatar profil.
- Di layar kasir: tidak ada app bar — seluruh layar dipakai untuk katalog + keranjang.

### 4.3 Hierarki Halaman

```
Root
├── Auth Stack (Splash → Login → Register → Lupa Sandi → Verifikasi OTP)
└── Main Shell (Bottom Nav)
    ├── Kasir
    │   ├── Layar Openbill (slide-up sheet)
    │   ├── Layar Reservasi (push)
    │   └── Layar Checkout → Layar Struk
    ├── Riwayat
    │   └── Detail Order
    ├── Dashboard (owner/admin)
    └── Pengaturan
        ├── Kelola Akun/Role
        ├── Langganan
        ├── Printer & Cash Drawer
        ├── Edit Struk
        └── Akun Saya
```

### 4.4 Transisi & Animasi

- Route push: slide dari kanan (default Material).
- Bottom sheet: slide dari bawah, 300ms ease-out.
- Dialog: fade + scale 0.95→1.0, 200ms.
- Produk masuk keranjang: bounce scale pada ikon keranjang.
- Skeleton loading: shimmer animasi pada card produk saat fetch data.
- Hindari animasi berlebihan — satu layar max satu animasi "wow".

## 5. Halaman Auth (Splash, Login, Register, Lupa Sandi)

### 5.1 Splash Screen

```
┌──────────────────────┐
│                      │
│                      │
│    [Logo BobKasir]   │  ← 96×96dp, rounded
│    BobKasir          │  ← headline, bold
│    by StarCyberCompany│  ← caption, on-surface-2
│                      │
│    v1.0.0            │  ← caption, on-surface-3, bawah
└──────────────────────┘
```

Background: `surface`. Tidak ada animasi berlebihan. Loading indicator kecil di bawah logo jika sedang cek session. Max 2 detik.

### 5.2 Login

Layout: single column, padding horizontal 24dp. Tidak ada gambar hero — clean.

```
[Logo kecil 48dp]
Selamat datang kembali    ← headline
Masuk ke akun Anda        ← body, on-surface-2

[Input Email]
[Input Password]          ← toggle show/hide

[Tombol Masuk]            ← ButtonPrimary, full-width

─── atau ───

[Masuk dengan Google]     ← ButtonSecondary + ikon Google

Belum punya akun? Daftar  ← body, link primary
Lupa sandi?               ← label, link primary
```

Validasi inline: email format, password min 8 karakter. Error muncul saat blur field, bukan saat submit.

### 5.3 Register (Owner)

Step 1 — Data Akun:
```
[Input Nama Lengkap]
[Input Email]
[Input Password]
[Input Konfirmasi Password]
[Tombol Lanjut]
[Daftar dengan Google]
```

Step 2 — Info Kedai (setelah verifikasi email):
```
[Input Nama Kedai]
[Input Alamat (opsional)]
[Input No. Telepon (opsional)]
[Tombol Selesai & Mulai]
```

Progress indicator 2 langkah di atas form.

### 5.4 Verifikasi Email

```
Cek email Anda            ← headline
Kami kirim kode ke        ← body
user@email.com            ← body-medium, bold

[OTP Input — 6 digit]     ← kotak terpisah tiap digit, focus otomatis

[Tombol Verifikasi]

Tidak dapat email?
[Kirim ulang] (countdown 60s)
```

### 5.5 Lupa Sandi

Step 1 — Input email → kirim link/OTP.
Step 2 — Input OTP 6 digit.
Step 3 — Input sandi baru + konfirmasi.

Sama strukturnya dengan verifikasi email, tidak perlu layar baru yang rumit.

## 6. Layar Kasir (Utama)

### 6.1 Layout Handset (Portrait)

```
┌────────────────────────────────┐
│ [Nama Kedai]    [Openbill(2)] [Reservasi] │  ← header bar tipis, 48dp
├────────────────────────────────┤
│ [Semua] [Klasik Kopi] [Non-Kopi] [Makanan]│  ← scroll horizontal, chip
├────────────────────────────────┤
│  [Prod]  [Prod]  [Prod]  [Prod] │
│  [Prod]  [Prod]  [Prod]  [HABIS]│  ← grid 2 kolom (handset)
│  [Prod]  [Prod]  [Prod]  [Prod] │
│                                 │
│  ↕ scroll vertikal              │
├────────────────────────────────┤
│ 🛒 3 item  •  Rp 75.000   [▲] │  ← cart summary bar, tap buka sheet
└────────────────────────────────┘
```

Cart summary bar selalu visible di bawah. Jika keranjang kosong, bar tetap ada tapi disabled dan teks "Belum ada item".

### 6.2 Bottom Sheet Keranjang (Handset)

Slide up dari cart bar. Isi:
```
── Pesanan ──────────────────────
Americano         1x  Rp 25.000
Matcha Latte      2x  Rp 50.000
─────────────────────────────────
Subtotal               Rp 75.000

[Openbill]    [Checkout →]
```

Setiap item ada tombol `−` qty, qty display, `+` qty, dan swipe-to-delete.

### 6.3 Header Bar Kasir

- Kiri: nama kedai (body-medium) + dot status offline/online (hijau/abu).
- Kanan: tombol **Openbill** (dengan badge jumlah bill aktif) + tombol **Reservasi**.
- Tidak ada judul "Kasir" — nama kedai sudah cukup sebagai konteks.

### 6.4 Grid Produk

- Handset: 2 kolom, gap 12dp.
- Tablet: 3-4 kolom tergantung lebar layar.
- Produk "HABIS": overlay semi-transparan + chip merah, tidak bisa di-tap.
- Pull-to-refresh untuk sync data produk.

## 7. Layar Checkout & Pembayaran

### 7.1 Halaman Checkout

Layout scroll vertikal, padding 24dp.

```
← Kembali          Checkout

Nama Customer  [______________]  (opsional)
Nomor Meja     [______________]  (opsional)
Keterangan     [______________]  (opsional)

── Item Pesanan ─────────────────
Americano × 1              Rp 25.000
Matcha Latte × 2           Rp 50.000
─────────────────────────────────
Total                      Rp 75.000

── Metode Pembayaran ────────────
[Tunai] [QRIS] [Debit] [E-Wallet] [+ Lainnya]
  ↑ chip horizontal scroll, satu bisa aktif

Nominal Bayar  [Rp ________]   ← muncul jika Tunai dipilih
Kembalian      Rp 25.000       ← otomatis hitung

[Split Bill]   ← tombol ghost, buka section split

── Split Bill (jika dibuka) ────
Bagian 1: [Metode] [Nominal Rp ___]
Bagian 2: [Metode] [Nominal Rp ___]
[+ Tambah Bagian]
Sisa: Rp 0 ✓  / Sisa: Rp 5.000 ⚠️

[Konfirmasi Pembayaran]   ← ButtonPrimary
```

### 7.2 Layar Struk (Setelah Bayar)

```
✓  Pembayaran Berhasil        ← ikon centang hijau besar, animasi

── Preview Struk ────────────
[Nama Kedai]
[Alamat]
...item...
Total: Rp 75.000
Bayar: Rp 100.000
Kembalian: Rp 25.000
─────────────────────────────

[Cetak Struk Customer]   ← ButtonPrimary
[Cetak Struk Dapur]      ← ButtonSecondary
[Transaksi Baru]         ← ButtonGhost (kembali ke kasir, clear cart)
```

Tombol cetak bisa ditekan berkali-kali. Tombol "Transaksi Baru" ada di paling bawah agar tidak tak sengaja tertekan.

## 8. Layar Openbill

Bottom sheet atau halaman penuh (tergantung jumlah bill). Muncul saat tap tombol "Openbill" di header kasir.

```
── Openbill Aktif (3) ───────────
┌──────────────────────────────┐
│ Meja 1  •  2 item  Rp 45.000│  [Buka]  [🗑]
└──────────────────────────────┘
┌──────────────────────────────┐
│ Meja 3  •  1 item  Rp 25.000│  [Buka]  [🗑]
└──────────────────────────────┘
┌──────────────────────────────┐
│ Tanpa nama  •  4 item        │  [Buka]  [🗑]
└──────────────────────────────┘

[+ Buat Openbill Baru]
```

- Tap **Buka** → load item ke keranjang aktif, sheet tutup.
- Tap **🗑** → konfirmasi dialog sebelum hapus.
- Label openbill bisa diedit (nama bebas, default "Tanpa nama").
- Jika keranjang sudah ada item saat buka openbill → tanya: "Gabung dengan keranjang sekarang atau ganti?"

## 9. Layar Reservasi

Halaman penuh (push dari kasir). App bar: "Reservasi" + tombol "+ Baru".

```
Filter: [Semua] [Pending] [Arrived] [Cancelled]

┌────────────────────────────────────┐
│ 🕐 14:00  Budi Santoso  •  Meja 5  │
│ "Ulang tahun, siapkan kue"         │
│ [pending]              [Konversi]  │
└────────────────────────────────────┘
┌────────────────────────────────────┐
│ 🕐 16:30  Dewi  •  Meja 2          │
│ [pending]              [Konversi]  │
└────────────────────────────────────┘
```

- Tap card → lihat detail + aksi edit/batalkan.
- Tombol **Konversi** → langsung buka keranjang dengan item reservasi (jika ada), navigasi ke kasir.
- Status chip warna: pending (oranye), arrived (hijau), cancelled (abu).

**Form Buat Reservasi (bottom sheet)**:
```
Nama Customer  [______________]
Nomor Meja     [______________]
Waktu Datang   [Date/Time Picker]
Keterangan     [______________]
[Simpan Reservasi]
```

## 10. Layar Riwayat Pesanan

App bar: "Riwayat" + ikon filter.

```
Filter bar:
[Hari ini ▾]  [Semua Kasir ▾]  [Semua Status ▾]

┌──────────────────────────────────────┐
│ #0042  •  14:23  •  Budi             │
│ Americano, Matcha Latte (+2)         │
│ Rp 75.000  [lunas]    [Detail] [🖨] │
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│ #0041  •  13:50  •  Dewi             │
│ Cappuccino                           │
│ Rp 28.000  [request cancel] [Detail]│
└──────────────────────────────────────┘
```

Badge "request cancel" warna oranye dengan teks menonjol. Filter tanggal pakai date range picker.

**Halaman Detail Order**:
```
← Kembali        Order #0042

Kasir: Budi Santoso  •  14:23, 28 Jun 2026

── Item ──────────────────────────
Americano × 1              Rp 25.000
Matcha Latte × 2           Rp 50.000
──────────────────────────────────
Total                      Rp 75.000
Bayar (Tunai)              Rp 100.000
Kembalian                  Rp 25.000

── Nama: Pak Agus  •  Meja 3

[Cetak Struk Customer]
[Cetak Struk Dapur]
[Cancel Order]   ← hanya owner/admin, merah
[Request Cancel] ← hanya kasir, jika belum cancel
```

## 11. Layar Dashboard

Hanya owner & admin. Scroll vertikal, padding 16dp.

```
Dashboard               [Export ▾]

── Ringkasan Hari Ini ───────────
┌──────────┐  ┌──────────┐
│ Rp 1,2jt │  │  24 trx  │
│ Omzet    │  │ Transaksi│
│ ↑ 12%    │  │ ↑ 3      │
└──────────┘  └──────────┘

── Grafik Omzet ─────────────────
[TabBar: Hari | Minggu | Bulan | Tahun]
[Line chart / Bar chart]

── Komparasi ────────────────────
Hari ini vs kemarin:   Rp 1,2jt vs Rp 1,07jt  ↑ 12%
Minggu ini vs lalu:    ...
Bulan ini vs lalu:     ...

── Kasir Aktif Hari Ini ─────────
Budi Santoso  •  12 transaksi  •  Rp 480rb
Dewi Rahayu   •   8 transaksi  •  Rp 320rb
```

- Kartu ringkasan: radius `md`, shadow `sm`, 2 kolom.
- Grafik: line chart untuk tren, bar chart untuk perbandingan. Library rekomendasi: `fl_chart`.
- Komparasi: angka + persentase naik/turun + ikon panah (hijau naik, merah turun).
- Tombol Export: dropdown → Gambar / PDF / Excel + filter rentang tanggal.

## 12. Layar Produk & Kategori

Hanya owner & admin. App bar: "Produk" + tombol "+ Produk".

### 12.1 Tab Kategori & Produk

```
[Kategori]  [Produk]   ← TabBar

── Tab Kategori ──────────────────
┌────────────────────────────────┐
│ ☰  Klasik Kopi          [✏️][🗑]│
└────────────────────────────────┘
┌────────────────────────────────┐
│ ☰  Non-Kopi             [✏️][🗑]│
└────────────────────────────────┘
[+ Tambah Kategori]

── Tab Produk ────────────────────
Filter: [Semua Kategori ▾]  [Cari...]

┌────┬───────────────────────────┐
│[Img│ Americano                 │
│    │ Klasik Kopi  •  Rp 25.000 │ [✏️][🗑]
└────┴───────────────────────────┘
```

### 12.2 Form Tambah/Edit Produk (halaman penuh)

```
← Kembali    Tambah Produk

[Upload Gambar]  ← kotak 120×120dp, tap buka image picker

Nama Produk  [______________]  *
Kategori     [Pilih ▾]         *
Harga        [Rp __________]  *
Keterangan   [______________]  (opsional)
Stok         [____]  ☑ Aktifkan stok  (opsional)

[Simpan]
```

Input harga: auto-format ribuan. Validasi: tidak boleh kosong, tidak boleh < 0.

## 13. Layar Pengaturan

App bar: "Pengaturan". Layout: list section dengan divider.

```
── Toko ──────────────────────────
  Kelola Akun & Role       →   (owner only)
  Langganan                →   (owner only)

── Perangkat ─────────────────────
  Printer & Cash Drawer    →
  Edit Template Struk      →   (owner & admin)

── Akun ──────────────────────────
  Profil Saya              →
  Ganti Sandi              →
  [Keluar]                     ← merah
  [Hapus Akun]                 ← merah, konfirmasi ganda
```

### 13.1 Kelola Akun & Role

List user + chip role. FAB "+ Tambah User".

```
┌──────────────────────────────────┐
│ [Avatar] Budi Santoso  [admin]   │ [Edit] [Nonaktifkan]
└──────────────────────────────────┘
┌──────────────────────────────────┐
│ [Avatar] Dewi Rahayu  [kasir]    │ [Edit] [Nonaktifkan]
└──────────────────────────────────┘
```

### 13.2 Langganan

```
Status: AKTIF  •  Berakhir 28 Jul 2026
Paket: Bulanan

[Perpanjang / Upgrade]
[Riwayat Pembayaran]
```

Jika expired: banner merah di atas + tombol "Berlangganan Sekarang" yang prominent.

### 13.3 Printer & Cash Drawer

```
Status Printer: ● Terhubung  (hijau) / ○ Putus (abu)
[Scan & Hubungkan Printer]
[Test Cetak]

Cash Drawer:  [OFF ──●]  ← toggle
[Buka Cash Drawer Manual]
```

### 13.4 Edit Template Struk

Form edit + live preview di bawah/samping (tablet: side by side).

```
Nama Kedai    [______________]
Alamat        [______________]
Keterangan    [______________]  (WiFi, dll)
Footer        [______________]
Ukuran kertas [58mm ▾ / 80mm]
Logo          [Upload] [Hapus]

── Preview ───────────────────────
[Tampilan struk preview]

[Simpan]
```

## 14. Responsif: Handset vs Tablet

Breakpoint: `< 600dp` = handset, `>= 600dp` = tablet.

| Komponen | Handset | Tablet (landscape) |
|---|---|---|
| Navigasi | Bottom Navigation Bar | Navigation Rail (kiri) |
| Kasir layout | 1 kolom, keranjang = bottom sheet | 2 kolom: katalog kiri, keranjang kanan (fixed) |
| Grid produk | 2 kolom | 3-4 kolom |
| Checkout | Full screen | Dialog/panel kanan |
| Dashboard | Scroll vertikal 1 kolom | 2 kolom: grafik + komparasi side by side |
| Edit Struk | Form + preview di bawah | Form kiri + preview kanan (side by side) |
| Dialog | Full modal | Centered dialog max 480dp |

### 14.1 Kasir Tablet (Landscape)

```
┌────────────────┬──────────────────────┐
│  Navigation    │  [Kategori chips]    │
│  Rail          ├──────────────────────┤
│  [Kasir]       │  Grid Produk         │
│  [Riwayat]     │  (3-4 kolom)         │
│  [Dashboard]   │                      │
│  [Pengaturan]  ├──────────────────────┤
│                │ Keranjang (sticky)   │
│                │ Item list + total    │
│                │ [Openbill][Checkout] │
└────────────────┴──────────────────────┘
```

Keranjang tablet selalu visible di sisi kanan, tidak perlu bottom sheet.

## 15. Dark Mode

Dark mode didukung penuh. Toggle tersedia di Pengaturan → Profil Saya (atau ikut system default).

### 15.1 Token Dark Mode

```
// Dark Mode
--color-primary:       #E6A84A   // amber lebih terang agar kontras di gelap
--color-primary-dark:  #C8892A
--color-primary-light: #3D2E10   // bg chip aktif gelap

--color-surface:       #1C1814
--color-surface-2:     #252118   // bg kasir, card
--color-surface-3:     #2F2A24   // divider, border

--color-on-surface:    #F0EDE8   // teks utama
--color-on-surface-2:  #B5AFA8   // teks sekunder
--color-on-surface-3:  #7A7470   // teks disable / hint

--color-success:       #4CAF50
--color-warning:       #FFA726
--color-error:         #EF5350
--color-info:          #42A5F5

--color-success-bg:    #1B3A1C
--color-warning-bg:    #3A2800
--color-error-bg:      #3A1010
--color-info-bg:       #0D2A4A
```

### 15.2 Catatan Implementasi

- Gunakan `ThemeData` Flutter dengan `brightness: Brightness.dark`.
- Semua warna diambil dari token — tidak ada hardcode hex di widget.
- Gambar produk: gunakan `BoxDecoration` dengan warna placeholder `surface-3` di dark mode (jangan putih).
- Grafik dashboard: pastikan warna garis kontras di background gelap.

## 16. Status & Feedback (Loading, Error, Empty State)

### 16.1 Loading

- **Skeleton screen**: tampil saat fetch data pertama kali. Pakai shimmer pada card produk, list riwayat, dashboard.
- **Inline loader**: `CircularProgressIndicator` kecil (24dp) di dalam tombol saat proses submit (disable tombol, ganti label dengan spinner).
- **Full-screen loader**: hanya untuk operasi blocking (mis: sync awal setelah login). Overlay semi-transparan + spinner + teks singkat "Memuat data...".

### 16.2 Error State

- **Network error**: ilustrasi sederhana (ikon WiFi putus) + teks "Tidak dapat terhubung" + tombol "Coba Lagi".
- **Server error (5xx)**: teks "Terjadi kesalahan, coba beberapa saat lagi" + tombol "Coba Lagi".
- **Not found**: teks sesuai konteks + link kembali.
- **Semua error**: tampil sebagai Snackbar untuk error ringan, full empty state untuk error halaman penuh.

### 16.3 Empty State

Tiap halaman punya empty state spesifik, bukan teks generik "Data tidak tersedia".

| Halaman | Teks | Aksi |
|---|---|---|
| Kasir — produk kosong | "Belum ada produk. Tambah dari menu Produk." | [+ Tambah Produk] (owner/admin) |
| Riwayat — kosong | "Belum ada transaksi hari ini." | — |
| Openbill — kosong | "Tidak ada bill yang tersimpan." | — |
| Reservasi — kosong | "Tidak ada reservasi." | [+ Buat Reservasi] |
| Notifikasi — kosong | "Semua sudah terbaca." | — |

Ilustrasi empty state: ikon line art sederhana, bukan gambar berat. Max 120×120dp. Warna `on-surface-3`.

### 16.4 Konfirmasi Aksi Berbahaya

Sebelum aksi destruktif (hapus produk, cancel order, hapus akun), selalu muncul dialog konfirmasi:
- Judul singkat: "Hapus produk ini?"
- Deskripsi dampak singkat: "Produk tidak bisa dikembalikan."
- Tombol: [Batal] (ghost) + [Hapus] (danger).
- Untuk hapus akun owner: dua langkah — dialog pertama + input ulang nama kedai.
