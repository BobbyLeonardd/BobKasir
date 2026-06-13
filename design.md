# **Dokumen Desain UI/UX (Design System) BobKasir v2.0 \- Premium Edition**

## **1\. Informasi Dokumen**

| Item | Detail |
| :---- | :---- |
| Nama Produk | BobKasir |
| Dibuat oleh | StarCyberCompany |
| Platform | Android (Smartphone & Tablet) |
| Frontend | Flutter |
| Versi Desain | 2.1 (Premium Dual-Theme) |
| Tema Utama | **Ivory Elegance (Terang \- Default)** & Midnight Obsidian (Gelap) |

## **2\. Prinsip Desain (The Premium Vibe)**

Desain antarmuka (UI) dan pengalaman pengguna (UX) BobKasir berpedoman pada prinsip desain eksklusif yang memanjakan mata tanpa terlihat berlebihan (tidak norak):

1. **Airy & Breathable (Ruang Terbuka):** Kemewahan identik dengan ruang yang luas. Gunakan ruang kosong (*negative space*) yang melimpah. Jangan menjejalkan terlalu banyak informasi dalam satu layar.  
2. **Subtle Contrast:** Hindari warna hitam pekat (\#000000) di atas putih menyilaukan (\#FFFFFF). Gunakan warna *Charcoal* (Arang) di atas latar *Pearl/Ivory* (Putih Mutiara) untuk mengurangi kelelahan mata namun tetap tajam.  
3. **Elegance in Typography:** Mengandalkan hierarki ukuran dan ketebalan font (tipografi), bukan sekadar blok warna solid untuk membedakan informasi.  
4. **Brushed Metal Accents:** Penggunaan warna aksen (seperti emas/bronze) dilakukan secara sangat tipis dan presisi, hanya pada indikator aktif, *outline* tombol, atau nilai total.  
5. **Soft Glassmorphism:** Efek kaca buram (*frosted glass*) yang sangat halus untuk pop-up dan navbar, memberikan kesan lapisan elegan tanpa membuat UI terasa berat.

## **3\. Sistem Tema (Dual-Theme Elegance)**

Aplikasi memberikan kebebasan bagi Owner/Manager untuk menyesuaikan estetika dengan *ambience* tempat usaha mereka.

* **Tema Default (Terang): Ivory Elegance.** Sangat cocok untuk *coffee shop* modern, *bakery*, retail butik, dan tempat dengan pencahayaan natural.  
* **Tema Alternatif (Gelap): Midnight Obsidian.** Cocok untuk *lounge*, bar, restoran *fine-dining*, atau operasional kasir di malam hari.  
* **Pengaturan:** Tersedia di **Pengaturan \> Tampilan** dengan opsi transisi memudar (*fade*) halus saat pergantian tema.

## **4\. Palet Warna (Executive Palette)**

Palet dirancang untuk tidak menggunakan warna primer dasar (neon/cerah). Semua warna adalah warna *muted* (diredam) atau *deep* (pekat).

### **4.1 Warna Latar & Permukaan (Background & Surface)**

| Elemen | Ivory Elegance (Terang \- Default) | Midnight Obsidian (Gelap) | Keterangan |
| :---- | :---- | :---- | :---- |
| **Background Dasar** | Pearl / Off-White (\#FBFBFA) | Deep Obsidian (\#0A0B0E) | Latar paling belakang aplikasi. |
| **Surface (Card/Modal)** | Pure White (\#FFFFFF) | Matte Black (\#15161A) | Latar untuk kartu produk, keranjang, popup. |
| **Glass / Blur Surface** | Putih Transparan (rgba(255,255,255,0.8)) | Hitam Transparan (rgba(20,21,26,0.7)) | Digunakan dengan filter *blur* tinggi (16px). |
| **Border & Divider** | Light Platinum (\#EBEBEB) | Dark Slate (\#2A2B30) | Garis pemisah yang sangat tipis (1px). |

### **4.2 Warna Teks & Aksen (Typography & Accent)**

* **Primary Accent:** Brushed Gold (\#B89047). *Digunakan sangat hati-hati pada mode terang (hover state, border fokus, total harga). Pada mode gelap, menggunakan Champagne Gold (\#D4AF37).*  
* **Teks Utama (H1/H2):** Charcoal (\#1A1B1E) pada Terang / Silver-White (\#EAEAEA) pada Gelap.  
* **Teks Sekunder (Body):** Ash Gray (\#868E96) pada Terang / Muted Slate (\#8A8D93) pada Gelap.  
* **Teks Tersier (Placeholder):** Sangat pudar agar tidak mengganggu (\#C1C3C8 / \#4A4D53).

### **4.3 Warna Semantik (Feedback & Status)**

Peringatan menggunakan warna yang elegan dan tidak berteriak:

* **Success:** Forest Green (\#2E7D32). Tidak menggunakan hijau stabilo.  
* **Danger/Error:** Crimson Red (\#C62828).  
* **Pending/Warning:** Warm Amber (\#D89A29).  
* **Offline/Info:** Deep Slate (\#455A64).

## **5\. Tipografi (Typography)**

Menggunakan font **Plus Jakarta Sans**. Font ini memiliki proporsi geometris yang bersih, memberikan kesan aplikasi perbankan/finansial premium.

* **Display (Grand Total):** 36px \- 48px, *Light (300)*. Tracking rapat (tight).  
* **H1 (Header Halaman):** 24px, *Medium (500)*. Warna Charcoal/Silver-White.  
* **Label/Kategori:** 11px, *Semi-Bold (600)*, **UPPERCASE**, dengan *letter-spacing* sangat lebar (2px). Memberikan *vibes* majalah kelas atas.  
* **Body Text:** 14px, *Regular (400)*. Warna Ash Gray.  
* **Font Angka:** Wajib mengaktifkan fitur *Tabular Figures* (font-feature-settings: "tnum") agar angka rata saat berjejer dalam kolom harga.

## **6\. Komponen Antarmuka (UI Components)**

### **6.1 Tombol (Buttons)**

* **Primary Button (Checkout):**  
  * *Terang:* Latar Charcoal (\#1A1B1E), Teks Putih. Saat di-*press*, bergeser warna ke Brushed Gold.  
  * *Gelap:* Latar Brushed Gold, Teks Obsidian.  
  * Bentuk: Membulat namun tegas (Radius 8px atau 12px), bukan melingkar penuh (*pill*).  
* **Secondary/Ghost Button:** Tanpa latar belakang, border Platinum tipis 1px, teks warna Charcoal.  
* **Destructive Button:** Teks warna Crimson Red, latar transparan dengan hover merah sangat pucat.

### **6.2 Input & Form (Text Fields)**

* **Keadaan Normal:** Latar belakang *Solid Surface* (Putih/Matte Black) dengan border Platinum/Slate tipis. Tanpa bayangan (shadow).  
* **Keadaan Fokus (Active):** Border berubah menjadi Brushed Gold (1.5px), label mengecil ke atas (*floating label*) dengan transisi sangat lembut (300ms).

### **6.3 Kartu & Bayangan (Cards & Shadows)**

* **Elevasi Mewah (Mode Terang):** Hindari bayangan hitam tebal yang membuat UI terlihat kotor. Gunakan *box-shadow* dengan warna abu-abu kebiruan yang sangat pudar dan tersebar luas. (Contoh CSS: box-shadow: 0 20px 40px rgba(0, 0, 0, 0.04);).  
* **Elevasi Mewah (Mode Gelap):** Tidak menggunakan bayangan, melainkan menggunakan garis *border* tipis (\#2A2B30) dengan pendaran latar (*surface glow*) yang nyaris tak terlihat.

## **7\. Penanganan State Layar (Screen States)**

1. **Loading State:** Tidak memakai animasi *spinner* memutar yang konvensional. Gunakan animasi *shimmer* bergelombang halus berwarna Platinum, atau logo "B" memudar masuk dan keluar perlahan secara asimetris.  
2. **Empty State:** Di tengah layar, ikon *outline* tipis berwarna Ash Gray dengan teks *"Belum ada data."* Tidak perlu menggunakan ilustrasi kartun berlebihan.  
3. **Offline Mode:** Banner atas berkonsep *Frosted Glass* abu-abu. Teks kecil elegan di tengah: *"Mode Resiliensi: Koneksi terputus. Transaksi tetap berjalan lokal."* Tidak ada warna merah atau tanda silang yang menakutkan pengguna.

## **8\. Tata Letak Prioritas Halaman (Layout)**

### **8.1 Splash Screen**

* **Terang:** Latar Pearl White. Logo "B" warna Charcoal dengan titik Emas. Teks di bawah menggunakan huruf *uppercase* kecil berjarak lebar.  
* **Gelap:** Latar Deep Obsidian. Logo "B" warna Champagne Gold.

### **8.2 Halaman Kasir (Prioritas Tertinggi)**

* **Kerapian Grid:** Produk tidak dibingkai kotak tebal. Cukup gambar produk berkualitas tinggi dengan nama dan harga di bawahnya. Jarak antar produk (gap) harus lega (minimal 16px \- 24px).  
* **Sidebar Keranjang:** Dipisahkan dari grid produk menggunakan garis pembatas 1px vertical yang sangat tipis, atau menggunakan efek *Glassmorphism* jika menggunakan tablet *overlay*.  
* **Area Nominal:** Bagian Total Tagihan menggunakan ukuran font sangat besar dan tipis, menjadi titik fokus utama layar.

### **8.3 Struk Digital & Cetak**

* Layout struk dirancang *center-aligned* atau rata kiri-kanan secara presisi, menyerupai struk butik fashion mahal. Gunakan *divider* berupa garis putus-putus tipis.

## **9\. Interaksi & Sentuhan Akhir**

* **Haptic Feedback (Wajib):**  
  * Getaran sangat pendek dan tajam (*Light Impact*) saat menambah produk ke keranjang.  
  * Getaran sedang (*Medium Impact*) saat sukses melakukan pembayaran (Checkout).  
  * *Haptic feedback* memberikan ilusi fisik pada antarmuka sentuh, hal krusial untuk kesan "Premium".  
* **Transisi Layar:** Menggunakan animasi *Fade Through* atau *Shared Axis* (Material Design 3). Hindari animasi geser cepat dari samping (*sliding*) yang terkesan murahan. Segala transisi harus terasa mengalir seperti cairan (*fluid*).  
* **Corner Radius:** Konsisten. Jika kartu menggunakan lengkungan 16px, maka dialog dan modal harus menggunakan proporsi yang seimbang (misal 24px), tidak campur aduk antar sudut tajam dan sudut melingkar.