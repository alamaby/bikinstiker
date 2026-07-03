# Privacy Policy

**Effective Date:** 2026-07-03 | **Last Updated:** 2026-07-03
**App:** BikinStiker
**Contact:** privacy@bikinstiker.example

---

## English

### 1. Overview

This Privacy Policy describes how [TO_BE_FILLED_BY_LEGAL] ("we", "us", or "our") collects, uses, and protects your personal information when you use the BikinStiker mobile application (the "App"). By using the App, you agree to the practices described in this policy.

### 2. Data We Collect

#### 2.1 Account Data
- **Email and password** — when you create an account via email/password sign-up.
- **Google account information** (when available) — your name, email address, and profile photo, as provided by Google Sign-In via Supabase Auth. We do not receive your Google password.
- **Anonymous session data** — a device-level anonymous session is created automatically on first launch. This is linked to a server-generated user ID, not your personal identity.

#### 2.2 Sticker and Generation Data
- **Text prompts and captions** — the text you enter to generate stickers, including any caption text and its position.
- **Preset and style metadata** — which visual style you selected.
- **Generated images** — the sticker images created by AI on your behalf, stored in private cloud storage with access limited to your account.
- **Generation history** — timestamps, preset names, prompt text, generation status, and provider/model metadata for diagnostic purposes.
- **Prompt enhancement logs** — when reasoning enhancement is applied, we log the original prompt length, success/failure status, cache hit status, and latency. The enhanced prompt is sent to the image generation provider.

#### 2.3 Credits, Wallet, and Subscription Data
- **Credit balance** — your current in-app credit balance.
- **Transaction records** — credit grants, deductions, refunds, mission rewards, and subscription grants, including expiration dates.
- **Subscription tier** — your current tier (e.g., free or plus) and active subscription period.
- **Mission progress** — missions you have completed and the credits earned.
- **Daily check-in streak records** — the date of your last claim and your current consecutive-day streak count.

#### 2.4 Anti-Bot and Abuse Prevention Data
- **Hashed IP address** — a non-reversible hash of your IP address for rate-limiting and abuse detection.
- **Usage telemetry** — generation attempts, blocked requests, and retry metadata, used to protect the service.

#### 2.5 Advertising Data
- **Rewarded video ads (active)** — when you choose to watch a rewarded ad to earn credits, Google AdMob processes the ad delivery and reward event. Google may collect device information, advertising identifiers, and usage data as described in Google's Privacy Policy.
- **Banner ads (when enabled)** — when banner ads are enabled, Google AdMob may collect your advertising ID, device model, OS version, app interactions, diagnostic data, and approximate location, depending on your device settings, ad personalization consent, and Google's policies. Banner placement is opt-in and may be disabled at any time.

#### 2.6 Local Device Data
- **Image cache** — generated stickers may be cached locally on your device to improve loading performance.
- **Sticker pack export cache** — when you export a sticker pack to WhatsApp, temporary files may be stored locally on your device.

#### 2.7 Guest Migration Tokens
- When you upgrade from a guest session to a registered account, a short-lived one-time token (`guest_migration_tokens`) is created to transfer your generated stickers, packs, tray icons, and prompt logs.
- Tokens are hashed at rest, expire automatically (typically within minutes of issuance), and are not shared with third parties.
- Tokens are consumed exactly once by the migration RPC and are then invalidated.

### 3. How We Use Your Data

| Purpose | Data Used | Legal Basis |
|---|---|---|
| Provide and operate the App | Account data, sticker data, wallet data | Performance of contract |
| Generate AI-powered stickers | Text prompts, captions, preset selection, enhanced prompt | Performance of contract |
| Manage credits, subscriptions, and missions | Wallet, subscription, mission, and daily check-in data | Performance of contract |
| Prevent abuse and maintain service security | Anti-bot events, hashed IP, usage telemetry | Legitimate interest |
| Display personalized advertising (when enabled) | AdMob identifiers, device info, rewarded ad events | Consent (where required by law) |
| Improve the service and diagnose issues | Generation logs, prompt enhancement logs, provider metadata, diagnostic data | Legitimate interest |
| Send policy or service updates | Contact information if provided | Legitimate interest / Consent |

### 4. Third-Party Processors

We share your data with the following third-party service providers as necessary to operate the App:

