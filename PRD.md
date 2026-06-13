# PRD BobKasir v2.0

## 1. Informasi Dokumen

| Item            | Detail                                                                  |
| --------------- | ----------------------------------------------------------------------- |
| Nama Produk     | BobKasir                                                                |
| Jenis Produk    | Aplikasi POS Kasir untuk umum                                           |
| Dibuat oleh     | StarCyberCompany                                                        |
| Platform Utama  | Android                                                                 |
| Frontend        | Flutter                                                                 |
| Backend         | Laravel 12 REST API                                                     |
| Database Server | MySQL                                                                   |
| Local Database  | SQLite / Drift / Isar / Hive                                            |
| Payment Gateway | Midtrans                                                                |
| Email Service   | Gmail SMTP                                                              |
| Login Sosial    | Google Login                                                            |
| Target Pengguna | UMKM, kedai, toko, coffee shop, restoran kecil, booth, retail sederhana |
| Versi PRD       | 2.0                                                                     |

---

# 2. Ringkasan Produk

**BobKasir** adalah aplikasi POS kasir berbasis Flutter yang dirancang untuk membantu usaha kecil hingga menengah dalam mengelola transaksi, produk, laporan penjualan, printer struk Bluetooth, cash drawer opsional, langganan aplikasi, multi device, dan operasional kasir harian.

Aplikasi ini menggunakan **Laravel 12 API** sebagai backend dan **MySQL** sebagai database utama. Untuk mendukung operasional kasir saat koneksi internet mati, aplikasi juga wajib memiliki sistem **offline mode** dengan local database dan sinkronisasi otomatis ketika internet kembali aktif.

BobKasir memiliki 3 role utama:

1. Owner
2. Manager
3. Karyawan

Setiap role memiliki akses berbeda sesuai kebutuhan operasional.

---

# 3. Tujuan Produk

Tujuan utama BobKasir adalah membuat aplikasi kasir yang:

* Mudah dipakai oleh kasir.
* Cepat untuk transaksi harian.
* Bisa digunakan di banyak jenis usaha.
* Mendukung printer struk Bluetooth umum.
* Mendukung cash drawer otomatis secara opsional.
* Bisa tetap transaksi saat internet mati.
* Mendukung banyak device.
* Memiliki sistem role yang jelas.
* Memiliki laporan penjualan yang mudah dibaca.
* Memiliki sistem langganan otomatis via Midtrans.
* Aman untuk penggunaan bisnis harian.

---

# 4. Target Pengguna

BobKasir ditujukan untuk:

* Coffee shop
* Kedai minuman
* Warung makan
* Restoran kecil
* Booth makanan/minuman
* Toko retail
* Laundry kecil
* Barbershop sederhana
* UMKM
* Usaha rumahan
* Toko kelontong
* Tenant bazar

---

# 5. Identitas Aplikasi

BobKasir wajib memiliki identitas aplikasi yang jelas.

## 5.1 Splash Screen

Saat aplikasi dibuka, tampilkan:

* Logo BobKasir
* Nama aplikasi: **BobKasir**
* Versi aplikasi
* Identitas pembuat: **StarCyberCompany**

Contoh:

```text
BobKasir
v1.0.0

Created by StarCyberCompany
```

## 5.2 Tentang Aplikasi

Di halaman pengaturan, sediakan menu **Tentang BobKasir**.

Isi:

* Nama aplikasi
* Versi aplikasi
* Dibuat oleh StarCyberCompany
* Tahun rilis
* Kontak support opsional
* Link kebijakan privasi opsional
* Link syarat penggunaan opsional

---

# 6. Role dan Hak Akses

BobKasir memiliki 3 role:

| Role     | Deskripsi                                                                                       |
| -------- | ----------------------------------------------------------------------------------------------- |
| Owner    | Pemilik bisnis, memiliki akses penuh                                                            |
| Manager  | Pengelola operasional, memiliki akses luas tetapi tidak bisa mengelola langganan dan role utama |
| Karyawan | Operator kasir, fokus pada transaksi dan operasional harian                                     |

---

# 7. Matriks Hak Akses

| Fitur                    | Owner |  Manager |     Karyawan |
| ------------------------ | ----: | -------: | -----------: |
| Login                    |    Ya |       Ya |           Ya |
| Register mandiri         |    Ya |    Tidak |        Tidak |
| Kasir                    |    Ya |       Ya |           Ya |
| Checkout                 |    Ya |       Ya |           Ya |
| Open bill                |    Ya |       Ya |           Ya |
| Reservasi                |    Ya |       Ya |     Terbatas |
| Riwayat pesanan          |    Ya |       Ya |           Ya |
| Cetak struk customer     |    Ya |       Ya |           Ya |
| Cetak struk dapur        |    Ya |       Ya |           Ya |
| Cetak ulang struk        |    Ya |       Ya |           Ya |
| Cancel order langsung    |    Ya |       Ya |        Tidak |
| Request cancel order     |    Ya |       Ya |           Ya |
| Approve cancel order     |    Ya |       Ya |        Tidak |
| Reject cancel order      |    Ya |       Ya |        Tidak |
| Refund                   |    Ya |       Ya | Request saja |
| Dashboard                |    Ya |       Ya |        Tidak |
| Laporan                  |    Ya |       Ya |        Tidak |
| Export laporan           |    Ya |       Ya |        Tidak |
| Produk CRUD              |    Ya |       Ya |        Tidak |
| Kategori CRUD            |    Ya |       Ya |        Tidak |
| Stok produk              |    Ya |       Ya |        Tidak |
| Diskon                   |    Ya |       Ya |     Terbatas |
| Pajak dan service charge |    Ya |       Ya |        Tidak |
| Kelola role              |    Ya |    Tidak |        Tidak |
| Kelola langganan         |    Ya |    Tidak |        Tidak |
| Kelola outlet            |    Ya | Terbatas |        Tidak |
| Printer Bluetooth        |    Ya |       Ya |           Ya |
| Cash drawer              |    Ya |       Ya |           Ya |
| Edit template struk      |    Ya |       Ya |        Tidak |
| Shift kasir              |    Ya |       Ya |           Ya |
| Tutup kas                |    Ya |       Ya |           Ya |
| Kelola akun sendiri      |    Ya |       Ya |           Ya |
| Audit log                |    Ya | Terbatas |        Tidak |

