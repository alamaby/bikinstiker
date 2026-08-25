# Project Memory - BikinStiker

## Status Saat Ini
- **Terakhir dikerjakan:** 2026-08-25
- **Perubahan terakhir:** Surprise Me AI Enhancement + review fixes — DEPLOY PRODUKSI SEBAGIAN BESAR SELESAI (migrasi ter-apply, edge functions ter-deploy, preflight bersih)
- **Versi:** `0.20.1+71`
- **Verifikasi:** deno surprise-me 10/10 (--allow-read) + generate-sticker 80/80, `flutter analyze` (0 issues), `flutter test` (138/138), `flutter build apk --split-per-abi` sukses (3 APK); produksi: enum+RPC+RLS+constraint terverifikasi via MCP read, preflight 0 pelanggaran
- **Blocker aktif:** sisa manual di SQL Editor: `ALTER TABLE public.credit_transactions VALIDATE CONSTRAINT credit_transactions_sign_consistency;` + patch credential Cloudflare (opsional — provider masih is_active=false).

## Riwayat Pekerjaan (terbaru → terlama)

### 2026-08-25 | Surprise Me Review Fixes
- **Status:** selesai. Pending deploy (migration + 2 edge function).
- **Latar:** Code review implementasi Surprise Me AI menemukan 6 temuan; semua diperbaiki per keputusan user (+CTA Missions di dialog).
- **Temuan & Fix:**
  - **H1 Critical:** `surprise-me/index.ts` baca env `SUPABASE_SERVICE_ROLE` padahal runtime inject `SUPABASE_SERVICE_ROLE_KEY` → semua request 500 di produksi (unit test tidak menangkap karena guard env ada di handler). Fix: nama var dikoreksi + **test kontrak baru** membaca source file dan assert nama env benar.
  - **H2 UX:** Dialog konfirmasi render "-1 credit" saat saldo 0 dan OK tetap aktif → 402 belakangan. Fix: pre-check `willBeCharged && balance < 1` → judul `notEnoughCredits`, isi pesan cost + `surpriseTopUpViaMissions`, tombol utama jadi CTA navigasi ke MissionsScreen (flag `goMissions` + guard mounted setelah await showDialog).
  - **M1:** `fetchQuota` double-wrap ServerFailure→UnknownFailure; fix `on Failure rethrow`.
  - **M2:** SurpriseMeButton punya komputasi random mati (parent abaikan suggestion) — refactor jadi `enabled` + `VoidCallback`; props `presetId/textOnly/avoid` dihapus; call site tunggal dirapikan.
  - **M3:** RateLimitedFailure kini tampil `surpriseWaitSeconds({seconds})`; failure handler pakai switch per tipe Failure.
  - **L1 Ops:** Migration drop+re-add CHECK sign-consistency menghapus status VALIDATE migrasi lama — header `20260825000001` kini memuat langkah manual VALIDATE + query preflight; deploy checklist SME6 diperluas.
- **Keputusan Teknis:**
  - Contract test env-name membaca source sendiri via `Deno.readTextFile(new URL(...))` — **perintah test surprise-me kini butuh `--allow-read`**. Assert substring longgar agar tahan reformat.
  - CTA Missions dipilih daripada sekadar disable OK (user butuh jalur dapat credit); navigasi plain `MaterialPageRoute` sama seperti appbar (MissionsScreen baca bloc dari provider app-level).
- **File:**
  - `supabase/functions/surprise-me/{index.ts,index_test.ts}` (fix + 1 test kontrak, total 10)
  - `supabase/migrations/20260825000001_surprise_me_ai.sql` (komentar header saja — belum di-deploy, aman diedit)
  - `lib/data/repositories/surprise_me_repository.dart`, `lib/presentation/widgets/surprise_me_button.dart`, `lib/presentation/screens/home/home_screen.dart`
  - `lib/l10n/app_{en,id}.arb` (+2 key) + generated
  - `pubspec.yaml` (`0.20.1+71`)
  - `plans/2026-08-25-surprise-me-review-fixes-plan.md`, `TODO.md`
- **Verifikasi:** deno surprise-me 10/10 (`--allow-read`), generate-sticker 80/80, flutter analyze 0 issues, flutter test 138/138, build apk 3 ABI sukses.
- **Proposed commit:** `fix(surprise-me): correct service role env name, zero-balance dialog guard, and button API cleanup`

### 2026-08-25 | Surprise Me AI Enhancement
- **Status:** selesai implementasi. Pending deploy (migration + 2 edge function).
- **Follow-up deploy fix (2026-08-25):** `supabase db push` gagal SQLSTATE 55P04 — nilai enum baru 'surprise_prompt' dipakai ekspresi CHECK dalam transaksi yang sama dengan ALTER TYPE ADD VALUE (PG larang; ekspresi CHECK dianalisis saat DDL, body PL/pgSQL tidak). Transaksi rollback → remote bersih. Fix: migrasi dipecah — enum+tabel+RPC tetap `20260825000001`, replace CHECK pindah ke `20260825000002_surprise_me_sign_check.sql` (+ catatan VALIDATE manual). Pelajaran: ADD VALUE + pemakaian literal di DDL apapun (CHECK/index/DEFAULT) wajib beda file migrasi.
- **Fitur:** Tombol "Surprise me" kini menghasilkan deskripsi stiker via reasoning provider chain (bukan curated list lokal). Konfirmasi biaya sebelum jalan; 3x gratis/hari (WIB) lalu 1 credit; style-aware preset; ≤200 char.
- **Alur:** klik → fetch `get_surprise_me_quota()` → dialog dinamis (gratis sisa N / bayar 1 credit + saldo setelahnya) → POST `surprise-me` → server: rate-limit in-memory (cooldown 5s + cap 30/hari/user) → kuota habis? `charge_surprise_prompt(1)` FIFO consume → loadPreset (style_descriptor valid dari DB) → seed randomizer (60 subjek × 40 twist, crypto RNG) + avoid-list 20 prompt history → reasoning chain failover (reuse adapter generate-sticker) → validasi non-kosong ≤200 char retry 1x → insert `surprise_me_history` → respons `{prompt, balance, freeRemaining, charged}`. Gagal total semua provider → auto `refund_surprise_prompt(1)` + respons 502 `{refunded:true}`.
- **Client feedback:** spinner + label "Lagi bikin ide..." + disable TextField/caption/generate/chip saat loading; sukses → isi field + haptic + refresh WalletBloc; gagal → snackbar + fallback lokal kPromptSuggestions gratis + refresh wallet. Text-only (tipografi) tetap perilaku lokal lama.
- **Keputusan Teknis:**
  - **Deviasi Fase 2:** ekstraksi `_shared/reasoning.ts` dibatalkan — helper HTTP dipakai luas kode image provider (diff besar). Ganti: tambah `export` pada `callReasoningProvider`, `loadReasoningConfigs`, `resolveUserRole`, `loadPreset` di generate-sticker/index.ts; surprise-me import relatif langsung (`import.meta.main` guard sudah ada sehingga aman). Konsekuensi: surprise-me/deno.json perlu mapping `imagescript`; deploy surprise-me membawa file generate-stiker sebagai dependency.
  - Charge pakai FIFO consume penuh (copy pola deduct_credit_for_sticker tanpa baris generasi) agar kredit expired tidak bisa dipakai surprise-me.
  - Refund sengaja sederhana (balance+ledger 'refund' positif), bukan restore FIFO — nuansa expiry hilang pada refund, trade-off diterima (jalur jarang).
  - FREE_LIMIT=3 hidup di RPC `get_surprise_me_quota` (single source of truth), bukan di Edge Function.
  - Anti-repeat lintas user TIDAK dijamin absolut (per-user akurat via DB; lintas-user probabilistik — tak terlihat secara UX).
  - Migration jebakan yang ditangani: CHECK `credit_transactions_sign_consistency` direplace agar 'surprise_prompt' boleh negatif; `ALTER TYPE ADD VALUE` standalone.
