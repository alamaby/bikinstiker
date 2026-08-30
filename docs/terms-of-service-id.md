
### 1. Penerimaan Ketentuan

Dengan mengunduh, menginstal, atau menggunakan aplikasi BikinStiker ("Aplikasi"), Anda setuju untuk terikat oleh Ketentuan Layanan ini ("Ketentuan"). Jika Anda tidak setuju dengan Ketentuan ini, jangan gunakan Aplikasi.

### 2. Kelayakan

Anda harus berusia minimal 13 tahun (atau usia minimum yang diwajibkan di yurisdiksi Anda) untuk menggunakan Aplikasi. Dengan menggunakan Aplikasi, Anda menyatakan bahwa Anda memenuhi persyaratan usia ini.

### 3. Jenis Akun

#### 3.1 Akun Tamu (Anonim)
- Saat peluncuran pertama, Aplikasi membuat sesi anonim secara otomatis.
- Pengguna tamu menerima 1 kredit awal untuk mencoba Aplikasi.
- Pengguna tamu dapat membuat stiker tetapi tidak dapat menyimpan atau membagikannya sampai mereka membuat akun terdaftar.
- Stiker, paket, ikon tray, dan log prompt tamu hanya dipertahankan jika Anda meningkatkan sesi anonim yang sama ke akun terdaftar, menggunakan token migrasi sekali-pakai berumur pendek. Konten tamu tidak dapat ditransfer ke akun yang sudah ada berbeda.

#### 3.2 Akun Terdaftar
- Anda dapat membuat akun menggunakan email dan kata sandi, atau melalui penyedia login pihak ketiga yang didukung (mis. Google Sign-In).
- Pengguna terdaftar menerima 1 kredit awal saat pembuatan akun, ditambah bonus pendaftaran +4 (idempotent) yang diberikan secara otomatis oleh RPC `grant_registered_bonus()` setelah sign-up atau upgrade dari anonim, dengan total 5 kredit awal.
- Pengguna terdaftar dapat menyimpan, membagikan, dan mengekspor stiker yang dihasilkan.

#### 3.3 Login Pihak Ketiga
- Anda dapat login menggunakan penyedia OAuth pihak ketiga seperti Google Sign-In.
- Login pihak ketiga tunduk pada ketentuan dan kebijakan privasi penyedia tersebut.
- Anda bertanggung jawab menjaga keamanan akun pihak ketiga Anda.
- Kami hanya menerima informasi profil dasar (mis. nama, email, foto profil) dari penyedia; kami tidak menerima kata sandi Anda.

### 4. Kredit dan Mata Uang Virtual

#### 4.1 Cara Kerja Kredit
- Setiap pembuatan stiker menghabiskan 1 kredit.
- Kredit tidak memiliki nilai moneter dan tidak dapat ditukar dengan uang tunai.
- Kredit diberikan melalui: pengaturan akun awal (1 starter + 4 bonus pendaftaran = 5 total untuk pengguna terdaftar baru), pemberian langganan bulanan, hadiah misi, hadiah streak check-in harian (tipe mission_reward), atau pemberian administratif.
- Bonus pendaftaran diberikan secara otomatis dan idempotent melalui RPC `grant_registered_bonus()`. Jika Anda sign-up langsung (non-anonim), Anda juga menerima bonus pada autentikasi pertama.

#### 4.2 Kedaluwarsa Kredit
- Pemberian langganan bulanan dan hadiah misi mungkin memiliki tanggal kedaluwarsa (biasanya 30 hari).
- Hadiah check-in harian kedaluwarsa 30 hari setelah diberikan.
- Kredit yang kedaluwarsa dihapus dari saldo Anda secara otomatis dan baris pemberian asli ditandai dengan `expired_at`.

