# Terms of Service

**Effective Date:** 2026-07-03 | **Last Updated:** 2026-07-03
**App:** BikinStiker
**Contact:** support@bikinstiker.example

---

## English

### 1. Acceptance of Terms

By downloading, installing, or using the BikinStiker mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

### 2. Eligibility

You must be at least 13 years old (or the minimum age required in your jurisdiction) to use the App. By using the App, you represent that you meet this age requirement.

### 3. Account Types

#### 3.1 Guest (Anonymous) Account
- On first launch, the App creates an anonymous session automatically.
- Guest users receive 1 starter credit to try the App.
- Guest users can generate stickers but cannot save or share them until they create a registered account.
- Guest stickers, packs, tray icons, and prompt logs are retained only if you upgrade the same anonymous session to a registered account, using a short-lived one-time migration token. Guest content cannot be transferred to a different existing account.

#### 3.2 Registered Account
- You may create an account using your email and password, or via a supported third-party sign-in provider (e.g., Google Sign-In).
- Registered users receive 1 starter credit upon account creation, plus a +4 registration bonus (idempotent) granted automatically by the `grant_registered_bonus()` RPC after sign-up or anonymous upgrade, for a total of 5 starter credits.
- Registered users can save, share, and export generated stickers.

#### 3.3 Third-Party Sign-In
- You may sign in using a third-party OAuth provider such as Google Sign-In.
- Third-party sign-in is subject to the provider's own terms and privacy policy.
- You are responsible for maintaining the security of your third-party account.
- We receive only basic profile information (e.g., name, email, profile photo) from the provider; we do not receive your password.

### 4. Credits and Virtual Currency

#### 4.1 How Credits Work
- Each sticker generation costs 1 credit.
- Credits have no monetary value and cannot be exchanged for cash.
- Credits are granted through: initial account setup (1 starter + 4 registration bonus = 5 total for new registered users), monthly subscription grants, mission rewards, daily check-in streak rewards (mission_reward type), or administrative grants.
- Registration bonus is granted automatically and idempotently via the `grant_registered_bonus()` RPC. If you signed up directly (non-anonymous), you also receive the bonus on first authentication.

#### 4.2 Credit Expiration
- Monthly subscription grants and mission rewards may have an expiration date (typically 30 days).
- Daily check-in rewards expire 30 days after they are granted.
- Expired credits are removed from your balance automatically and the original grant row is marked with `expired_at`.

#### 4.3 Free and Plus Tiers
- **Free tier**: 5 credits monthly grant, access to free presets, 2 pack slots. Wallet cap: 50 credits.
- **Plus tier**: 50 credits monthly grant, access to all presets including Plus-only styles, 20 pack slots. Wallet cap: 50 credits (200 credits if granted administratively).
- Monthly grants are skipped automatically if your current balance is already at or above `tier_cap`. The cap is per wallet, not per month.
- Tier features and limits may change with prior notice.

#### 4.4 Refund on Failed Generation
- If sticker generation fails after your credit has been deducted, the credit is automatically refunded.
- If generation fails before deduction, no credit is charged.

### 5. Sticker Generation

#### 5.1 How It Works
- You select a visual style preset, enter a text description (prompt), and optionally add a caption.
- The App sends your request to our server, which may first enhance your prompt via a text-only reasoning model (Mistral) and then generate a sticker image using one of several AI providers (Pixazo Flux-1-Schnell, Pixazo SDXL Base 1.0, OpenRouter, Gemini, or Pollinations as fallback).
- The generated sticker is a die-cut style image with a white background, sized for WhatsApp compatibility.
- Caption text (max 10 characters) can be embedded into the sticker at top or bottom position.

#### 5.2 AI-Generated Content
- Generated stickers are produced by artificial intelligence models. Results may vary and may not exactly match your prompt.
- We do not guarantee that generated content will be unique, free of defects, or free from third-party claims.
- You are responsible for reviewing generated content before using or sharing it.
- Generated content may occasionally contain unintended artifacts or biases inherent to AI technology.

#### 5.3 Prompt and Caption Restrictions
- Your prompts and captions must not contain content that is illegal, harmful, hateful, sexually explicit, defamatory, or that infringes on the rights of others.
- We reserve the right to refuse or remove content that violates these restrictions.
- We may log prompts, prompt enhancement metadata, and provider/model metadata for abuse prevention, service improvement, and diagnostic purposes.

### 6. User Content and License

#### 6.1 Your Prompts
- You retain ownership of the text prompts and captions you submit.
- By submitting prompts, you grant us a limited, non-exclusive license to process, store, and use them solely for the purpose of generating stickers and operating the App.