- **File:**
  - `supabase/migrations/20260825000001_surprise_me_ai.sql` (NEW)
  - `supabase/functions/surprise-me/{index.ts,index_test.ts,deno.json}` (NEW)
  - `supabase/functions/generate-sticker/index.ts` (+4 export keyword saja)
  - `supabase/config.toml` (+[functions.surprise-me])
  - `lib/data/repositories/surprise_me_repository.dart` (NEW)
  - `lib/presentation/blocs/surprise_me/{cubit,state}.dart` (NEW)
  - `lib/core/di.dart`, `lib/app.dart`, `lib/presentation/screens/home/home_screen.dart`
  - `lib/l10n/app_{en,id}.arb` (+10 key surprise*) + generated
  - `pubspec.yaml` (`0.20.0+70`)
  - `plans/2026-08-25-surprise-me-ai-enhancement-plan.md`, `TODO.md`
- **Verifikasi:** deno surprise-me 9/9; deno generate-sticker 80/80 (gate 2x); flutter analyze 0 issues; flutter test 138/138; build apk 3 ABI.
- **Proposed commit:** `feat(surprise-me): AI-generated sticker ideas with daily free quota and credit charging`

### 2026-08-25 | Surprise Me Gap Fixes
- **Status:** selesai.
- **Latar:** Audit implementasi fitur "Surprise me" menemukan 3 gap; semua difix + 1 bonus i18n.
- **Perubahan:**
  - Gap 1 (i18n): label hardcoded `'Surprise me'` di `surprise_me_button.dart` diganti `AppLocalizations.of(context)?.surpriseMe ?? 'Surprise me'`. Key l10n sudah ada sebelumnya tapi tak pernah dipakai.
  - Gap 2 (anti-repeat): `randomSuggestionFor()` dapat param opsional `avoid` + `rng` (injectable untuk test deterministik). Pool >1 dan mengandung `avoid` → exclude sebelum random. Caller wiring: `home_screen.dart` pass `_promptCtrl.text` via prop baru `SurpriseMeButton.avoid`; `prompt_suggestion_chip.dart` pass `_current` di `_shuffle()`.
  - Gap 3 (tag coverage): audit produksi via MCP read (`sticker_presets`, 31 preset aktif) menunjukkan **8 preset gambar tanpa satu pun saran match** → selalu fallback ke semua 30 prompt: `caricature`, `chibi_3d`, `lego_voxel`, `minimal_line`, `pixel_art`, `retro_sticker`, `vector_flat` + **`watercolor`** (terlewat di audit awal, ketahuan saat recheck daftar). Cakupan tipis: `origami`(1), `stained_glass`(2), `neon_cyber`(2). Fix: tambah tag pada saran existing tanpa konten baru — kini semua 21 image preset ≥3 match, semua 10 text preset = 6 match.
  - Test kontrak baru: hardcoded 31 preset ID aktif di `test/prompt_suggestions_test.dart`; assert tiap ID ≥3 match di pool masing-masing. Regression net — bukan validator runtime.
  - Bonus: prefix `'Try:'` hardcoded di chip juga di-i18n-kan via key ARB baru `trySuggestion` (EN "Try:", ID "Coba:") dengan placeholder `{suggestion}` + `flutter gen-l10n`.
- **Keputusan Teknis:**
  - Anti-repeat pakai *exclude-last* (param `avoid`), bukan shuffle-bag stateful global: mudah ditest seeded-rng, tanpa state lintas widget, cukup mencegah repeat langsung. Limitasi diakui: nilai sama bisa muncul lagi setelah 1 tekanan lain — acceptable untuk pool 3–15 item.
  - Fallback "semua saran" dipertahankan (bukan disable tombol) karena reasoning layer server (`enhancePrompt`) tetap mengadaptasi prompt apa pun ke style_descriptor preset; UX lebih baik memberi inspirasi daripada tombol mati. Fokus = memperkecil frekuensi fallback lewat tag.
  - Test kontrak pakai hardcoded list (bukan parse migration SQL) agar sederhana dan stabil; preset DB baru yang belum masuk list tidak tertangkap test, tapi fallback menjamin UX aman.
- **File:**
  - `lib/core/constants/prompt_suggestions.dart` (signature `randomSuggestionFor`, docstring, ~15 penambahan tag)
  - `lib/presentation/widgets/surprise_me_button.dart` (l10n label + prop `avoid`)
  - `lib/presentation/widgets/prompt_suggestion_chip.dart` (l10n `trySuggestion` + avoid)
  - `lib/presentation/screens/home/home_screen.dart` (pass `avoid`)
  - `lib/l10n/app_en.arb`, `app_id.arb` (+ generated localizations)
  - `test/prompt_suggestions_test.dart` (+5 test), `pubspec.yaml` (`0.19.1+69`)
  - `plans/2026-08-25-surprise-me-gap-fixes-plan.md`, `TODO.md`
- **Verifikasi:** `flutter pub get`, `flutter analyze` 0 issues, `flutter test` 138/138 (+5), `flutter build apk --split-per-abi` sukses (3 APK).
- **Proposed commit:** `fix(home): localize surprise me labels, prevent repeat suggestions, close preset tag coverage`

### 2026-08-24 | Cloudflare Workers AI Image Provider (Fase 0-1 + Review Remediation)
- **Status:** selesai implementasi Fase 1 (menunggu deploy + patch credential). Fase 2-3 defer.
- **Implementasi:**
  - Migration `20260824000001_add_cloudflare_provider.sql`: extend CHECK `provider_name` += `'cloudflare'`, seed 3 rows (`@cf/black-forest-labs/flux-1-schnell`, `@cf/stabilityai/stable-diffusion-xl-base-1.0`, `@cf/lykon/dreamshaper-8-lcm`) — priority 5 (last-resort setelah pollinations p4), **is_active=false** (remediation H1: cegah alert noise `missing_api_key` sebelum credential dipatch), fallback `always`, timeout 90s, idempotent `WHERE NOT EXISTS`. base_url placeholder `SET_ACCOUNT_ID` agar account id tidak masuk git.
  - `index.ts`: `ProviderName+="cloudflare"`; `callCloudflare()` handle dua bentuk response (JSON `result.image` base64 → sniff magic bytes JPEG/PNG/WebP via `contentTypeFromBytes()`; binary `image/*` → arrayBuffer); `buildCloudflareRequestBody()` allowlist per model family; guard img2img/inpainting (`model_requires_input_image` 422 retryable); case di `callProvider()`.
  - Test `index_test.ts`: 10 test baru (flux JSON success + strip negative, sdxl binary + passthrough params, result-as-string varian, non-image payload rejection, missing key 401 no-fetch, 400 non-retryable, 429 retryable, schema_mismatch kosong, trailing slash, img2img guard).