#### 4.3 Tier Free dan Plus
- **Tier Free**: pemberian bulanan 5 kredit, akses ke preset gratis, 2 slot paket. Batas dompet: 50 kredit.
- **Tier Plus**: pemberian bulanan 50 kredit, akses ke semua preset termasuk gaya Plus-only, 20 slot paket. Batas dompet: 50 kredit (200 kredit jika diberikan secara administratif).
- Pemberian bulanan dilewati secara otomatis jika saldo Anda saat ini sudah pada atau di atas `tier_cap`. Batas adalah per dompet, bukan per bulan.
- Fitur dan batasan tier dapat berubah dengan pemberitahuan sebelumnya.

#### 4.4 Pengembalian pada Kegagalan Generasi
- Jika pembuatan stiker gagal setelah kredit Anda dipotong, kredit dikembalikan secara otomatis.
- Jika pembuatan gagal sebelum pemotongan, tidak ada kredit yang dikenakan.

### 5. Pembuatan Stiker

#### 5.1 Cara Kerja
- Anda memilih preset gaya visual, memasukkan deskripsi teks (prompt), dan opsional menambahkan caption.
- Aplikasi mengirimkan permintaan Anda ke server kami, yang mungkin pertama-tama meningkatkan prompt Anda melalui model reasoning berbasis teks saja (Mistral) dan kemudian menghasilkan gambar stiker menggunakan salah satu dari beberapa penyedia AI (Pixazo Flux-1-Schnell, Pixazo SDXL Base 1.0, OpenRouter, Gemini, atau Pollinations sebagai fallback).
- Stiker yang dihasilkan adalah gambar gaya die-cut dengan latar belakang putih, berukuran untuk kompatibilitas WhatsApp.
- Teks caption (maksimal 10 karakter) dapat disematkan ke dalam stiker di posisi atas atau bawah.

#### 5.2 Konten yang Dihasilkan AI
- Stiker yang dihasilkan diproduksi oleh model kecerdasan buatan. Hasil dapat bervariasi dan mungkin tidak sesuai persis dengan prompt Anda.
- Kami tidak menjamin bahwa konten yang dihasilkan akan unik, bebas dari cacat, atau bebas dari klaim pihak ketiga.
- Anda bertanggung jawab meninjau konten yang dihasilkan sebelum menggunakannya atau membagikannya.
- Konten yang dihasilkan mungkin sesekali mengandung artefak atau bias yang tidak disengaja yang melekat pada teknologi AI.

#### 5.3 Batasan Prompt dan Caption
- Prompt dan caption Anda tidak boleh mengandung konten yang ilegal, berbahaya, kebencian, eksplisit secara seksual, pencemaran nama baik, atau yang melanggar hak orang lain.
- Kami berhak menolak atau menghapus konten yang melanggar batasan ini.
- Kami mungkin mencatat prompt, metadata peningkatan prompt, dan metadata provider/model untuk pencegahan penyalahgunaan, peningkatan layanan, dan keperluan diagnostik.

### 6. Konten Pengguna dan Lisensi

#### 6.1 Prompt Anda
- Anda mempertahankan kepemilikan teks prompt dan caption yang Anda kirimkan.
- Dengan mengirimkan prompt, Anda memberikan kami lisensi terbatas, non-eksklusif untuk memproses, menyimpan, dan menggunakannya semata-mata untuk tujuan membuat stiker dan mengoperasikan Aplikasi.

#### 6.2 Stiker yang Dihasilkan
- Anda diberikan lisensi non-eksklusif, seluruh dunia, bebas royalti untuk menggunakan, menyalin, memodifikasi, dan mendistribusikan stiker yang dihasilkan untuk tujuan pribadi dan komersial, tunduk pada hukum yang berlaku.
- Lisensi ini tidak meluas ke model AI, deskriptor gaya, atau teknologi dasar Aplikasi.
- Stiker yang dihasilkan diproduksi oleh AI. Anda bertanggung jawab memastikan penggunaan Anda mematuhi hukum yang berlaku, termasuk persyaratan pengungkapan konten AI.
- Lisensi ini tunduk pada hukum yang berlaku di yurisdiksi Anda, termasuk persyaratan pengungkapan atau pelabelan untuk konten yang dihasilkan AI.

### 7. Paket Stiker dan Ekspor WhatsApp

