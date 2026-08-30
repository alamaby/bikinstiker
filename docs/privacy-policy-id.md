
### 1. Ringkasan

Kebijakan Privasi ini menjelaskan bagaimana [TO_BE_FILLED_BY_LEGAL] ("kami") mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda saat Anda menggunakan aplikasi BikinStiker ("Aplikasi"). Dengan menggunakan Aplikasi, Anda menyetujui praktik yang dijelaskan dalam kebijakan ini.

### 2. Data yang Kami Kumpulkan

#### 2.1 Data Akun
- **Email dan kata sandi** — saat Anda membuat akun melalui pendaftaran email/kata sandi.
- **Informasi akun Google** (jika tersedia) — nama, alamat email, dan foto profil Anda, sebagaimana disediakan oleh Google Sign-In melalui Supabase Auth. Kami tidak menerima kata sandi Google Anda.
- **Data sesi anonim** — sesi anonim tingkat perangkat dibuat secara otomatis pada peluncuran pertama. Sesi ini terkait dengan ID pengguna yang dihasilkan server, bukan identitas pribadi Anda.

#### 2.2 Data Stiker dan Generasi
- **Teks prompt dan caption** — teks yang Anda masukkan untuk membuat stiker, termasuk teks caption dan posisinya.
- **Metadata preset dan gaya** — gaya visual mana yang Anda pilih.
- **Gambar yang dihasilkan** — gambar stiker yang dibuat oleh AI atas nama Anda, disimpan di penyimpanan cloud pribadi dengan akses terbatas untuk akun Anda.
- **Riwayat generasi** — cap waktu, nama preset, teks prompt, status generasi, dan metadata provider/model untuk keperluan diagnostik.
- **Log peningkatan prompt** — saat peningkatan prompt (reasoning) diterapkan, kami mencatat panjang prompt asli, status berhasil/gagal, hit cache, dan latensi. Prompt yang ditingkatkan dikirim ke penyedia generasi gambar.

#### 2.3 Data Kredit, Dompet, dan Langganan
- **Saldo kredit** — saldo kredit dalam aplikasi Anda saat ini.
- **Catatan transaksi** — pemberian kredit, potongan, pengembalian, hadiah misi, dan pemberian langganan, termasuk tanggal kedaluwarsa.
- **Tier langganan** — tier Anda saat ini (misalnya free atau plus) dan periode langganan aktif.
- **Progres misi** — misi yang telah Anda selesaikan dan kredit yang diperoleh.
- **Catatan streak check-in harian** — tanggal klaim terakhir Anda dan jumlah streak hari berturut-turut saat ini.

#### 2.4 Data Pencegahan Bot dan Penyalahgunaan
- **Hash alamat IP** — hash alamat IP Anda yang tidak dapat dibalikkan untuk pembatasan laju dan deteksi penyalahgunaan.
- **Telemetri penggunaan** — percobaan generasi, permintaan yang diblokir, dan metadata percobaan ulang.

#### 2.5 Data Periklanan
- **Iklan video berhadiah (aktif)** — saat Anda memilih menonton iklan berhadiah untuk mendapatkan kredit, Google AdMob memproses pengiriman iklan dan peristiwa hadiah. Google dapat mengumpulkan informasi perangkat, pengenal periklanan, dan data penggunaan sebagaimana dijelaskan dalam Kebijakan Privasi Google.
- **Iklan banner (jika diaktifkan)** — saat iklan banner diaktifkan, Google AdMob dapat mengumpulkan ID periklanan Anda, model perangkat, versi OS, interaksi aplikasi, data diagnostik, dan lokasi perkiraan, tergantung pada pengaturan perangkat, persetujuan personalisasi iklan, dan kebijakan Google. Penempatan banner bersifat opt-in dan dapat dinonaktifkan kapan saja.

#### 2.6 Data Perangkat Lokal
- **Cache gambar** — stiker yang dihasilkan mungkin di-cache secara lokal di perangkat Anda untuk meningkatkan kinerja pemuatan.
- **Cache ekspor paket stiker** — saat Anda mengekspor paket stiker ke WhatsApp, file sementara mungkin disimpan secara lokal di perangkat Anda.