- **Spike live (Fase 0):** flux=200 JSON b64 JPEG (~173 neurons/4-step); SDXL & DreamShaper=200 binary PNG; error shape `{success:false,errors:[{code,message}]}`. **Temuan kritis: flux-1-schnell menolak `negative_prompt`** dengan 400 code 5006 "Additional or unevaluated properties not allowed" → wajib allowlist param per family.
- **Keputusan Teknis:**
  - Priority 5 last-resort konservatif — tidak mengubah chain existing (live DB terkonfirmasi via MCP read: active chain pixazo p1-p3 + pollinations p4); promosi cukup `UPDATE priority` tanpa redeploy.
  - Seed inactive — aktivasi digabung satu UPDATE dengan patch credential.
  - Allowlist param per model family (flux: `prompt`+`steps`≤8 saja) karena schema Cloudflare strict-reject unknown fields.
  - `.env.example`: hapus `CLOUDFLARE_AI_BASE_URL` override (tidak ada kode yang membacanya — menyesatkan), ganti catatan bahwa base_url hidup di DB row.
- **File:**
  - `supabase/migrations/20260824000001_add_cloudflare_provider.sql` (NEW)
  - `supabase/functions/generate-sticker/index.ts` (ProviderName, callCloudflare, helpers, dispatcher)
  - `supabase/functions/generate-sticker/index_test.ts` (+10 test)
  - `.env.example`, `plans/2026-08-24-cloudflare-workers-ai-provider-plan.md`, `TODO.md`
- **Verifikasi:** deno 80/80; flutter analyze 0 issues; flutter test 133/133. Spike curl live 5 request.
- **Proposed commit:** `feat(providers): add Cloudflare Workers AI image provider with 3 text-to-image models`


### 2026-08-02 | Server-Side Legal Consent Audit
- **Status:** selesai implementasi (menggantung legal review & backend deploy untuk production).
- **Fitur baru:**
  - DB migration `20260802000034_server_side_legal_consent.sql`:
    - `legal_document_versions` registry (4 current docs seeded with SHA-256).
    - Pseudonymous `legal_audit_subjects` + `legal_audit_subject_links` (ON DELETE CASCADE).
    - Append-only `legal_consent_events` (idempotent via `client_request_id`).
    - SECURITY DEFINER RPCs: `get_legal_consent_status`, `accept_current_legal_documents`, `withdraw_current_privacy_consent`.
    - Strict RLS + REVOKE ALL direct table access; only RPC EXECUTE for `authenticated`.
    - `soft_delete_account()` redefined to sever identity link while retaining pseudonymous events.
  - Flutter stack:
    - `LegalConsentRepository` rewritten as Supabase-backed (no local prefs authority).
    - `LegalConsentCubit` + `LegalConsentState` (phases: loading/ready/error + submitting flag).
    - Auth gate reorder: Language → Anonymous session → Remote consent check → Consent → Onboarding/Home.
    - `LegalConsentScreen`: loads asset docs, computes SHA-256, verifies against registry; blocks on mismatch.
    - `LegalConsentErrorScreen`: blocking retry on remote check failure.
    - Privacy withdrawal action in Profile → Danger Zone (withdraws current privacy consent, Terms unaffected).
    - Re-consent forced on version/hash change and on Google identity switch (new userId).
  - New l10n keys: `consentErrorTitle`, `consentErrorBody`, `consentDocsChanged`, `withdrawPrivacy`, `withdrawPrivacySub`, `withdrawPrivacyBody`, `withdrawPrivacyConfirm`.
  - `AppBuildInfo.version` constant for app metadata submitted with each acceptance.
- **File diubah:**
  - `supabase/migrations/20260802000034_server_side_legal_consent.sql` (NEW)
  - `lib/data/repositories/legal_consent_repository.dart`
  - `lib/presentation/blocs/legal_consent/legal_consent_cubit.dart` (NEW)
  - `lib/presentation/blocs/legal_consent/legal_consent_state.dart` (NEW)
  - `lib/presentation/screens/legal/legal_consent_screen.dart`
  - `lib/presentation/screens/legal/legal_consent_error_screen.dart` (NEW)
  - `lib/presentation/screens/profile/profile_screen.dart`
  - `lib/core/app_version.dart` (NEW)
  - `lib/app.dart`
  - `lib/core/di.dart`
  - `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`
  - `pubspec.yaml` (+ crypto, bloc deps; version 0.19.0+68)
- **Verifikasi:** `flutter analyze` 0 issues, `flutter test` 133/133, `flutter build apk --split-per-abi` sukses (3 APK).
- **Proposed commit:** `feat(consent): add server-side legal acceptance audit`

### 2026-08-01 | Multi-Language: English and Bahasa Indonesia
- **Status:** selesai implementasi (menggantung legal review untuk production).
- **Fitur baru:**
  - Flutter Gen L10n diaktifkan di `MaterialApp` dengan delegate, `supportedLocales`, dan `locale` stateful.
  - `LocaleRepository` + `LocaleCubit` menyimpan pilihan bahasa ke SharedPreferences.
  - `LanguageSelectionScreen` muncul sebelum legal consent saat first launch (hanya sekali, di-tracking via key `app.locale.selection_completed`).
  - Bahasa dapat diubah di Profil > Language.
  - Default locale mengikuti device (`id` untuk bahasa Indonesia, `en` untuk lainnya), dengan fallback ke English.
  - Dokumen legal dipisah menjadi 4 file per locale: `privacy-policy-{en,id}.md` dan `terms-of-service-{en,id}.md`.
  - `LegalConsentScreen` memuat dokumen sesuai locale aktif.
  - Semua teks UI utama dipetakan ke ARB (English + Indonesian).
  - Preset dan mission dilokalkan via stable ID dengan fallback ke server text.
  - Caption tetap aturan lama: maksimal 10 karakter, ASCII only (`A-Z 0-9 .!?-`).