#### 7.1 Pembuatan Paket
- Anda dapat membuat paket stiker yang berisi 3 hingga 30 stiker.
- Setiap paket memiliki nama, ikon tray, dan asosiasi emoji.
- Slot paket dibatasi berdasarkan tier langganan Anda (2 untuk Free, 20 untuk Plus).

#### 7.2 Impor WhatsApp
- Paket stiker dapat diekspor ke WhatsApp melalui ContentProvider stiker Android.
- Stiker yang diekspor disimpan secara lokal di perangkat Anda dan dilayani ke WhatsApp melalui content provider sistem.
- WhatsApp mungkin meng-cache dan menangani stiker yang diekspor sesuai dengan ketentuan dan kebijakannya sendiri.
- Kami tidak bertanggung jawab atas perilaku, perubahan, atau penghapusan fungsionalitas stiker oleh WhatsApp.

#### 7.3 Ikon Tray
- Ikon tray untuk paket Anda secara otomatis diturunkan dari konten stiker pertama.
- Anda dapat mengubah ikon tray dengan memilih stiker lain dalam paket.

### 8. Periklanan

#### 8.1 Google AdMob
- Jika diaktifkan, Aplikasi menampilkan iklan banner melalui Google AdMob. Iklan video berhadiah saat ini digunakan untuk memberikan kredit misi. Penempatan banner bersifat opt-in dan dapat dinonaktifkan tanpa pemberitahuan.
- AdMob dapat mengumpulkan informasi perangkat, pengenal periklanan, dan data penggunaan sebagaimana dijelaskan dalam Kebijakan Privasi Google.
- Pengaturan personalisasi iklan Anda dapat mempengaruhi iklan mana yang ditampilkan.

#### 8.2 Iklan Berhadiah
- Anda dapat memilih untuk menonton iklan berhadiah untuk mendapatkan kredit tambahan.
- Kredit hanya diberikan setelah penyedia iklan mengonfirmasi bahwa peristiwa hadiah telah terjadi.
- Ketersediaan iklan tidak dijamin; jika iklan gagal dimuat, tidak ada hadiah yang diberikan.
- Anda tidak boleh mencoba memanipulasi atau mengeksploitasi sistem iklan berhadiah.

### 9. Kebijakan Anti-Penyalahgunaan

- Kami menerapkan pembatasan laju dan langkah-langkah pencegahan penyalahgunaan untuk melindungi layanan.
- Anda tidak boleh:
  - Mencoba mengelabui pembatasan laju atau batasan kredit
  - Menggunakan skrip otomatis, bot, atau alat lain untuk berinteraksi dengan Aplikasi
  - Mengirimkan konten yang berbahaya, ilegal, atau melanggar hak orang lain
  - Mencoba mengakses data atau akun pengguna lain
  - Melakukan rekayasa balik, dekompilasi, atau pembongkaran Aplikasi
- Kami berhak menangguhkan, membatasi, atau mengakhiri akun yang melanggar ketentuan ini.

### 10. Hak Kekayaan Intelektual

- Aplikasi, termasuk kode, desain, logo, dan merek dagangnya, adalah milik [TO_BE_FILLED_BY_LEGAL] dan dilindungi oleh hukum kekayaan intelektual yang berlaku.
- Anda tidak boleh menyalin, memodifikasi, mendistribusikan, menjual, atau menyewakan bagian mana pun dari Aplikasi tanpa persetujuan tertulis kami.
- Deskriptor gaya visual yang digunakan untuk pembuatan stiker bersifat proprietary dan tidak diungkapkan kepada pengguna.

### 11. Penafian Jaminan

APLIKASI DISEDIAKAN "SEBAGAIMANA ADANYA" DAN "SEBAGAIMANA TERSEDIA" TANPA JENIS JAMINAN APA PUN, BAIK TERSURAT MAUPUN TERSIRAT, TERMASUK NAMUN TIDAK TERBATAS PADA JAMINAN TERSIRAT KELAYAKAN JUAL, KELAYAKAN UNTUK TUJUAN TERTENTU, DAN NON-PELANGGARAN.