#### 2.7 Token Migrasi Tamu
- Saat Anda meningkatkan sesi tamu ke akun terdaftar, token sekali-pakai berumur pendek (`guest_migration_tokens`) dibuat untuk memindahkan stiker, paket, ikon tray, dan log prompt Anda.
- Token di-hash saat disimpan, kedaluwarsa secara otomatis (biasanya dalam hitungan menit sejak pembuatan), dan tidak dibagikan ke pihak ketiga.
- Token dikonsumsi tepat satu kali oleh RPC migrasi dan langsung di-invalidasi.

### 3. Bagaimana Kami Menggunakan Data Anda

| Tujuan | Data yang Digunakan | Dasar Hukum |
|---|---|---|
| Menyediakan dan mengoperasikan Aplikasi | Data akun, data stiker, data dompet | Pelaksanaan kontrak |
| Menghasilkan stiker bertenaga AI | Teks prompt, caption, pemilihan preset, prompt yang ditingkatkan | Pelaksanaan kontrak |
| Mengelola kredit, langganan, dan misi | Data dompet, langganan, misi, dan check-in harian | Pelaksanaan kontrak |
| Mencegah penyalahgunaan dan menjaga keamanan layanan | Peristiwa anti-bot, hash IP, telemetri penggunaan | Kepentingan yang sah |
| Menampilkan iklan yang dipersonalisasi (jika diaktifkan) | Pengenal AdMob, info perangkat, peristiwa iklan berhadiah | Persetujuan (diwajibkan oleh hukum) |
| Meningkatkan layanan dan mendiagnosis masalah | Log generasi, log peningkatan prompt, metadata provider, data diagnostik | Kepentingan yang sah |
| Mengirim pembaruan kebijakan atau layanan | Informasi kontak jika diberikan | Kepentingan yang sah / Persetujuan |

### 4. Pihak Ketiga Pemroses

Kami membagikan data Anda dengan pihak ketiga berikut sebagaimana diperlukan untuk mengoperasikan Aplikasi:

| Penyedia | Tujuan | Kebijakan Privasi |
|---|---|---|
| **Supabase** | Autentikasi, basis data, penyimpanan cloud, fungsi serverless | https://supabase.com/privacy |
| **Google (AdMob)** | Iklan video berhadiah, iklan banner (jika diaktifkan), pencegahan penipuan | https://policies.google.com/privacy |
| **Google Sign-In** | Autentikasi OAuth (jika tersedia) | https://policies.google.com/privacy |
| **Pixazo** | Generasi gambar stiker di sisi server (Flux-1-Schnell, SDXL Base 1.0; tier gratis, rate-limited) | https://pixazo.ai/privacy |
| **OpenRouter** | Generasi gambar stiker di sisi server (fallback berbayar) | https://openrouter.ai/privacy |
| **Gemini** | Generasi gambar stiker di sisi server (fallback berbayar) | https://ai.google.dev/privacy |
| **Pollinations** | Generasi gambar stiker di sisi server (fallback tanpa autentikasi) | https://pollinations.ai/privacy |
| **Mistral** | Peningkatan prompt berbasis teks sebelum generasi gambar (tidak digunakan untuk generasi gambar) | https://mistral.ai/privacy |
| **WhatsApp (di perangkat)** | Mengimpor paket stiker ke WhatsApp | https://www.whatsapp.com/privacy |

Kunci API penyedia AI tidak pernah ditampilkan ke Aplikasi. Kunci tersebut disimpan dan dikelola secara eksklusif di server backend kami.

### 5. Retensi Data