- **File diubah:**
  - `lib/data/repositories/locale_repository.dart` (NEW)
  - `lib/presentation/blocs/locale/locale_cubit.dart` (NEW)
  - `lib/presentation/blocs/locale/locale_state.dart` (NEW)
  - `lib/presentation/screens/locale/language_selection_screen.dart` (NEW)
  - `lib/core/localization/preset_localizations.dart` (NEW)
  - `lib/core/localization/mission_localizations.dart` (NEW)
  - `lib/app.dart`, `lib/core/di.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`
  - `lib/presentation/screens/auth/auth_screen.dart`
  - `lib/presentation/screens/home/home_screen.dart`
  - `lib/presentation/screens/legal/legal_consent_screen.dart`
  - `lib/presentation/screens/onboarding/onboarding_screen.dart`
  - `lib/presentation/screens/history/history_screen.dart`
  - `lib/presentation/screens/history/widgets/history_filter_chips.dart`
  - `lib/presentation/screens/history/widgets/history_search_field.dart`
  - `lib/presentation/screens/missions/missions_screen.dart`
  - `lib/presentation/screens/missions/widgets/daily_checkin_card.dart`
  - `lib/presentation/screens/profile/profile_screen.dart`
  - `lib/presentation/screens/packs/packs_list_screen.dart`
  - `lib/presentation/screens/packs/pack_create_screen.dart`
  - `lib/presentation/screens/packs/pack_detail_screen.dart`
  - `docs/privacy-policy-en.md`, `docs/privacy-policy-id.md`, `docs/terms-of-service-en.md`, `docs/terms-of-service-id.md` (NEW)
  - `pubspec.yaml`, `test/legal_documents_test.dart`, `test/onboarding_screen_test.dart`, `test/daily_checkin_card_test.dart`
- **Verifikasi:** `flutter analyze` 0 issues, `flutter test` 133/133.
- **Proposed commit:** `feat(i18n): add English and Indonesian localization with first-launch chooser`

### 2026-08-01 | Code Review Fix: Transparent WhatsApp Sticker Pipeline
- **Status:** selesai (menunggu deploy edge function)
- **Code Review Temuan & Perbaikan:**
  1. **Critical: WebP Encoder Missing** - `encodeWEBP()` tidak ada di ImageScript runtime. **Fix**: `encodeWebPWithinLimit()` sekarang throw `ExtractionError` jika >100KB di quality terendah; WASM encoder evaluation pending untuk deploy.
  2. **Critical: Alpha Validation Incorrect** - `inspectTransparency()` false-positive pada padding non-square. **Fix**: `validateStrictTransparency()` dengan strict corner/ratio checks; inspection dipindah SEBELUM resize.
  3. **High: Tray Icon Not Resized** - `derive-tray-icon` composite tanpa resize. **Fix**: `fit()` sebelum composite ke canvas 96×96.
  4. **High: Cache Bypass Risk** - legacy opaque files undetected. **Fix**: version-based invalidation via sticker `updated_at` (1hr window); Flutter `_isValidWebpCache` cek VP8X alpha flag (0x10).
  5. **High: Style Descriptor Conflicts** - deskripsi minta `dark/white background`, `white border`. **Fix**: `sanitizeVisualGuidance()` strip conflicting background/border dari prompt.
  6. **High: 100KB Limit Not Enforced** - upload tetap lanjut walau oversize. **Fix**: throw `ExtractionError` jika quality terendah masih >100KB.
  7. **Medium: PNG Derivative Non-Fatal** - upload PNG boleh gagal. **Fix**: validasi PNG output di `encodeStickerAssets()`.
  8. **Medium: Native-Transparent Branch** - skip outline/quality gates. **Fix**: `validateStrictTransparency()` + `addWhiteOutline()` pada SEMUA branch accepted.
- **File Diperbaiki:**
  - `supabase/functions/generate-sticker/image_processing.ts` (strict validation, process order)
  - `supabase/functions/generate-sticker/index.ts` (sanitization, strict size, PNG validation)
  - `supabase/functions/derive-tray-icon/index.ts` (resize fix, cache invalidation)
  - `lib/data/repositories/sticker_pack_repository.dart` (VP8X alpha check)
- **Verifikasi:** `deno test` 83/83, `flutter analyze` 0 issues, `flutter test` 143/143, `flutter build apk --split-per-abi` sukses.
- **Proposed commit:** `fix(stickers): harden transparent WebP generation and WhatsApp export`

### 2026-07-14 | Daily Check-in Regression Fix: WIB Timezone + Post-Claim Animation
- **Status:** selesai (menunggu deploy migration `00033`)
- **Perubahan:**
  - **DB cooldown fix**: `load_daily_checkin_streak()` dan `claim_daily_checkin()` sekarang konsisten pakai `AT TIME ZONE 'Asia/Jakarta'::date` untuk semua perbandingan. Cooldown cycle selesai pada 00:00 WIB, bukan UTC midnight. Countdown menghitung sisa detik sampai 00:00 WIB.
  - **Animation classification fix**: Pilih Lottie dari post-claim streak (`state.streak.cycleCompleted`), bukan dari pre-claim `_pendingCheckinDay`. Day 7 → celebration; day 1-6 → flame; start new cycle (day 1 hasil) → flame.
  - **Enum overlay refactor**: Ganti 2 boolean (`_showCelebration`, `_showFlame`) dan 2 method show dengan single enum `CheckinAnimationType` + `_showCheckinAnimation(type, claimedDay)`. Hapus `_pendingCheckinDay`.
  - **Pure helper**: `checkinAnimationFor(DailyCheckinStreak)` di `daily_checkin_streak.dart` — testable tanpa widget tree.
- **Detail:**
  - Migration: `20260714000033_fix_daily_checkin_jakarta_cooldown.sql` (baru, jangan edit `00032`)
  - `lib/data/models/daily_checkin_streak.dart` — enum + helper
  - `lib/presentation/screens/missions/missions_screen.dart` — refactor animation
  - `test/daily_checkin_streak_test.dart` — 3 test `checkinAnimationFor`: flame (day 3), celebration (day 7), flame (start new cycle day 1)
  - `pubspec.yaml`: `0.16.2+61` → `0.16.3+62`
- **Verifikasi:** `flutter analyze` 1 warning pre-existing; `flutter test` 143/143 (+3 pure function tests); `flutter build apk --split-per-abi` sukses.
- **Proposed commit:** `fix(daily-checkin): use WIB timezone for cooldown and post-claim animation`

### 2026-07-14 | Daily Check-in: Flame Animation + Box Marker
- **Status:** selesai (menunggu deploy migration + fire-flame.json ada di assets)
- **Perubahan:**
  - Box "checked-in today" (isCompletedToday) kini render hijau/centang, tidak abu-abu lagi.
  - Lottie flame (`fire-flame.json`) untuk day 1-6 setelah check-in; celebration tetap untuk day 7.
  - `_DayBox` visual state machine refactor: `isCompletedToday` → `isCompleted` (gabung dengan completed sebelumnya). Checkmark emoji ✅ untuk hari ini yang sudah check-in.
  - `missions_screen.dart`: refactor animation timer (enum-based), `_showCheckinFlame()` method, branch logic di listener (day 7 → celebration, else → flame).
  - Widget test: 5 test baru untuk `_DayBox` render states (isToday, isCompletedToday, locked, cycle complete all green, fresh start).