---

# 8. Autentikasi

## 8.1 Login Owner

Owner dapat login dengan:

* Email dan password
* Google Login

Ketentuan:

* Login email wajib email sudah diverifikasi.
* Login Google tidak perlu verifikasi email manual.
* Jika email belum diverifikasi, tampilkan pesan verifikasi.
* Jika akun diblokir/nonaktif, login ditolak.

## 8.2 Register Owner

Owner dapat register dengan:

* Email dan password
* Google Register

Ketentuan:

* Register email wajib verifikasi via Gmail SMTP.
* Register Google tidak perlu verifikasi email manual.
* Setelah register berhasil, role otomatis menjadi **Owner**.
* Owner otomatis mendapat trial 7 hari.
* Satu email hanya boleh memiliki satu akun utama.

## 8.3 Login Manager

Manager dibuat oleh Owner.

Manager dapat login dengan:

* Email dan password
* Google Login jika email Google sama dengan email manager yang terdaftar

Ketentuan:

* Login email manager wajib email sudah diverifikasi.
* Manager tidak bisa register sendiri dari halaman umum.
* Manager tetap terhubung ke bisnis milik owner.

## 8.4 Login Karyawan

Karyawan dibuat oleh Owner.

Karyawan dapat login dengan:

* Email dan password
* Google Login jika email Google sama dengan email karyawan yang terdaftar

Ketentuan:

* Karyawan tidak wajib verifikasi email saat login agar operasional kasir tidak terhambat.
* Karyawan tidak bisa register sendiri dari halaman umum.
* Karyawan tetap terhubung ke bisnis milik owner.

## 8.5 Lupa Password

Alur:

1. User klik **Lupa Password**.
2. User memasukkan email.
3. Sistem mengirim link reset via Gmail SMTP.
4. User membuka link.
5. User membuat password baru.
6. Sistem menyimpan password baru dalam bentuk hash.
7. User login ulang.

## 8.6 Verifikasi Email

Digunakan untuk:

* Register owner via email
* Register manager via email
* Ganti email
* Reset password
* Login email owner dan manager jika belum verified

---

# 9. Alur Awal Aplikasi

## 9.1 Alur Owner Baru

1. User membuka aplikasi.
2. Splash screen tampil.
3. User masuk ke halaman login.
4. User belum punya akun.
5. User klik register.
6. User memilih register email atau Google.
7. Jika email, user wajib verifikasi email.
8. Jika Google, langsung masuk.
9. Sistem membuat akun owner.
10. Sistem membuat bisnis default.
11. Sistem mengaktifkan trial 7 hari.
12. User masuk ke halaman kasir.
13. Sistem menampilkan popup informasi trial dan langganan.

## 9.2 Popup Trial

Isi popup:

* Trial gratis 7 hari.
* Semua fitur terbuka selama trial.
* Setelah trial habis, fitur premium terkunci.
* Transaksi dasar tetap bisa digunakan.
* Tersedia paket mingguan dan bulanan.

Tombol:

* Lanjutkan Trial
* Lihat Paket Langganan

---

# 10. Sistem Langganan

## 10.1 Paket Langganan

| Paket    |     Harga | Masa Aktif |
| -------- | --------: | ---------: |
| Mingguan |  Rp30.000 |     7 hari |
| Bulanan  | Rp100.000 |    30 hari |

## 10.2 Trial

Ketentuan trial:

* Trial 7 hari.
* Hanya untuk owner baru.
* Trial hanya berlaku satu kali.
* Trial membuka semua fitur.
* Setelah trial habis, fitur premium dikunci.

## 10.3 Pembayaran Langganan

Pembayaran menggunakan Midtrans.

Metode pembayaran mengikuti Midtrans:

* QRIS
* Virtual Account
* E-wallet
* Kartu debit/kredit
* Retail payment
* Metode lain yang tersedia

## 10.4 Alur Pembayaran

1. Owner membuka menu **Langganan**.
2. Owner memilih paket.
3. Backend membuat transaksi Midtrans.
4. Aplikasi membuka halaman pembayaran.
5. Owner menyelesaikan pembayaran.
6. Midtrans mengirim webhook ke backend.
7. Backend memvalidasi signature Midtrans.
8. Backend mengecek status pembayaran.
9. Jika settlement/success, subscription aktif otomatis.
10. Aplikasi memperbarui status langganan.

## 10.5 Upgrade Langganan

Contoh:

* User sedang paket mingguan.
* User upgrade ke bulanan.
* User membayar paket bulanan.
* Setelah sukses, sistem menambahkan masa aktif bulanan.

Aturan masa aktif:

* Jika langganan lama masih aktif, sisa masa aktif ditambahkan.
* Jika langganan sudah habis, masa aktif dimulai dari tanggal pembayaran berhasil.

Contoh:

```text
Sisa paket lama: 2 hari
Beli paket bulanan: 30 hari
Total masa aktif: 32 hari
```

## 10.6 Jika Langganan Habis

Fitur yang tetap bisa digunakan:

* Login
* Kasir dasar
* Checkout cash
* Cetak struk
* Riwayat pesanan terbatas
* Pengaturan printer
* Pengaturan cash drawer
* Kelola akun sendiri
* Sinkronisasi transaksi dasar

Fitur yang dikunci:

* Dashboard lengkap
* Export laporan
* Laporan perbandingan
* CRUD produk lanjutan
* Kelola role
* Kelola outlet
* Edit struk lanjutan
* Reservasi lanjutan
* Open bill lanjutan
* Audit log detail
* Multi device tambahan jika dibatasi paket

## 10.7 Status Langganan

Status:

* Trial
* Active
* Expired
* Pending Payment
* Payment Failed
* Cancelled

---

# 11. Menu Utama Aplikasi

Menu utama:

1. Kasir
2. Riwayat Pesanan
3. Dashboard
4. Produk
5. Stok
6. Shift Kasir
7. Pengaturan

Akses menu mengikuti role.

Tampilan pertama setelah login untuk semua role adalah **Kasir**.

---

# 12. Modul Kasir

Modul kasir adalah fitur utama aplikasi.

## 12.1 Fitur Utama Kasir

* Katalog produk
* Filter kategori
* Pencarian produk
* Keranjang
* Catatan item
* Diskon item
* Diskon transaksi
* Pajak
* Service charge
* Open bill
* Reservasi
* Checkout
* Pembayaran
* Cetak struk customer
* Cetak struk dapur
* Cash drawer opsional