KAMI TIDAK MENJAMIN BAHWA:
- APLIKASI AKAN TANPA GANGGUAN, BEBAS KESALAHAN, ATAU AMAN
- KONTEN YANG DIHASILKAN AKAN MEMENUHI EKSPEKTASI ANDA
- APLIKASI AKAN KOMPATIBEL DENGAN SEMUA PERANGKAT ATAU SISTEM OPERASI
- PERIKLANAN ATAU LAYANAN PIHAK KETIGA AKAN BERFUNGSI DENGAN BENAR

### 12. Batasan Tanggung Jawab

SEJAUH DIIZINKAN OLEH HUKUM YANG BERLAKU, [TO_BE_FILLED_BY_LEGAL] TIDAK BERTANGGUNG JAWAB ATAS KERUGIAN LANGSUNG, TIDAK LANGSUNG, INSIDENSIAL, KHUSUS, KONSEKUENSIAL, ATAU HUKUMAN, TERMASUK NAMUN TIDAK TERBATAS PADA KEHILANGAN DATA, KEHILANGAN KEUNTUNGAN, ATAU GANGGUAN BISNIS, YANG TIMBUL DARI PENGGUNAAN APLIKASI ANDA.

TANGGUNG JAWAB TOTAL KAMI TIDAK MELEBIHI JUMLAH YANG ANDA BAYARKAN KEPADA KAMI DALAM 12 BULAN SEBELUM KLAIM, ATAU $100 USD, MANA YANG LEBIH BESAR.

### 13. Pengakhiran

- Anda dapat mengakhiri akun Anda kapan saja dengan menghubungi kami atau melalui pengaturan akun di Aplikasi.
- Kami dapat menangguhkan atau mengakhiri akun Anda jika Anda melanggar Ketentuan ini, terlibat dalam perilaku penyalahgunaan, atau jika diwajibkan oleh hukum.
- Setelah pengakhiran, hak Anda untuk menggunakan Aplikasi berhenti. Data akun di-soft-delete segera dan di-hard-delete oleh job terjadwal kami setelah masa tenggang 30 hari. Kami dapat mempertahankan catatan tertentu sebagaimana dijelaskan dalam Kebijakan Privasi kami.
- Email pemasaran hanya dikirim jika Anda opt-in melalui toggle Email Marketing di Profile. Anda dapat opt-out kapan saja; penarikan tidak mempengaruhi pemrosesan sebelumnya.

### 14. Perubahan pada Ketentuan Ini

- Kami dapat memperbarui Ketentuan ini dari waktu ke waktu.
- Perubahan material akan memerlukan penerimaan ulang Anda melalui Aplikasi sebelum Anda dapat melanjutkan penggunaan.
- Perubahan non-material dapat diperbarui tanpa pemberitahuan individual.
- Tanggal efektif di bagian atas dokumen ini menunjukkan revisi terbaru.

### 15. Hukum yang Berlaku

Ketentuan ini tunduk pada hukum Republik Indonesia, tanpa memperhatikan prinsip konflik hukum. Setiap sengketa yang timbul dari Ketentuan ini akan diselesaikan di pengadilan Republik Indonesia, kecuali jika diwajibkan lain oleh hukum perlindungan konsumen yang berlaku.

### 16. Keterpisahan

Jika ketentuan mana pun dalam Ketentuan ini ditemukan tidak dapat diberlakukan atau tidak sah, ketentuan tersebut akan dibatasi atau dihapus sampai tingkat minimum yang diperlukan, dan ketentuan lainnya tetap berlaku sepenuhnya.

### 17. Perjanjian Seluruh

Ketentuan ini, bersama dengan Kebijakan Privasi kami, merupakan seluruh perjanjian antara Anda dan [TO_BE_FILLED_BY_LEGAL] mengenai penggunaan Aplikasi.

### 18. Hubungi Kami

Jika Anda memiliki pertanyaan tentang Ketentuan ini, hubungi kami di:

**Email:** support@bikinstiker.example
**Alamat:** [TO_BE_FILLED_BY_LEGAL]