- **Detail:**
  - `lib/presentation/screens/missions/widgets/daily_checkin_card.dart` — `_DayBox.build` visual states
  - `lib/presentation/screens/missions/missions_screen.dart` — flame/celebration Lottie branch
  - `test/daily_checkin_card_test.dart` — 5 widget tests
  - `pubspec.yaml`: `0.16.1+60` → `0.16.2+61`
- **Verifikasi:** `flutter analyze` 1 warning pre-existing; `flutter test` 139/139 lulus.
- **Proposed commit:** `fix(daily-checkin): show completed box state + flame Lottie for streak days`

### 2026-07-14 | Daily Check-in Cycle-Complete Fix
- **Status:** selesai (menunggu deploy migration + data patch)
- **Perubahan:** Fix bug user lihat "Cycle complete!" permanen setelah selesai siklus 7 hari dan tidak bisa check-in keesokan harinya.
  - **Server:** `load_daily_checkin_streak` RPC tambah return kolom `cycle_cooldown_finished` (BOOLEAN) dan `cooldown_remaining_seconds` (INTEGER) untuk memberi tahu client apakah cooldown selesai.
  - **Model:** `DailyCheckinStreak` tambah field `cycleCooldownFinished`, `cooldownRemainingSeconds`. `canClaim` getter sekarang cek cooldown: jika cycle completed tapi cooldown selesai → claim allowed.
  - **UI:** `daily_checkin_card.dart` ganti branch tunggal "Cycle complete!" jadi 3-way: cooldown aktif → "Cycle complete! Next in Xh Ym"; cooldown selesai → "Start new cycle" button; normal → "Check-in" button. `_DayBox.locked` logic update untuk fresh start setelah cooldown.
  - **Test:** tambah 2 test `canClaim` untuk cooldown scenarios + parse `cycle_cooldown_finished`/`cooldown_remaining_seconds`.
- **Detail:**
  - Migration: `20260714000032_daily_checkin_cooldown_flag.sql`
  - `lib/data/models/daily_checkin_streak.dart` — model update
  - `lib/presentation/screens/missions/widgets/daily_checkin_card.dart` — widget update
  - `test/daily_checkin_streak_test.dart` — 2 test baru
- **Verifikasi:** `flutter analyze` (1 warning pre-existing), `flutter test` 134/134 lulus.
- **Data patch (manual):** `UPDATE public.daily_checkin_streaks SET current_streak=0, current_cycle_day=0, cycle_completed_at=NULL, updated_at=now() WHERE user_id='2b9783ab-7829-4536-80fa-eaaf76acec1e';`
- **Proposed commit:** `fix(daily-checkin): show "Start new cycle" button after cooldown elapses`

### 2026-07-12 | Fix Cerebras: Seed Idempotent, Test 429 & Trailing Slash
- **Status:** selesai
- **Perubahan:** Migration seed diubah dari `INSERT ... VALUES ... ON CONFLICT DO NOTHING` menjadi `INSERT ... SELECT ... WHERE NOT EXISTS` berdasarkan combo `(provider_name, route_scope, model_name)`. Tambah 2 unit test: HTTP 429 error mapping dan normalisasi base URL trailing slash.
- **Detail:**
  - Migration `20260712000031` diubah langsung (belum pernah di-deploy).
  - Test 429: assert `ProviderError(429, "provider_http_error")` dengan message mencantumkan `cerebras`.
  - Test trailing slash: config `base_url = "https://api.cerebras.ai/v1/"` menghasilkan request ke `https://api.cerebras.ai/v1/chat/completions` tanpa `//chat`.
- **Verifikasi:** `deno test --no-check` 70/70 lulus.
- **Proposed commit:** `fix(reasoning): harden Cerebras provider seed idempotency and test coverage`

### 2026-07-12 | Cerebras Cloud Reasoning Provider (3 Model)
- **Status:** selesai (menunggu deploy + patch API key)
- **Perubahan:** Tambah Cerebras Cloud sebagai provider reasoning dengan 3 model: `gemma-4-31b`, `zai-glm-4.7`, `gpt-oss-120b`. OpenAI-compatible endpoint.
- **Detail:**
  - Migration `20260712000031`: extend CHECK constraint `provider_name` dengan `cerebras`, seed 3 config route `reasoning`.
  - `ProviderName` extended: `"cerebras"`.
  - `callCerebrasReasoning()`: adapter OpenAI-compatible `/chat/completions`, mapping `max_tokens` ke `max_completion_tokens`, mengambil `reasoning_effort` dan `reasoning_format` dari DB `request_options`.
  - DB-driven reasoning params: message-level `reasoning_effort` dan `reasoning_format` per model via `request_options`, tanpa hardcode di Edge Function.
  - Priority: 4 (gemma-4-31b), 5 (zai-glm-4.7), 6 (gpt-oss-120b).
  - 6 unit test: gemma-4-31b params, GLM tanpa effort, GPT-OSS effort medium, missing key, HTTP 401, empty content.
- **Keputusan Teknis:**
  - Pakai OpenAI-compatible (`/chat/completions`), bukan native model API lain.
  - Mapping `max_tokens` di DB ke `max_completion_tokens` di body Cerebras.
  - `reasoning_format: "parsed"` agar thought tokens tidak mencemari `message.content`.
  - `reasoning_effort: "medium"` hanya untuk Gemma 4 dan GPT-OSS. GLM tidak perlu karena reasoning default aktif.
  - `max_completion_tokens: 800` mengakomodasi reasoning + JSON output.
- **File:**
  - `supabase/migrations/20260712000031_add_cerebras_reasoning_provider.sql` (NEW)
  - `supabase/functions/generate-sticker/index.ts` (ProviderName, callCerebrasReasoning, switch case)
  - `supabase/functions/generate-sticker/index_test.ts` (6 test Cerebras)
  - `.env.example` (Cerebras credential docs)
- **Verifikasi:** `deno test --no-check` 68/68 lulus.
- **Proposed commit:** `feat(reasoning): add Cerebras Cloud fallback provider`

### 2026-07-12 | Fix Review Ollama Cloud Gemini 4: Model ID, API Key Wajib, Test
- **Status:** selesai
- **Perubahan:** Model ID direct API dari `gemma4:31b-cloud` ke `gemma4:31b`. API key kini diverifikasi sebelum HTTP request. Test alert existing diperbaiki kontrak keamanannya. Coverage header Authorization ditambahkan.
- **Detail:**
  - Migration `20260712000030`: update model_name config reasoning ollama.
  - `callOllamaReasoning()`: ganti `cfg.api_key?.trim() ?? ""` dengan `requireApiKey(cfg)` + unconditional `Authorization` header.
  - Test sukses: assert `new Headers(init?.headers).get("Authorization")` aktual.
  - Test no_api_key diganti: assert `ProviderError(401, "missing_api_key")` tanpa fetch call.
  - Test safe alert diperbaiki: verifikasi raw provider error tidak bocor, sambil mengizinkan `error_type` metadata klasifikasi.
  - Semua 62 test Deno lulus (sebelumnya 61/62).