## 12.2 Alur Transaksi Normal

1. User membuka halaman kasir.
2. User memilih kategori.
3. User klik produk.
4. Produk masuk ke keranjang.
5. User dapat mengubah jumlah item.
6. User dapat menambah catatan item.
7. User dapat memberi diskon jika punya izin.
8. User klik checkout.
9. User mengisi data opsional:

   * nama customer,
   * nomor meja,
   * catatan pesanan.
10. User memilih metode pembayaran.
11. Sistem menghitung total.
12. User menyelesaikan pembayaran.
13. Order tersimpan.
14. Struk tampil di layar.
15. User dapat cetak struk customer dan dapur.

## 12.3 Data Opsional Checkout

Data opsional:

* Nama customer
* Nomor meja/tempat duduk
* Catatan pesanan
* Nomor HP customer
* Catatan dapur
* Catatan pembayaran

## 12.4 Metode Pembayaran Kasir

Metode yang dicatat:

* Cash
* QRIS
* Transfer
* Debit
* E-wallet
* Split payment
* Lainnya

Catatan:

* Integrasi Midtrans wajib untuk langganan.
* Integrasi Midtrans untuk pembayaran customer dapat dibuat sebagai fitur lanjutan.
* Untuk MVP, pembayaran customer cukup dicatat manual.

## 12.5 Cash Payment

Alur:

1. User pilih pembayaran cash.
2. User masukkan nominal uang diterima.
3. Sistem menghitung kembalian.
4. User klik bayar.
5. Jika cash drawer aktif, sistem mengirim perintah buka laci.
6. Sistem menampilkan struk.
7. User dapat cetak struk.

## 12.6 Split Payment

Split payment digunakan jika customer membayar dengan lebih dari satu metode.

Contoh:

* Total Rp100.000
* Cash Rp50.000
* QRIS Rp50.000

Sistem harus menyimpan detail setiap metode pembayaran.

---

# 13. Open Bill

Open bill digunakan untuk menyimpan pesanan yang belum dibayar.

## 13.1 Fitur Open Bill

* Buat open bill
* Edit open bill
* Tambah item
* Hapus item
* Ubah jumlah item
* Tambah catatan
* Simpan nama customer
* Simpan nomor meja
* Checkout open bill
* Cancel open bill sesuai izin role

## 13.2 Status Open Bill

Status:

* Open
* Updated
* Checked Out
* Cancelled

## 13.3 Ketentuan

* Open bill harus memiliki nomor unik.
* Open bill bisa dipakai saat offline.
* Open bill offline wajib disinkronkan saat online.

---

# 14. Reservasi

Reservasi digunakan untuk mencatat booking customer.

## 14.1 Data Reservasi

* Nama customer
* Nomor HP
* Tanggal reservasi
* Jam reservasi
* Jumlah orang
* Nomor meja/tempat
* Catatan
* Status reservasi

## 14.2 Status Reservasi

* Pending
* Confirmed
* Arrived
* Completed
* Cancelled
* No Show

## 14.3 Hak Akses Reservasi

| Aksi             | Owner | Manager | Karyawan |
| ---------------- | ----: | ------: | -------: |
| Lihat reservasi  |    Ya |      Ya |       Ya |
| Tambah reservasi |    Ya |      Ya | Terbatas |
| Edit reservasi   |    Ya |      Ya |    Tidak |
| Cancel reservasi |    Ya |      Ya |  Request |
| Tandai arrived   |    Ya |      Ya |       Ya |

---

# 15. Diskon, Pajak, dan Service Charge

## 15.1 Diskon

Jenis diskon:

* Diskon nominal
* Diskon persentase
* Diskon item
* Diskon transaksi

Contoh:

```text
Diskon nominal: Rp10.000
Diskon persentase: 10%
```

## 15.2 Hak Akses Diskon

| Aksi            | Owner | Manager | Karyawan |
| --------------- | ----: | ------: | -------: |
| Buat diskon     |    Ya |      Ya |    Tidak |
| Terapkan diskon |    Ya |      Ya | Terbatas |
| Hapus diskon    |    Ya |      Ya |    Tidak |

Karyawan boleh menggunakan diskon hanya jika diskon tersebut sudah dibuat oleh owner/manager.

## 15.3 Pajak

Sistem mendukung pajak opsional.

Contoh:

* PPN 10%
* Pajak restoran 10%
* Pajak custom

Pajak dapat diaktifkan atau dimatikan.

## 15.4 Service Charge

Sistem mendukung service charge opsional.

Contoh:

* Service charge 5%
* Service charge 10%
* Service custom

Service charge dapat diaktifkan atau dimatikan.

## 15.5 Urutan Perhitungan Total

Rekomendasi urutan:

```text
Subtotal item
- Diskon item
= Subtotal setelah diskon item
- Diskon transaksi
= Subtotal setelah diskon
+ Pajak
+ Service charge
= Grand total
```

---

# 16. Modul Riwayat Pesanan

Riwayat pesanan berlaku untuk semua role.

## 16.1 Data Riwayat

Data yang ditampilkan:

* Nomor order
* Tanggal dan jam
* Nama customer
* Nomor meja
* Nama kasir
* Role kasir
* Device
* Total transaksi
* Metode pembayaran
* Status order
* Status pembayaran
* Status sync
* Tombol cetak ulang
* Tombol request cancel/cancel

## 16.2 Status Order

Status order:

* Completed
* Cancel Requested
* Cancelled
* Refund Requested
* Refunded
* Pending Sync
* Synced
* Failed Sync

## 16.3 Cetak Ulang Struk

Semua role bisa cetak ulang:

* Struk customer
* Struk dapur

Cetak ulang bisa dilakukan berkali-kali.

Sistem wajib mencatat:

* Siapa yang mencetak ulang
* Waktu cetak ulang
* Jenis struk
* Nomor order

## 16.4 Cancel Order Owner/Manager

Alur:

1. Owner/manager buka riwayat.
2. Pilih order.
3. Klik cancel.
4. Isi alasan.
5. Sistem mengubah status order menjadi cancelled.
6. Sistem mencatat audit log.
7. Laporan diperbarui.

## 16.5 Cancel Order Karyawan

Alur:

1. Karyawan buka riwayat.
2. Pilih order.
3. Klik request cancel.
4. Karyawan wajib isi alasan.
5. Sistem mengirim notifikasi ke owner dan manager.
6. Owner/manager menyetujui atau menolak.
7. Jika disetujui, order cancelled.
8. Jika ditolak, order tetap completed.

## 16.6 Monitoring Karyawan

Owner dan manager bisa melihat transaksi berdasarkan:

* Nama karyawan
* Role
* Device
* Shift
* Tanggal
* Jam
* Outlet
* Status order
* Status cancel

Tujuan:

* Melacak siapa yang memegang kasir.
* Melacak kesalahan input.
* Melihat performa kasir.
* Mengetahui siapa yang melakukan cancel/refund.

---

# 17. Refund

Refund berbeda dari cancel.

Cancel digunakan untuk membatalkan order. Refund digunakan untuk pengembalian dana setelah transaksi sudah selesai.

## 17.1 Jenis Refund

* Full refund
* Partial refund

## 17.2 Hak Akses Refund

| Aksi           | Owner | Manager | Karyawan |
| -------------- | ----: | ------: | -------: |
| Full refund    |    Ya |      Ya |  Request |
| Partial refund |    Ya |      Ya |  Request |
| Approve refund |    Ya |      Ya |    Tidak |
| Reject refund  |    Ya |      Ya |    Tidak |

## 17.3 Alur Refund Karyawan

1. Karyawan memilih order.
2. Klik request refund.
3. Isi alasan.
4. Pilih full/partial refund.
5. Owner/manager menerima notifikasi.
6. Owner/manager approve/reject.
7. Jika approve, status order diperbarui.
8. Sistem mencatat audit log.

---

# 18. Dashboard

Dashboard hanya untuk owner dan manager.

## 18.1 Isi Dashboard

* Total penjualan hari ini
* Total transaksi hari ini
* Total refund
* Total cancel
* Produk terlaris
* Kategori terlaris
* Metode pembayaran terbanyak
* Rata-rata nilai transaksi
* Grafik penjualan
* Perbandingan penjualan
* Aktivitas kasir
* Status sinkronisasi

## 18.2 Perbandingan Laporan

Sistem mendukung:

* Hari ini vs kemarin
* Minggu ini vs minggu lalu
* Bulan ini vs bulan lalu
* Tahun ini vs tahun lalu
* Custom date range

## 18.3 Export Laporan

Laporan bisa:

* Dicetak via printer struk Bluetooth
* Diunduh PDF
* Diunduh Excel
* Diunduh gambar

Jenis laporan:

* Harian
* Mingguan
* Bulanan
* Tahunan
* Custom range
* Per kasir
* Per outlet
* Per produk
* Per metode pembayaran

---

# 19. Produk dan Kategori

## 19.1 Kategori

Owner dan manager bisa CRUD kategori.

Data kategori:

* Nama kategori
* Deskripsi opsional
* Urutan tampilan
* Status aktif/nonaktif

## 19.2 Produk

Owner dan manager bisa CRUD produk.

Data produk:

* Nama produk
* Kategori
* Harga
* Modal produk opsional
* Stok opsional
* SKU opsional
* Barcode opsional
* Gambar opsional
* Keterangan opsional
* Status aktif/nonaktif

## 19.3 Format Harga

Input harga harus fleksibel.

Input valid:

```text
50000
Rp50000
Rp50.000
50.000
```

Sistem menyimpan sebagai integer:

```text
50000
```

Tampilan:

```text
Rp50.000
```

## 19.4 Gambar Produk

Gambar produk bersifat opsional.

Penyimpanan:

* Server storage sebagai sumber utama.
* Cache lokal untuk mempercepat loading.

Jika gambar kosong, tampilkan placeholder.

## 19.5 Hapus Produk

Produk yang sudah pernah masuk transaksi tidak boleh dihapus permanen.

Solusi:

* Gunakan status nonaktif.
* Produk tidak tampil di kasir.
* Riwayat transaksi lama tetap aman.

---

# 20. Manajemen Stok

Stok bersifat opsional karena tidak semua bisnis butuh stok.

## 20.1 Mode Stok

Pilihan:

* Stok nonaktif
* Stok aktif per produk
* Stok aktif semua produk

## 20.2 Fitur Stok

* Input stok awal
* Tambah stok
* Kurangi stok
* Koreksi stok
* Stok minimum
* Notifikasi stok menipis
* Riwayat perubahan stok

## 20.3 Pengurangan Stok

Stok berkurang saat:

* Transaksi selesai
* Transaksi offline berhasil dibuat

Jika transaksi dicancel:

* Stok dapat dikembalikan sesuai pengaturan.

Jika refund:

* Stok dapat dikembalikan jika barang kembali.

## 20.4 Stok Saat Offline

Saat offline:

* Stok lokal berkurang.
* Perubahan stok masuk sync queue.
* Saat online, stok disinkronkan ke server.

Jika ada konflik stok:

* Transaksi tetap disimpan.
* Sistem memberi tanda konflik.
* Owner/manager dapat melakukan koreksi stok.

---

# 21. Shift Kasir

Shift kasir digunakan untuk mencatat sesi kerja kasir.

## 21.1 Buka Shift

Karyawan/manager/owner dapat membuka shift.

Data buka shift:

* Nama user
* Role
* Device
* Outlet
* Waktu buka shift
* Modal awal kas
* Catatan opsional

## 21.2 Tutup Shift

Saat tutup shift, sistem menampilkan:

* Modal awal
* Total cash
* Total QRIS
* Total transfer
* Total debit
* Total e-wallet
* Total transaksi
* Total cancel
* Total refund
* Total uang seharusnya
* Uang fisik yang dihitung
* Selisih kas
* Catatan tutup shift

## 21.3 Cetak Laporan Shift

Laporan shift bisa:

* Dicetak via printer struk
* Diunduh PDF
* Dilihat di dashboard

## 21.4 Ketentuan Shift

* Transaksi sebaiknya terhubung ke shift aktif.
* Jika user belum buka shift, tampilkan peringatan.
* Owner bisa mengizinkan transaksi tanpa shift melalui pengaturan.

---

# 22. Printer Bluetooth

BobKasir harus mendukung printer struk Bluetooth umum.

## 22.1 Fitur Printer