| Provider | Purpose | Privacy Policy |
|---|---|---|
| **Supabase** | Authentication, database, cloud storage, serverless functions | https://supabase.com/privacy |
| **Google (AdMob)** | Rewarded video ads, banner ads (when enabled), fraud prevention | https://policies.google.com/privacy |
| **Google Sign-In** | OAuth authentication (when available) | https://policies.google.com/privacy |
| **Pixazo** | Server-side sticker image generation (Flux-1-Schnell, SDXL Base 1.0; free tier, rate-limited) | https://pixazo.ai/privacy |
| **OpenRouter** | Server-side sticker image generation (paid fallback) | https://openrouter.ai/privacy |
| **Gemini** | Server-side sticker image generation (paid fallback) | https://ai.google.dev/privacy |
| **Pollinations** | Server-side sticker image generation (unauthenticated fallback) | https://pollinations.ai/privacy |
| **Mistral** | Text-only prompt enhancement before image generation (not used for image generation) | https://mistral.ai/privacy |
| **WhatsApp (on-device)** | Importing generated sticker packs into WhatsApp | https://www.whatsapp.com/privacy |

Server-side API keys for AI providers are never exposed to the App. They are stored and managed exclusively on our backend servers.

### 5. Data Retention

| Data Category | Retention Period |
|---|---|
| Account and authentication data | Retained while your account is active; deleted upon account deletion request |
| Sticker generation history | Retained while your account is active or until manually deleted |
| Credits and transaction records | Retained for 3 years for audit purposes |
| Subscription records | Retained for 3 years for audit purposes |
| Anti-bot and abuse logs | Retained for up to 12 months |
| Prompt enhancement logs | Retained for up to 12 months |
| Daily check-in streak records | Retained while your account is active |
| Guest migration tokens | Short-lived (minutes); invalidated immediately after consumption |
| Local device cache | Stored until cleared by you or by app/OS cleanup |
| Legal consent record | Retained indefinitely as audit proof |
| Advertising data | Handled by Google per their retention policies |

### 6. Your Rights (GDPR / UU PDP)

Depending on your jurisdiction, you may have the following rights regarding your personal data:

- **Access** — request a copy of the personal data we hold about you.
- **Correction** — request correction of inaccurate or incomplete data.
- **Deletion** — request deletion of your personal data, subject to legal retention obligations.
- **Withdrawal of Consent** — withdraw consent for data processing where consent is the legal basis (e.g., advertising, marketing emails). Withdrawal does not affect the lawfulness of processing that occurred before withdrawal.
- **Data Portability** — request your data in a structured, commonly used, machine-readable format.
- **Restriction / Objection** — request restriction of processing or object to processing in certain circumstances.
- **Lodge a Complaint** — file a complaint with your local data protection authority.

To exercise your rights, contact us at privacy@bikinstiker.example. We will respond within 30 days of receiving your request.

### 7. Children's Privacy

The App is not intended for children under the age of 13 (or the applicable minimum age in your jurisdiction). We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us immediately so we can delete it.

### 8. International Data Transfers

Your data may be processed in countries outside your jurisdiction, including where Supabase, Google, Pixazo, OpenRouter, Gemini, Pollinations, or Mistral operate their infrastructure. These transfers are protected by appropriate safeguards, including standard contractual clauses where required by applicable law.

### 9. Security

We implement industry-standard security measures to protect your data:

- **Row Level Security (RLS)** — database access is restricted to your own records.
- **Private storage with signed URLs** — sticker files are stored in private buckets; temporary signed URLs expire after a limited time.
- **Server-side API key management** — AI provider credentials are never exposed to the client app.
- **Hashed migration tokens** — guest migration tokens are stored as one-way hashes and expire within minutes.
- **Secure authentication** — provided by Supabase Auth with industry-standard protocols.

However, no method of transmission or storage is 100% secure. We cannot guarantee absolute security of your data.

### 10. Changes to This Policy

We may update this Privacy Policy from time to time. Material changes will require renewed consent via the App. Non-material changes may be updated without notification. The effective date at the top of this document indicates the most recent revision.

### 11. Contact Us

If you have questions about this Privacy Policy or wish to exercise your data rights, contact us at:

**Email:** privacy@bikinstiker.example
**Address:** [TO_BE_FILLED_BY_LEGAL]

---

## Bahasa Indonesia

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