- **File:**
  - `supabase/migrations/20260712000030_fix_ollama_cloud_model_name.sql` (NEW)
  - `supabase/functions/generate-sticker/index.ts` (requireApiKey)
  - `supabase/functions/generate-sticker/index_test.ts` (header assert, missing_key test, safe text test)
- **Verifikasi:** `deno test --no-check` 62/62. `flutter analyze` 1 warning pre-existing. `flutter test` 132/132.
- **Proposed commit:** `fix(reasoning): correct Ollama Cloud model ID, enforce API key, fix test coverage`

### 2026-07-12 | Ollama Cloud Gemma 4 Fallback Reasoning Provider
- **Status:** selesai (menunggu deploy + patch API key)
- **Perubahan:** Tambah Ollama Cloud `gemma4:31b-cloud` sebagai fallback reasoning provider ketiga (Priority 3). API native `POST /api/chat` dengan JSON format enforcement. Failover urut: Pollinations (prioritas 1) → Pollinations (prioritas 2) → Ollama Cloud (prioritas 3) → local fallback prompt.
- **Detail:**
  - Migration `20260712000029`: extend CHECK constraint `provider_name` dengan `'ollama'`, seed config `api_key = NULL`.
  - `ProviderName` extended: `"ollama"`.
  - `callOllamaReasoning()`: adapter Ollama native `/api/chat`, body `stream:false`, `format:"json"`, `options.num_predict`.
  - `callReasoningProvider()`: case `"ollama"`.
  - 7 unit test: success dengan preset guidance, 401 throw, empty content schema_mismatch, no api_key tanpa header, regex fallback, missing message.content.
  - `.env.example`: dokumentasi operasional cara patch API key via SQL Editor.
- **Keputusan Teknis:**
  - Pakai API native Ollama (`/api/chat`) bukan OpenAI-compatible, karena `/v1/chat/completions` tidak tersedia di cloud API.
  - `format: "json"` untuk enforce JSON output tanpa `response_format`.
  - Credential tetap DB-driven (`image_generation_configs.api_key`), konsisten provider lain.
  - `fallback_policy: never` (tidak relevan untuk reasoning loop, tetap continue).
- **File:**
  - `supabase/migrations/20260712000029_add_ollama_reasoning_provider.sql` (NEW)
  - `supabase/functions/generate-sticker/index.ts` (ProviderName, callOllamaReasoning, switch case, exports)
  - `supabase/functions/generate-sticker/index_test.ts` (7 test Ollama)
  - `.env.example` (Ollama credential docs)
- **Verifikasi:** `deno test --no-check --config supabase/functions/generate-sticker/deno.json --allow-env --allow-net supabase/functions/generate-sticker/index_test.ts` — 61/62 lulus (1 pre-existing). `flutter analyze` (1 warning pre-existing). `flutter test` (132/132).
- **Proposed commit:** `feat(reasoning): add Ollama Cloud Gemma 4 as fallback reasoning provider`

### 2026-07-12 | Provider Failure Email Alerts — Harden & Remediation
- **Status:** selesai
- **Perubahan:** Perbaikan dari code review: secret safety (tidak kirim raw provider error), background delivery hardening (`EdgeRuntime.waitUntil()`), config load alerts, test isolation, type fix.
- **Detail:**
  - Alert helpers dipisah ke `operator_alerts.ts`: pure functions tanpa dependensi Supabase env. Test import file ini, bukan `index.ts`.
  - `sendOperatorAlert()` tidak menerima `errorMessage` raw provider. Gunakan `errorType` + `safeAlertText()` → pesan generik aman (no secret, no API key, no provider raw body).
  - `queueOperatorAlert()` menggunakan `EdgeRuntime.waitUntil()` di Supabase, fallback `void` di runtime lain. Tidak perlu `.catch()` di call site.
  - `sanitizeAlertError()` diperluas: JSON `api_key`, `apiKey`, `token`, `access_token`, `client_secret`; header `Authorization`, `x-api-key`; query param key.
  - `alertDedupeKey()` kini pakai `errorType` (fixed string) bukan `errorMessage.slice(0,100)`.
  - Config alert: database error loading image config → `provider_config_load_failed`. Zero active config → `no_active_provider_config`. Kedua dikirim via `queueOperatorAlert()`.
  - `loadPreset()` return type diperbaiki: tambah `reasoning_guidance: string | null`.
  - 46 unit test: klasifikasi status/keyword, safe text, sanitasi (11 format secret), HTML escape, dedupe isolated, no-op tanpa env, fetch failure, config alert body.
  - Test mock: `Deno.env.get` dan `globalThis.fetch` di-restore manual via `try/finally`. `resetAlertDedupeForTest()` di tiap test dedupe.
  - `import.meta.main` tetap dipertahankan untuk defensive start prevention.
- **Keputusan Teknis:**
  - Alert hanya mengirim pesan generik safe berdasarkan `statusCode` + `errorType`. Tanpa raw error provider untuk mencegah kebocoran secret tak terduga.
  - `queueOperatorAlert()` adalah satu-satunya call site. `sendOperatorAlert()` tetap publik untuk test langsung.
  - Config load alert menggunakan provider `configuration`, phase sesuai konteks. Dedupe key `phase|configuration|error_type|status`.
- **File:**
  - `supabase/functions/generate-sticker/operator_alerts.ts` (NEW — module alert)
  - `supabase/functions/generate-sticker/index_test.ts` (46 test)
  - `supabase/functions/generate-sticker/index.ts` (import module, queueOperatorAlert, config alert, loadPreset type)
  - `.env.example` (sebelumnya)
- **Verifikasi:** `flutter test` (132/132). Deno: `deno test --config supabase/functions/generate-sticker/deno.json --allow-env --allow-net supabase/functions/generate-sticker/index_test.ts`.
- **Proposed commit:** `fix(alerts): harden provider alert delivery and secret redaction`

### 2026-07-12 | Provider Failure Email Alerts (Initial)
- **Status:** selesai
- **Perubahan:** Kirim email alert best-effort ke operator saat provider reasoning atau generate sticker gagal karena credential, konfigurasi, quota, billing, model/endpoint tidak ditemukan, atau provider tidak didukung. Timeout (408) dan 5xx tidak di-alert karena failover menangani. Dedupe in-memory per instance Edge Function (5 menit).
- **Detail:**
  - `sendOperatorAlert()` — fire-and-forget via Resend API, 5 detik timeout, tidak pernah throw.
  - `shouldAlertProviderIssue()` — filter HTTP status + 13 keyword case-insensitive.
  - `sanitizeAlertError()` — redact Authorization header, API key, Ocp-Apim-Subscription-Key, key query param.
  - `escapeHtml()` — HTML escape untuk body email.
  - `alertDedupeKey()` + `_alertDedupeCache` — maksimal satu email per (phase, provider, config, status, error) per 5 menit.
  - Integrasi alert di `enhancePrompt()` catch block (tiap reasoning provider gagal).
  - Integrasi alert di `callImageProviderChain()` catch block (tiap image provider gagal).
  - `requestId` diteruskan ke `ProviderAttemptContext` dan `enhancePrompt()`.
  - Lock leak fix: `releaseGenerationLock()` dipanggil sebelum return 400 saat preset tidak ditemukan atau text-only > 20 karakter.
  - Env vars: `RESEND_API_KEY`, `OPERATOR_ALERT_TO`, `OPERATOR_ALERT_FROM`, `APP_NAME`. Kosong = no-op.
  - `APP_NAME` default `BikinStiker`; `OPERATOR_ALERT_TO` dukung comma-separated recipients.
  - `import.meta.main` guard agar `Deno.serve` tidak aktif saat modul di-import test.
  - 35 unit test: klasifikasi alert, sanitasi secret, HTML escape, dedupe, no-op, fetch failure.