* Scan perangkat Bluetooth
* Pair/connect printer
* Simpan printer default
* Putuskan koneksi
* Reconnect otomatis
* Test cetak
* Cetak struk customer
* Cetak struk dapur
* Cetak laporan
* Cetak ulang struk

## 22.2 Ukuran Kertas

Dukung ukuran:

* 58mm
* 80mm

Pengaturan:

* Lebar kertas
* Jumlah karakter per baris
* Font kecil/sedang/besar
* Auto cut jika didukung printer
* Feed paper setelah cetak

## 22.3 Hak Akses Printer

Semua role dapat:

* Scan printer
* Hubungkan printer
* Test cetak
* Cetak struk

Karyawan diberi akses printer agar jika printer error saat operasional, karyawan dapat menyambungkan ulang tanpa menunggu owner/manager.

---

# 23. Cash Drawer

Cash drawer bersifat opsional.

## 23.1 Cara Kerja

Cash drawer umumnya terhubung ke printer struk melalui port RJ11/RJ12. Aplikasi mengirim perintah ESC/POS ke printer, lalu printer mengirim sinyal untuk membuka cash drawer.

## 23.2 Pengaturan Cash Drawer

Pilihan:

| Mode                 | Fungsi                                   |
| -------------------- | ---------------------------------------- |
| Off                  | Cash drawer dimatikan                    |
| Auto on Cash Payment | Terbuka otomatis setelah pembayaran cash |
| Manual Only          | Hanya terbuka lewat tombol manual        |
| Always Ask           | Sistem bertanya setelah checkout         |

Default:

```text
Cash Drawer: Off
```

## 23.3 Test Cash Drawer

Owner, manager, dan karyawan dapat test cash drawer jika fitur diaktifkan.

Semua aktivitas buka cash drawer dicatat:

* User
* Role
* Device
* Waktu
* Mode buka
* Alasan jika manual

---

# 24. Edit Struk

## 24.1 Data Struk

Owner dan manager dapat mengatur:

* Nama kedai
* Alamat
* Nomor HP
* Footer struk
* Password WiFi
* Logo teks
* Nomor meja tampil/sembunyi
* Nama customer tampil/sembunyi
* Nama kasir tampil/sembunyi
* Pajak tampil/sembunyi
* Service charge tampil/sembunyi

## 24.2 Jenis Struk

BobKasir mendukung:

1. Struk customer
2. Struk dapur
3. Struk laporan
4. Struk tutup shift

## 24.3 Struk Customer

Isi:

* Nama kedai
* Alamat
* Nomor order
* Tanggal dan jam
* Nama kasir
* Nama customer opsional
* Nomor meja opsional
* Daftar item
* Subtotal
* Diskon
* Pajak
* Service charge
* Grand total
* Metode pembayaran
* Uang diterima
* Kembalian
* Footer

## 24.4 Struk Dapur

Isi:

* Nomor order
* Tanggal dan jam
* Nomor meja
* Nama customer opsional
* Nama kasir
* Daftar item
* Catatan item
* Catatan pesanan

Struk dapur tidak perlu menampilkan harga.

---

# 25. Multi Device

BobKasir harus mendukung banyak device.

## 25.1 Ketentuan

* Owner bisa login di HP pribadi.
* Manager bisa login di tablet.
* Karyawan bisa login di HP kasir.
* Banyak karyawan bisa transaksi bersamaan.
* Semua transaksi tetap masuk ke bisnis yang sama.

## 25.2 Device Tracking

Setiap device menyimpan:

* Device ID
* Nama device
* User terakhir
* Waktu login
* App version
* Status aktif
* Printer default lokal

## 25.3 Nomor Order

Nomor order server:

```text
BK-YYYYMMDD-0001
```

Contoh:

```text
BK-20260610-0001
```

Nomor order offline sementara:

```text
BK-OFFLINE-DEVICEID-TIMESTAMP
```

Saat online, server memberikan nomor order final.

---

# 26. Offline Mode dan Sinkronisasi

BobKasir wajib tetap bisa transaksi saat internet mati.

## 26.1 Fitur yang Berjalan Offline

* Melihat produk cache lokal
* Melihat kategori cache lokal
* Membuat transaksi
* Checkout
* Cetak struk
* Open bill lokal
* Riwayat lokal
* Request cancel lokal
* Shift kasir lokal
* Pengaturan printer lokal

## 26.2 Fitur yang Butuh Online

* Login pertama kali
* Google Login
* Verifikasi email
* Pembayaran Midtrans
* Update langganan
* Kelola role baru
* Download laporan server
* Export laporan lengkap
* Sinkronisasi data
* Update produk dari server

## 26.3 Alur Offline

1. Internet mati.
2. Aplikasi menampilkan status **Offline Mode**.
3. Kasir tetap transaksi.
4. Data disimpan di local database.
5. Data masuk sync queue.
6. Status transaksi: **Belum Sinkron**.
7. Saat internet kembali, aplikasi sinkron otomatis.
8. Jika berhasil, status menjadi **Tersinkron**.
9. Jika gagal, status menjadi **Gagal Sinkron**.
10. User dapat klik **Coba Sinkron Ulang**.

## 26.4 Sync Queue

Data yang masuk queue:

* Transaksi
* Order item
* Pembayaran
* Open bill
* Cancel request
* Refund request
* Shift
* Perubahan stok
* Audit log lokal

## 26.5 Idempotency

Setiap request sinkronisasi wajib memiliki:

* local_id
* device_id
* sync_id
* timestamp

Tujuannya agar transaksi tidak dobel saat retry.

## 26.6 Konflik Data

Aturan:

* Transaksi tidak boleh hilang.
* Transaksi tidak boleh tertimpa.
* Server menjadi sumber data utama.
* Data offline tetap dikirim ke server.
* Jika konflik stok, transaksi tetap masuk tetapi diberi tanda perlu review.
* Jika produk sudah dinonaktifkan saat offline, transaksi lama tetap diterima dengan catatan audit.

---

# 27. Pengaturan

## 27.1 Pengaturan Owner

Owner dapat mengakses:

* Kelola akun sendiri
* Kelola role
* Kelola langganan
* Kelola outlet
* Printer Bluetooth
* Cash drawer
* Edit struk
* Pajak dan service charge
* Diskon
* Tentang aplikasi
* Logout

## 27.2 Pengaturan Manager