#### 6.2 Generated Stickers
- You are granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, and distribute generated stickers for personal and commercial purposes, subject to applicable law.
- This license does not extend to the AI models, style descriptors, or the App's underlying technology.
- Generated stickers are AI-produced. You are responsible for ensuring your use complies with applicable laws, including disclosure requirements for AI-generated content.
- This license is subject to applicable laws in your jurisdiction, including any disclosure or labelling requirements for AI-generated content.

### 7. Sticker Packs and WhatsApp Export

#### 7.1 Pack Creation
- You can create sticker packs containing 3 to 30 stickers.
- Each pack has a name, tray icon, and emoji associations.
- Pack slots are limited based on your subscription tier (2 for Free, 20 for Plus).

#### 7.2 WhatsApp Import
- Sticker packs can be exported to WhatsApp via Android's sticker ContentProvider.
- Exported stickers are stored locally on your device and served to WhatsApp through the system's content provider.
- WhatsApp may cache and handle exported stickers according to its own terms and policies.
- We are not responsible for WhatsApp's behavior, changes, or removal of sticker functionality.

#### 7.3 Tray Icon
- The tray icon for your pack is automatically derived from the first sticker's content.
- You may change the tray icon by selecting a different sticker in the pack.

### 8. Advertising

#### 8.1 Google AdMob
- When enabled, the App displays banner ads via Google AdMob. Rewarded video ads are currently used to grant mission credits. Banner placement is opt-in and may be disabled without notice.
- AdMob may collect device information, advertising identifiers, and usage data as described in Google's Privacy Policy.
- Your ad personalization settings may affect which ads are shown.

#### 8.2 Rewarded Ads
- You may choose to watch a rewarded ad to earn additional credits.
- Credits are granted only after the ad provider confirms the reward event occurred.
- Ad availability is not guaranteed; if ads fail to load, no reward is granted.
- You may not attempt to manipulate or exploit the rewarded ad system.

### 9. Anti-Abuse Policy

- We implement rate limiting and abuse prevention measures to protect the service.
- You may not:
  - Attempt to circumvent rate limits or credit restrictions
  - Use automated scripts, bots, or other tools to interact with the App
  - Submit content that is harmful, illegal, or violates the rights of others
  - Attempt to access other users' data or accounts
  - Reverse-engineer, decompile, or disassemble the App
- We reserve the right to suspend, restrict, or terminate accounts that violate these terms.

### 10. Intellectual Property

- The App, including its code, design, logos, and trademarks, is the property of [TO_BE_FILLED_BY_LEGAL] and protected by applicable intellectual property laws.
- You may not copy, modify, distribute, sell, or lease any part of the App without our written consent.
- The visual style descriptors used for sticker generation are proprietary and not disclosed to users.

### 11. Disclaimer of Warranties

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

WE DO NOT WARRANT THAT:
- THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE
- GENERATED CONTENT WILL MEET YOUR EXPECTATIONS
- THE APP WILL BE COMPATIBLE WITH ALL DEVICES OR OPERATING SYSTEMS
- ADVERTISING OR THIRD-PARTY SERVICES WILL FUNCTION CORRECTLY

### 12. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, [TO_BE_FILLED_BY_LEGAL] SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, LOSS OF PROFITS, OR BUSINESS INTERRUPTION, ARISING FROM YOUR USE OF THE APP.

OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID TO US IN THE 12 MONTHS PRECEDING THE CLAIM, OR $100 USD, WHICHEVER IS GREATER.

### 13. Termination

- You may terminate your account at any time by contacting us or through the App's account settings.
- We may suspend or terminate your account if you violate these Terms, engage in abusive behavior, or if required by law.
- Upon termination, your right to use the App ceases. Account data is soft-deleted immediately and hard-deleted by our scheduled job after a 30-day grace period. We may retain certain records as described in our Privacy Policy.
- Marketing emails are sent only when you opt in via the Email Marketing toggle in Profile. You may opt out at any time; withdrawal does not affect prior processing.

### 14. Changes to These Terms

- We may update these Terms from time to time.
- Material changes will require your renewed acceptance via the App before you can continue using it.
- Non-material changes may be updated without individual notice.
- The effective date at the top of this document indicates the most recent revision.

### 15. Governing Law

These Terms are governed by the laws of the Republic of Indonesia, without regard to conflict of law principles. Any disputes arising from these Terms shall be resolved in the courts of the Republic of Indonesia, unless otherwise required by applicable consumer protection law.

### 16. Severability

If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.

### 17. Entire Agreement

These Terms, together with our Privacy Policy, constitute the entire agreement between you and [TO_BE_FILLED_BY_LEGAL] regarding the use of the App.

### 18. Contact Us

If you have questions about these Terms, contact us at:

**Email:** support@bikinstiker.example
**Address:** [TO_BE_FILLED_BY_LEGAL]

---

## Bahasa Indonesia

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