- **Keputusan Teknis:**
  - Alert bersifat best-effort dan tidak pernah blocking primary flow.
  - Dedupe in-memory per instance (bukan database) karena menambah observability tanpa state tambahan.
  - Credential provider dari DB (`image_generation_configs.api_key`), bukan env vars.
- **File:**
  - `supabase/functions/generate-sticker/index.ts` (helper alert, integrasi, lock fix)
  - `supabase/functions/generate-sticker/index_test.ts` (NEW — 35 unit test)
  - `.env.example` (tambah env alert)
- **Verifikasi:** `flutter pub get`, `flutter analyze`, `flutter test` (132/132). Deno test: `deno test --allow-env --allow-net supabase/functions/generate-sticker/index_test.ts`.
- **Proposed commit:** `feat(alerts): email operators for actionable sticker provider failures`

### 2026-07-12 | Onboarding Core Flow (Generate → Pack → WhatsApp)
- **Status:** selesai
- **Perubahan:** Tambah onboarding 3 langkah untuk core flow setelah legal consent dan sesi guest/auth siap. Tampil sekali per perangkat via `SharedPreferences`. Bisa replay dari Profile.
- **Detail:**
  - Step 1: Generate sticker (prompt + style).
  - Step 2: Add sticker ke pack dengan emoji.
  - Step 3: Export pack ke WhatsApp (min 3 sticker).
  - Skip 1 tap, `Back`, `Next`, dan `Create My First Sticker`.
  - Gate di `_AuthGate` setelah `AuthStatus.authenticated` / `AuthStatus.guest`.
  - Replay di Profile > How It Works, tanpa mengubah completion.
  - Contextual guidance inline: "Next: add this sticker to a pack" setelah generate; snackbar dinamis saat add to pack; pack-ready callout di pack detail.
- **File:**
  - `lib/data/repositories/onboarding_repository.dart` (NEW)
  - `lib/presentation/screens/onboarding/onboarding_screen.dart` (NEW)
  - `test/onboarding_repository_test.dart` (NEW)
  - `test/onboarding_screen_test.dart` (NEW)
  - `plans/2026-07-12-core-flow-onboarding-plan.md` (NEW)
  - `lib/core/di.dart` (register repo)
  - `lib/app.dart` (gate)
  - `lib/presentation/screens/profile/profile_screen.dart` (How It Works)
  - `lib/presentation/screens/home/home_screen.dart` (inline guidance)
  - `lib/presentation/widgets/add_to_pack_sheet.dart` (dynamic snackbar)
  - `lib/presentation/screens/packs/pack_detail_screen.dart` (pack-ready callout)
- **Verifikasi:** `flutter analyze` (0 error selain pre-existing), `flutter test` (132/132).
- **Proposed commit:** `feat(onboarding): guide users through sticker generation, packs, and WhatsApp export`

### 2026-07-12 | Fix Credit History Filter Earnings (PostgREST 22P02)
- **Status:** selesai
- **Masalah:** Filter Earnings kirim enum `admin_grant` ke PostgREST, tapi `transaction_type` di PostgreSQL tidak punya nilai itu → `22P02`.
- **Akar:** Enum Dart `CreditTxType.adminGrant` ada di aplikasi tapi tidak pernah ditambah ke DB via migration. RPC `admin_grant_credits` catat sebagai `topup`.
- **Perbaikan:** Hapus enum dari model, mapping repository, filter bloc, label display. Filter Earnings kirim 5 tipe valid: `topup`, `daily_reward`, `refund`, `subscription_grant`, `mission_reward`. Grant admin tetap tampil sebagai "Top Up" (nilai DB asli).
- **File:** `lib/data/models/credit_transaction.dart`, `lib/data/repositories/credit_transaction_repository.dart`, `lib/presentation/blocs/credit_transactions/credit_transactions_bloc.dart`, `lib/presentation/screens/profile/profile_screen.dart`, `test/credit_transaction_test.dart`, `test/credit_transactions_bloc_test.dart`
- **Verifikasi:** `flutter analyze` (0 error), `flutter test` (121/121).
- **Proposed commit:** `fix(profile): remove invalid admin_grant enum from earnings filter causing PostgREST 22P02`

### 2026-07-10 | Fix AdMob SSV Signature Verification
- **Status:** selesai (deploy terblokir)
- **Masalah:** AdMob menandatangani query setelah percent-decoding, tapi `admob-ssv` verifikasi terhadap query encoded → 401.
- **Perbaikan:** `decodeURIComponent()` sebelum ECDSA verify.
- **File:** `supabase/functions/admob-ssv/index.ts`, `plans/2026-07-10-fix-admob-ssv-signature-verification.md` (NEW)
- **Blocker:** Supabase CLI belum login.
- **Proposed commit:** `fix(admob): verify SSV signatures against decoded callback content`

### 2026-07-09 | Credit Reward Amounts (Watch Ad & Share)
- **Status:** selesai
- **Perubahan:** Reward watch ad & share social: free=2 credit, plus=3 credit.
- **File:** `supabase/migrations/20260709000028_update_mission_rewards.sql` (NEW)

### 2026-07-09 | Critical Credit Integrity C4-C7
- **Status:** selesai
- **Temuan:** Code review lanjutan — 4 celah critical:
  - **C4:** Guest migration mati — RPC via service-role kehilangan `auth.uid()`. Edge Functions beralih ke `userClient`.
  - **C5:** Response parsing `RETURNS TABLE` salah. Fix array handling.
  - **C6:** Monthly grant ledger catat full amount walau balance di-cap. Fix: ledger hanya `v_actual_grant`.
  - **C7:** Tidak ada `CHECK (amount <> 0)` dan sign consistency di `credit_transactions`. Fix: constraint `NOT VALID`.
- **File:**
  - `supabase/functions/create-guest-migration/index.ts`
  - `supabase/functions/migrate-guest-stickers/index.ts`
  - `supabase/migrations/20260709000025_fix_monthly_grant_ledger.sql` (NEW)
  - `supabase/migrations/20260709000026_fix_credit_tx_constraints.sql` (NEW)
  - `supabase/migrations/20260709000027_fix_daily_checkin_reference_id.sql` (NEW)
  - `plans/2026-07-09-fix-critical-c4-c7.md` (NEW)