Manager dapat mengakses:

* Kelola akun sendiri
* Printer Bluetooth
* Cash drawer
* Edit struk
* Pajak dan service charge
* Diskon
* Tentang aplikasi
* Logout

Manager tidak dapat mengakses:

* Kelola role
* Kelola langganan
* Data owner

## 27.3 Pengaturan Karyawan

Karyawan dapat mengakses:

* Kelola akun sendiri
* Printer Bluetooth
* Cash drawer
* Test cetak
* Tentang aplikasi
* Logout

Karyawan tidak dapat mengakses:

* Langganan
* Kelola role
* Produk
* Dashboard
* Edit struk
* Pajak
* Service charge
* Diskon master

---

# 28. Kelola Akun Sendiri

Semua role dapat:

* Edit nama
* Edit foto profil opsional
* Ganti password
* Reset password
* Ganti email
* Logout

Ketentuan:

* Ganti email wajib verifikasi email baru.
* Reset password wajib verifikasi.
* Perubahan data akun tidak mengubah role.
* Akun manager/karyawan tetap terhubung ke owner walaupun email/nama berubah.

---

# 29. Kelola Role

Hanya owner yang dapat mengelola role.

## 29.1 Fitur

Owner dapat:

* Tambah manager
* Tambah karyawan
* Edit data manager
* Edit data karyawan
* Nonaktifkan akun
* Aktifkan akun
* Reset password akun
* Lihat aktivitas akun
* Hapus akses akun dari bisnis

## 29.2 Status Akun

* Aktif
* Nonaktif
* Menunggu verifikasi
* Diblokir

## 29.3 Ketentuan

* Manager bisa lebih dari satu.
* Karyawan bisa banyak.
* Manager dan karyawan tidak bisa membuat akun baru sendiri.
* Owner bisa mencabut akses manager/karyawan kapan saja.

---

# 30. Multi Outlet

Multi outlet dapat dibuat sebagai fitur lanjutan, tetapi struktur database harus disiapkan dari awal.

## 30.1 Konsep

Satu owner bisa memiliki:

* Satu bisnis
* Banyak outlet/cabang

Contoh:

```text
Bob Coffee
- Outlet 1: Surabaya
- Outlet 2: Sidoarjo
- Outlet 3: Malang
```

## 30.2 Hak Akses Outlet

* Owner bisa melihat semua outlet.
* Manager bisa dibatasi per outlet.
* Karyawan hanya melihat outlet tempat dia bekerja.

---

# 31. Audit Log

Sistem wajib mencatat aktivitas penting.

## 31.1 Data Audit Log

* User ID
* Nama user
* Role
* Business ID
* Outlet ID
* Device ID
* Aktivitas
* Data sebelum
* Data sesudah
* IP address jika tersedia
* Waktu

## 31.2 Aktivitas yang Dicatat

* Login
* Logout
* Register
* Verifikasi email
* Tambah produk
* Edit produk
* Nonaktif produk
* Checkout
* Cetak ulang struk
* Request cancel
* Approve cancel
* Reject cancel
* Request refund
* Approve refund
* Reject refund
* Buka cash drawer
* Buka shift
* Tutup shift
* Ubah role
* Ubah langganan
* Ubah struk
* Sinkronisasi offline

---

# 32. Notifikasi

## 32.1 Jenis Notifikasi

* Request cancel order
* Request refund
* Trial hampir habis
* Trial habis
* Langganan hampir habis
* Langganan habis
* Pembayaran berhasil
* Pembayaran gagal
* Stok menipis
* Sinkronisasi gagal

## 32.2 Penerima Notifikasi

| Notifikasi     | Owner | Manager |         Karyawan |
| -------------- | ----: | ------: | ---------------: |
| Request cancel |    Ya |      Ya |            Tidak |
| Request refund |    Ya |      Ya |            Tidak |
| Langganan      |    Ya |   Tidak |            Tidak |
| Stok menipis   |    Ya |      Ya |            Tidak |
| Sync gagal     |    Ya |      Ya | Ya sesuai device |

---

# 33. Backend API

Backend menggunakan Laravel 12 REST API.

## 33.1 Modul API

* Auth API
* Google Auth API
* Email Verification API
* Password Reset API
* User API
* Role API
* Business API
* Outlet API
* Subscription API
* Midtrans API
* Category API
* Product API
* Stock API
* Order API
* Payment API
* Open Bill API
* Reservation API
* Cancel Order API
* Refund API
* Dashboard API
* Report API
* Shift API
* Receipt Setting API
* Printer Setting API
* Cash Drawer Setting API
* Sync API
* Audit Log API
* Notification API

## 33.2 Format Response API

Sukses:

```json
{
  "success": true,
  "message": "Data berhasil disimpan",
  "data": {}
}
```

Gagal:

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {}
}
```

---

# 34. Endpoint API Minimum

## 34.1 Auth

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/google
POST /api/auth/logout
POST /api/auth/forgot-password
POST /api/auth/reset-password
POST /api/auth/verify-email
POST /api/auth/resend-verification
GET  /api/auth/me
```

## 34.2 Subscription

```text
GET  /api/subscription/status
GET  /api/subscription/plans
POST /api/subscription/checkout
POST /api/midtrans/webhook
GET  /api/subscription/history
```

## 34.3 Role

```text
GET    /api/users
POST   /api/users/manager
POST   /api/users/employee
PUT    /api/users/{id}
PATCH  /api/users/{id}/activate
PATCH  /api/users/{id}/deactivate
DELETE /api/users/{id}/access
```

## 34.4 Product

```text
GET    /api/categories
POST   /api/categories
PUT    /api/categories/{id}
DELETE /api/categories/{id}

GET    /api/products
POST   /api/products
GET    /api/products/{id}
PUT    /api/products/{id}
PATCH  /api/products/{id}/status
DELETE /api/products/{id}
```

## 34.5 Order

```text
GET  /api/orders
POST /api/orders
GET  /api/orders/{id}
POST /api/orders/{id}/print-log
POST /api/orders/{id}/cancel-request
POST /api/orders/{id}/cancel-approve
POST /api/orders/{id}/cancel-reject
POST /api/orders/{id}/refund-request
POST /api/orders/{id}/refund-approve
POST /api/orders/{id}/refund-reject
```

## 34.6 Dashboard dan Report