| Kategori Data | Periode Retensi |
|---|---|
| Data akun dan autentikasi | Disimpan selama akun Anda aktif; dihapus atas permintaan penghapusan akun |
| Riwayat generasi stiker | Disimpan selama akun Anda aktif atau hingga dihapus secara manual |
| Kredit dan catatan transaksi | Disimpan selama 3 tahun untuk keperluan audit |
| Catatan langganan | Disimpan selama 3 tahun untuk keperluan audit |
| Log anti-bot dan penyalahgunaan | Disimpan hingga 12 bulan |
| Log peningkatan prompt | Disimpan hingga 12 bulan |
| Catatan streak check-in harian | Disimpan selama akun Anda aktif |
| Token migrasi tamu | Berumur pendek (menit); langsung di-invalidasi setelah dikonsumsi |
| Cache perangkat lokal | Disimpan hingga dihapus oleh Anda atau pembersihan OS/aplikasi |
| Catatan persetujuan hukum | Disimpan selamanya sebagai bukti audit |
| Data periklanan | Dikelola oleh Google sesuai kebijakan retensi mereka |

### 6. Hak Anda (GDPR / UU PDP)

Berdasarkan yurisdiksi Anda, Anda mungkin memiliki hak-hak berikut mengenai data pribadi Anda:

- **Akses** — meminta salinan data pribadi yang kami miliki tentang Anda.
- **Koreksi** — meminta koreksi data yang tidak akurat atau tidak lengkap.
- **Penghapusan** — meminta penghapusan data pribadi Anda, tunduk pada kewajiban retensi hukum.
- **Penarikan Persetujuan** — menarik persetujuan untuk pemrosesan data di mana persetujuan merupakan dasar hukum (mis. periklanan, email pemasaran). Penarikan tidak mempengaruhi keabsahan pemrosesan yang terjadi sebelum penarikan.
- **Portabilitas Data** — meminta data Anda dalam format yang terstruktur, umum digunakan, dan dapat dibaca mesin.
- **Pembatasan / Keberatan** — meminta pembatasan pemrosesan atau keberatan terhadap pemrosesan dalam keadaan tertentu.
- **Mengajukan Keluhan** — mengajukan keluhan kepada otoritas perlindungan data lokal Anda.

Untuk menggunakan hak Anda, hubungi kami di privacy@bikinstiker.example. Kami akan merespons dalam 30 hari sejak menerima permintaan Anda.

### 7. Privasi Anak-anak

Aplikasi tidak ditujukkan untuk anak-anak di bawah usia 13 tahun (atau usia minimum yang berlaku di yurisdiksi Anda). Kami tidak secara sadar mengumpulkan informasi pribadi dari anak-anak. Jika Anda yakin anak telah memberikan data pribadi kepada kami, segera hubungi kami agar kami dapat menghapusnya.

### 8. Transfer Data Internasional

Data Anda mungkin diproses di luar yurisdiksi Anda, termasuk di tempat Supabase, Google, Pixazo, OpenRouter, Gemini, Pollinations, atau Mistral mengoperasikan infrastruktur mereka. Transfer ini dilindungi oleh perlindungan yang memadai, termasuk klausul kontrak standar jika diwajibkan oleh hukum yang berlaku.

### 9. Keamanan

Kami menerapkan langkah-langkah keamanan standar industri untuk melindungi data Anda:

- **Row Level Security (RLS)** — akses basis data dibatasi hanya untuk catatan Anda sendiri.
- **Penyimpanan pribadi dengan URL bertanda tangan** — file stiker disimpan di bucket pribadi; URL bertanda tangan kedaluwarsa setelah waktu terbatas.
- **Manajemen kunci API di sisi server** — kredensial penyedia AI tidak pernah ditampilkan ke aplikasi klien.
- **Token migrasi ter-hash** — token migrasi tamu disimpan sebagai hash satu arah dan kedaluwarsa dalam hitungan menit.
- **Autentikasi aman** — disediakan oleh Supabase Auth dengan protokol standar industri.

Namun, tidak ada metode transmisi atau penyimpanan yang 100% aman. Kami tidak dapat menjamin keamanan absolut data Anda.

### 10. Perubahan pada Kebijakan Ini

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Perubahan material akan memerlukan persetujuan ulang melalui Aplikasi. Perubahan non-material dapat diperbarui tanpa pemberitahuan. Tanggal efektif di bagian atas dokumen ini menunjukkan revisi terbaru.

### 11. Hubungi Kami

Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini atau ingin menggunakan hak data Anda, hubungi kami di:

**Email:** privacy@bikinstiker.example
**Alamat:** [TO_BE_FILLED_BY_LEGAL]