- **Verifikasi:** `supabase db push` + smoke test per plan.
- **Proposed commit:** `fix(critical): fix guest migration auth context, monthly grant ledger, and credit tx constraints`

### 2026-07-08 | Security Credit Integrity C1-C3
- **Status:** selesai
- **Temuan:** 3 celah integritas kredit:
  - **C1:** `consume_share_token` grant ke `auth.uid()` = NULL di service-role. Fix: RPC `complete_mission_for_user`.
  - **C2:** `complete_mission` bisa dipanggil langsung user untuk `ad_reward`/`share_app`. Fix: RAISE EXCEPTION; reward hanya via service-role.
  - **C3:** `claim_daily_checkin` update wallet tanpa `LEAST(..., tier_cap)` → langgar balance cap. Fix: pakai `LEAST`.
- **Prerequisite:** AdMob SSV implementation (C2 butuh SSV untuk `ad_reward`).

### 2026-07-08 | Reward Config Sentralisasi (DB-Driven)
- **Status:** selesai
- **Perubahan:** Pindahkan semua reward credit dari hardcode RPC ke DB. Tabel baru: `seasons`, `reward_configs`, `mission_rewards`. Reward dukung tier-based + seasonal.
- **File:**
  - `supabase/migrations/20260708000023_reward_config_sentralisasi.sql` (NEW)
  - `lib/data/models/mission_reward.dart` (NEW)
  - `lib/data/models/mission.dart`, `lib/data/repositories/mission_repository.dart`
  - `lib/presentation/screens/missions/missions_screen.dart`, `lib/presentation/screens/missions/widgets/daily_checkin_card.dart`
- **Proposed commit:** `feat(rewards): centralize reward config into DB with tier + season support`

### 2026-07-07 | Bugfix: Watch Ad Error Code 3
- **Status:** selesai
- **Masalah:** `ADMOB_REWARDED_*` diisi banner test ID, bukan rewarded test ID → "Ad unit doesn't match format".
- **Perbaikan:** Ganti env ke rewarded test ID (`5224354917` Android / `1712485313` iOS).

### 2026-07-07 | AdMob SSV Implementation
- **Status:** selesai
- **Perubahan:** Edge Function `admob-ssv` verifikasi signature ECDSA Google, dedup via `ad_ssv_events`, grant via `complete_mission_for_user`. Client polling singkat menunggu grant.
- **File:** `supabase/functions/admob-ssv/index.ts`

### 2026-07-06 | Share-to-Social-Media (Server-Verified)
- **Status:** selesai
- **Perubahan:** Reward hanya diberikan setelah link benar-benar dibuka. Server mint single-use token (10 min) → share sheet → recipient buka link → Edge Function consume → grant → 302 ke app.
- **File:**
  - `supabase/migrations/20260706114120_share_tokens_and_rpcs.sql` (NEW)
  - `supabase/functions/share-redirect/index.ts` (NEW)
  - `supabase/functions/share-redirect/deno.json` (NEW)
  - `lib/core/services/share_mission_service.dart` (NEW)
  - Multi-platform deep link config (Android App Link + iOS Universal Link)
  - Bloc/screen/widget updates
- **Keputusan Teknis:** Nonce 24 byte, single-use, atomic UPDATE. Cold-start claim via `consumeInitialLink()`.
- **Proposed commit:** `feat(missions): verify share_app_daily via single-use short link`

### 2026-07-06 | Analyze Fix: Share Mission
- **Status:** selesai
- **Masalah:** Error analyzer pada fitur share mission: API `share_plus 10.1.4` tidak cocok, import kurang, deklarasi `_unused` ganda.
- **File:** `lib/core/services/share_mission_service.dart`, `lib/presentation/blocs/mission/mission_bloc.dart`, `lib/presentation/screens/missions/missions_screen.dart`
- **Proposed commit:** `fix(missions): resolve share mission analyzer errors`

### 2026-07-05 | Feedback & Analytics (Rate Up/Down)
- **Status:** selesai
- **Perubahan:** User rate up/down hasil generate (thumbs + reason tags). 9 analytic views untuk performa provider, model reasoning, generate image.
- **File:** `supabase/migrations/20260705000001_generation_feedback_analytics.sql` (NEW), `supabase/migrations/20260705000002_analytics_views.sql` (NEW)
- **Proposed commit:** `feat(feedback): add sticker rating (up/down + reason tags) and 9 provider/model analytics views`

### 2026-07-05 | Banner Ads Multi-Location
- **Status:** selesai
- **Perubahan:** AdMob Banner Ads di 5 lokasi (Home, History, Missions, Profile, Packs) dengan unique ad unit ID per lokasi.
- **File:**
  - `lib/core/services/ad_config_service.dart` (NEW)
  - `lib/presentation/widgets/ads_banner_widget.dart` (NEW)
  - `lib/presentation/widgets/ads_banner_placeholder.dart` (replace)
  - 5 screen files (tambah banner), `lib/main.dart` (MobileAds init), `.env` (5 keys)

### 2026-07-05 | Analytics Migration Fix
- **Status:** selesai
- **Masalah:** `supabase db push` error — alias scope SQL, kolom nama tidak konsisten, correlated subquery.
- **Perbaikan:** Non-destruktif, hanya ubah definisi view.
- **File:** `supabase/migrations/20260705000002_analytics_views.sql`
- **Proposed commit:** `fix(analytics): correct analytics view aliases and grouped health dashboard`

### 2026-07-04 | Profile Polish: Filter, Subscription, Packs, Check-in
- **Status:** selesai
- **Perubahan:**
  - Filter Credit History: All/Earnings/Spent/Rewards pakai `Set<CreditTxType>`.
  - Info Next Monthly Credit di subscription section.
  - PackCard thumbnail pakai stiker pertama (fallback generic).
  - PackCard padding fix.
  - PackDetail cache lokal WebP sebelum jaringan.
  - Daily Check-in Lottie overlay + day box bounce.
- **File:**
  - `lib/data/repositories/credit_transaction_repository.dart`, `lib/presentation/blocs/credit_transactions/credit_transactions_bloc.dart`, `lib/presentation/screens/profile/profile_screen.dart`
  - `lib/data/models/sticker_pack.dart`, `lib/presentation/blocs/sticker_pack/sticker_pack_bloc.dart`, `lib/presentation/widgets/pack_card.dart`, `lib/presentation/screens/packs/pack_detail_screen.dart`
  - `lib/presentation/widgets/lottie_overlay.dart` (NEW), `lib/data/models/subscription_next_grant.dart` (NEW)
  - `lib/presentation/screens/missions/missions_screen.dart`, `lib/presentation/screens/missions/widgets/daily_checkin_card.dart`
- **Proposed commit:** `fix(profile): broaden earnings filter and show next grant date for subscription`