```text
GET /api/dashboard/summary
GET /api/reports/daily
GET /api/reports/weekly
GET /api/reports/monthly
GET /api/reports/yearly
GET /api/reports/custom
GET /api/reports/export/pdf
GET /api/reports/export/excel
GET /api/reports/export/image
```

## 34.7 Shift

```text
POST /api/shifts/open
POST /api/shifts/close
GET  /api/shifts/current
GET  /api/shifts/history
GET  /api/shifts/{id}
```

## 34.8 Sync

```text
POST /api/sync/push
GET  /api/sync/pull
POST /api/sync/retry
GET  /api/sync/status
```

---

# 35. Database MySQL

## 35.1 Tabel Minimum

* users
* businesses
* outlets
* roles
* user_business_roles
* devices
* subscriptions
* subscription_plans
* subscription_payments
* email_verifications
* password_resets
* categories
* products
* product_images
* stocks
* stock_movements
* discounts
* taxes
* service_charges
* orders
* order_items
* payments
* open_bills
* open_bill_items
* reservations
* cancel_requests
* refund_requests
* shifts
* shift_payments
* receipt_settings
* printer_settings
* cashdrawer_settings
* audit_logs
* notifications
* sync_logs

## 35.2 Relasi Utama

* User bisa terhubung ke bisnis.
* Business bisa punya banyak outlet.
* Outlet punya banyak produk, transaksi, shift.
* Order dibuat oleh user.
* Order punya banyak item.
* Order punya banyak payment jika split payment.
* Order bisa punya cancel request.
* Order bisa punya refund request.
* Product punya stock.
* Stock punya stock movement.
* Shift punya banyak order.
* Subscription terhubung ke owner/business.

---

# 36. Struktur Tabel Penting

## 36.1 users

Field utama:

* id
* name
* email
* password
* google_id
* email_verified_at
* phone
* avatar
* status
* created_at
* updated_at

## 36.2 businesses

Field utama:

* id
* owner_id
* name
* address
* phone
* status
* created_at
* updated_at

## 36.3 orders

Field utama:

* id
* business_id
* outlet_id
* user_id
* shift_id
* device_id
* order_number
* local_order_id
* customer_name
* table_number
* note
* subtotal
* discount_total
* tax_total
* service_charge_total
* grand_total
* paid_amount
* change_amount
* payment_status
* order_status
* sync_status
* ordered_at
* created_at
* updated_at

## 36.4 order_items

Field utama:

* id
* order_id
* product_id
* product_name_snapshot
* price_snapshot
* qty
* discount
* note
* subtotal
* created_at
* updated_at

## 36.5 payments

Field utama:

* id
* order_id
* method
* amount
* reference_number
* status
* paid_at
* created_at
* updated_at

## 36.6 subscriptions

Field utama:

* id
* business_id
* owner_id
* plan
* status
* started_at
* expired_at
* trial_started_at
* trial_expired_at
* created_at
* updated_at

## 36.7 audit_logs

Field utama:

* id
* business_id
* outlet_id
* user_id
* role
* device_id
* action
* table_name
* record_id
* old_data
* new_data
* ip_address
* created_at

---

# 37. UI/UX

## 37.1 Prinsip Desain

Desain harus:

* Bersih
* Natural
* Tidak terlalu ramai
* Mudah dipahami
* Cocok untuk penggunaan cepat
* Tombol utama mudah dijangkau
* Warna tidak berlebihan
* Responsif di HP dan tablet
* Tidak memakai elemen dekoratif yang tidak berguna

## 37.2 Halaman Kasir

Prioritas halaman kasir:

1. Produk mudah dicari.
2. Kategori mudah dipilih.
3. Keranjang mudah dibaca.
4. Checkout cepat.
5. Tombol cetak jelas.
6. Error mudah dipahami.

## 37.3 State UI

Setiap halaman wajib punya state:

* Loading
* Empty
* Error
* Success
* Offline
* Syncing
* Synced
* Failed sync

Contoh offline state:

```text
Koneksi internet terputus.
Transaksi tetap bisa berjalan dan akan disinkronkan otomatis saat online.
```

Contoh empty produk:

```text
Belum ada produk.
Tambahkan produk pertama untuk mulai berjualan.
```

---

# 38. Keamanan

## 38.1 Akun

* Password wajib di-hash.
* Token API harus aman.
* Role dicek di backend.
* Endpoint wajib memakai middleware auth.
* Owner, manager, dan karyawan hanya bisa akses data bisnisnya.
* User nonaktif tidak bisa login.

## 38.2 Midtrans

* Webhook wajib divalidasi.
* Status pembayaran tidak boleh hanya dari frontend.
* Signature Midtrans wajib dicek.
* Langganan aktif hanya jika pembayaran berhasil.

## 38.3 Data

* Data bisnis tidak boleh bocor ke bisnis lain.
* Karyawan tidak boleh akses dashboard.
* Manager tidak boleh akses langganan owner.
* Semua aktivitas penting masuk audit log.

---

# 39. Aturan Bisnis

## 39.1 Transaksi

* Transaksi selesai tidak boleh dihapus permanen.
* Kesalahan transaksi memakai cancel/refund.
* Cancel harus punya alasan.
* Refund harus punya alasan.
* Karyawan wajib request cancel/refund.
* Cetak ulang struk harus dicatat.

## 39.2 Produk

* Produk yang sudah pernah dijual tidak boleh dihapus permanen.
* Produk lama di transaksi tetap memakai harga snapshot.
* Perubahan harga produk tidak mengubah transaksi lama.

## 39.3 Stok

* Stok bisa aktif/nonaktif.
* Stok berkurang saat transaksi.
* Cancel/refund bisa mengembalikan stok sesuai pengaturan.
* Perubahan stok harus punya riwayat.

## 39.4 Langganan

* Trial hanya sekali.
* Trial 7 hari.
* Paket mingguan 7 hari.
* Paket bulanan 30 hari.
* Jika expired, fitur premium terkunci.
* Transaksi dasar tetap bisa berjalan.

## 39.5 Offline

* Transaksi offline tidak boleh hilang.
* Transaksi offline harus punya ID unik.
* Sinkronisasi tidak boleh membuat data dobel.
* Jika sync gagal, user bisa retry.

---

# 40. Acceptance Criteria

## 40.1 Auth

* Owner bisa register email.
* Owner menerima email verifikasi.
* Owner bisa register Google tanpa verifikasi manual.
* Owner login email hanya jika email verified.
* Manager bisa login setelah dibuat owner.
* Karyawan bisa login tanpa verifikasi email yang menghambat operasional.
* Reset password berjalan via Gmail SMTP.

## 40.2 Langganan

* Owner mendapat trial 7 hari.
* Owner bisa memilih paket mingguan.
* Owner bisa memilih paket bulanan.
* Pembayaran dibuat via Midtrans.
* Webhook Midtrans mengaktifkan langganan.
* Jika langganan expired, fitur premium terkunci.

## 40.3 Kasir

* User bisa memilih produk.
* Produk masuk keranjang.
* User bisa checkout.
* User bisa bayar cash.
* Sistem menghitung kembalian.
* Struk tampil setelah checkout.
* Struk customer dan dapur bisa dicetak berkali-kali.

## 40.4 Riwayat Pesanan

* Semua role bisa melihat riwayat.
* Semua role bisa cetak ulang struk.
* Owner dan manager bisa cancel langsung.
* Karyawan hanya request cancel.
* Owner/manager bisa approve/reject.
* Nama kasir tercatat di transaksi.

## 40.5 Dashboard

* Owner dan manager bisa melihat grafik.
* Laporan harian tersedia.
* Laporan mingguan tersedia.
* Laporan bulanan tersedia.
* Laporan tahunan tersedia.
* Perbandingan periode tersedia.
* Export PDF/Excel/gambar tersedia.

## 40.6 Produk dan Stok

* Owner/manager bisa CRUD kategori.
* Owner/manager bisa CRUD produk.
* Harga bisa diinput fleksibel.
* Gambar produk opsional.
* Stok bisa aktif/nonaktif.
* Riwayat stok tercatat.

## 40.7 Shift

* User bisa buka shift.
* User bisa tutup shift.
* Sistem menghitung total pembayaran.
* Sistem menghitung selisih kas.
* Laporan shift bisa dicetak.

## 40.8 Printer dan Cash Drawer

* User bisa scan printer.
* User bisa connect printer.
* User bisa test cetak.
* User bisa cetak struk.
* User bisa pilih 58mm/80mm.
* Cash drawer bisa on/off.
* Cash drawer bisa auto open saat cash.

## 40.9 Offline

* Transaksi bisa dibuat saat offline.
* Transaksi tersimpan lokal.
* Transaksi punya status belum sinkron.
* Saat online, transaksi sinkron otomatis.
* Sync tidak membuat transaksi dobel.

---

# 41. Prioritas Pengembangan

## 41.1 MVP Wajib

Fitur wajib versi pertama:

* Splash screen
* Login/register owner
* Verifikasi email
* Google Login
* Trial 7 hari
* Langganan Midtrans
* Role owner, manager, karyawan
* Kelola role
* Kasir
* Checkout cash
* Riwayat pesanan
* Cancel request
* Cetak struk Bluetooth
* Produk dan kategori
* Shift kasir
* Pengaturan struk sederhana
* Cash drawer on/off
* Offline transaksi dasar
* Sync transaksi
* Dashboard dasar

## 41.2 Versi Lanjutan

Fitur lanjutan:

* Reservasi lengkap
* Open bill lanjutan
* Multi outlet
* Stok advanced
* Export laporan
* Promo dan voucher
* Kitchen display system
* Integrasi payment customer
* Loyalty customer
* Backup cloud
* Analitik lanjutan

---

# 42. Rekomendasi Struktur Flutter

Gunakan struktur feature-based.

Contoh:

```text
lib/
  core/
    constants/
    helpers/
    network/
    storage/
    theme/
    widgets/
  features/
    auth/
    cashier/
    orders/
    products/
    dashboard/
    subscription/
    settings/
    sync/
    shift/
    printer/
  main.dart
```

State management dapat memakai:

* Riverpod
* Bloc
* Provider

Rekomendasi:

```text
Riverpod atau Bloc
```

Untuk aplikasi POS yang cukup besar, struktur harus rapi sejak awal.

---

# 43. Rekomendasi Struktur Laravel

Contoh:

```text
app/
  Http/
    Controllers/
    Requests/
    Resources/
  Models/
  Services/
  Repositories/
  Policies/
  Jobs/
  Events/
  Listeners/
  Notifications/
routes/
  api.php
database/
  migrations/
  seeders/
```

Gunakan:

* Form Request untuk validasi.
* Service layer untuk logic.
* Policy/middleware untuk role permission.
* Job queue untuk email dan proses berat.
* Event listener untuk audit log.

---

# 44. Environment Backend

File `.env` backend minimal:

```env
APP_NAME=BobKasir
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bobkasir
DB_USERNAME=root
DB_PASSWORD=

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME="BobKasir"

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=

MIDTRANS_SERVER_KEY=
MIDTRANS_CLIENT_KEY=
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_MERCHANT_ID=
```

---

# 45. Definisi Selesai

Sebuah fitur dianggap selesai jika:

* UI sudah berjalan.
* API sudah berjalan.
* Validasi backend ada.
* Role permission benar.
* Error handling ada.
* Loading state ada.
* Empty state ada.
* Data tersimpan benar.
* Audit log tersedia untuk fitur penting.
* Offline behavior jelas jika fitur terkait kasir.
* Sudah dites minimal pada skenario normal dan skenario gagal.

---

# 46. Kesimpulan

BobKasir adalah aplikasi POS kasir untuk umum yang dibuat dengan Flutter, Laravel 12 API, dan MySQL. Aplikasi ini dirancang untuk mendukung transaksi cepat, role owner/manager/karyawan, printer struk Bluetooth, cash drawer opsional, langganan Midtrans, verifikasi email via Gmail SMTP, Google Login, dashboard laporan, produk, stok, shift kasir, refund, cancel order, multi device, dan offline mode.

Fokus utama BobKasir adalah aplikasi yang stabil, ringan, mudah dipakai, aman, dan tetap bisa digunakan saat koneksi internet bermasalah.

Identitas aplikasi wajib mencantumkan:

```text
Created by StarCyberCompany
```

BobKasir harus dibangun dengan struktur kode yang rapi agar mudah dikembangkan menjadi aplikasi POS yang matang dan siap dipakai banyak jenis usaha.
