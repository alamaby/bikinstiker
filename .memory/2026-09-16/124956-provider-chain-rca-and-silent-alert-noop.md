# Provider Chain RCA + Silent Operator Alert No-Op

Date: 2026-09-16 12:49:56
Plan: `plans/2026-09-16-provider-chain-rca-and-silent-alert-remediation-plan.md`

## Task / Problem

Analisis 10 log LLM terakhir (`prompt_enhancement_logs` + `image_generation_attempt_logs`)
di produksi, lalu jawab kenapa alert email operator tidak pernah terkirim.

## Key Files Changed

- `supabase/functions/generate-sticker/operator_alerts.ts`
- `supabase/functions/generate-sticker/index.ts`
- `supabase/functions/generate-sticker/index_test.ts`
- `supabase/functions/surprise-me/index.ts`
- `supabase/migrations/20260916000001_remediate_provider_chain_rca.sql` (NEW, applied)
- `supabase/migrations/20260916065125_operator_alert_sink.sql` (NEW, applied)
- `supabase/migrations/20260916071704_deactivate_archived_cerebras_model.sql` (NEW, applied)
- `plans/2026-09-16-provider-chain-rca-and-silent-alert-remediation-plan.md` (NEW)

## Decisions

- **RCA inti:** tiga fault drift saling menutupi. Ollama p1 `401 Unauthorized` sejak 2026-09-11
  (terakhir sukses 09-10); Cerebras p2 `gemma-4-31b` diarsipkan upstream (`404 model_archived_error`
  pada 09-16, sebelumnya `model_not_found`); Cloudflare p1 `route_scope='default'` aktif dengan
  `api_key IS NULL` + `base_url` placeholder `SET_ACCOUNT_ID` sejak 09-02 (10/10 attempt gagal,
  membakar attempt #1 setiap generation). Rantai reasoning menyusut ke `openrouter/free` saja
  (lifetime 27 ok / 51 fail) yang gagal senyap ke `buildFinalPrompt()` deterministik —
  `sticker_generations` tetap mencatat 48/48 sukses, jadi degradasi tak terlihat.
- **Alert tidak terkirim** karena guard `if (!apiKey || !toRaw || !from) return;` di
  `operator_alerts.ts:88` tanpa log apa pun. Bukan "kirim gagal" — memang tidak pernah dikirim,
  dan tak terbedakan dari sukses.
- **Deteksi alert diperluas** ke `errorType` (`missing_api_key`, `schema_mismatch`, `opaque_output`,
  `prompt_leak`, dll) karena kegagalan dominan OpenRouter (422) sebelumnya tidak pernah alertable.
- **`safeAlertText`**: error sintetis sisi kita (`missing_api_key`) tidak lagi dilaporkan sebagai
  "Provider rejected authentication".
- **Dedupe**: slot diklaim sebelum fetch, dilepas bila kirim gagal, sehingga insiden nyata tidak
  ter-mute 5 menit; tetap per-isolate (utang teknis). Slot baru diklaim **setelah** validasi
  recipient, jadi `OPERATOR_ALERT_TO=" , "` tidak lagi mengonsumsi/membekukan alert.
- **Guard runtime `partitionRunnableConfigs()`**: membuang config aktif tanpa `api_key` (kecuali
  `pollinations`) atau ber-`base_url` placeholder, dengan `console.warn` per config.
- **Migrasi non-destruktif**: menonaktifkan Cloudflare default tak-berkredensial + cerebras
  `gemma-4-31b`; **tidak** menonaktifkan Ollama (401 mungkin transien, kualitas terbaik saat sehat);
  menambah partial index + view health. Tidak menyentuh kredensial dan tidak menghapus baris.
- **DB alert sink (keputusan pemilik)**: email-only adalah desain yang rapuh — satu secret hilang
  dan seluruh kanal mati. Alert sekarang **selalu** ditulis ke `public.operator_alerts` lebih dulu
  (RLS deny-all, service_role only), email Resend jadi kanal kedua opsional. `email_status`
  merekam hasil kanal email (`sent`/`deduped`/`skipped_unconfigured`/`skipped_no_recipients`/`failed`).
- **`queueOperatorAlert(params, service)`**: service client diteruskan eksplisit, bukan module-level
  singleton — menghindari race antar request konkuren di isolate Edge yang sama.
- **`sanitizeStoredError()`**: error provider di-redact (Authorization/key/token) dan dipotong 500
  char sebelum masuk DB; body error provider bisa memantulkan header auth.
- **Lesson (regresi kredensial)**: patch kredensial harus **hanya** menyentuh kolom kredensial.
  Backfill `is_active = TRUE` massal per-provider menghidupkan kembali model known-bad.

## Assumptions / Risks

- ~~Isi secret alert tidak bisa diverifikasi~~ **Terjawab**: `supabase secrets list` menunjukkan
  `RESEND_API_KEY` / `OPERATOR_ALERT_TO` / `OPERATOR_ALERT_FROM` tidak pernah ada. Guard lama
  `return` senyap pada setiap insiden — RCA alert tervalidasi definitif.
- `partitionRunnableConfigs` heuristik placeholder bisa salah tandai URL sah yang memuat `<`;
  pola dibatasi kata kunci konfigurasi lazim + 4 unit test.
- Dedupe masih per-isolate → bisa spam setelah cold start.
- `prompt_enhancement_logs.sticker_generation_id` selalu `null` → korelasi ke hasil akhir via timestamp.
- `updateAlertEmailStatus` mencocokkan baris via `(provider,config,errorType,requestId)`; satu request
  bisa menghasilkan >1 insiden identik hanya bila errorType sama untuk provider berbeda — `provider_name`
  ada di kriteria sehingga aman.

## Verification

- `deno check index.ts` bersih untuk `generate-sticker` dan `surprise-me`.
- `deno test`: generate-sticker **134/134**, surprise-me **15/15**; `_shared` 6, `list-presets` 7,
  `showcase-preview` 6, `showcase-purchase-copy` 13 semuanya lulus.
- 22 tes baru: warn-saat-secret-kosong, deteksi berbasis `errorType`, `safeAlertText` sintetis,
  dedupe release-on-failure / keep-on-success, recipient kosong (warn + tidak konsumsi slot),
  `partitionRunnableConfigs` (4 kasus), DB sink (`recordOperatorAlert` 5 kasus, `sanitizeStoredError` 2,
  `dispatchOperatorAlert` 2).
- Simulasi dampak migrasi via query baca-saja: hanya 1 baris Cloudflare + 1 baris Cerebras
  tersentuh; sisa aktif 4 default + 2 reasoning (ollama, openrouter).
- Produksi: migrasi `20260916000001`, `20260916065125` & `20260916071704` **ter-apply** (dikonfirmasi
  via `supabase_migrations.schema_migrations` + `information_schema.columns`). Edge function sudah
  dideploy oleh pemilik: `generate-sticker` **v38**, `surprise-me` **v6**; verifikasi `get_edge_function`
  menunjukkan 12/12 marker kode baru PRESENT dan marker lama ABSENT.

## Blockers / Unresolved

- ~~Deploy edge function~~ **Selesai** (v38 / v6).
- **Regresi pasca-patch kredensial (sudah diperbaiki)**: backfill key Cerebras memakai
  `SET is_active = TRUE` massal untuk semua row cerebras, sehingga `gemma-4-31b` (archived)
  aktif kembali pada p2. Migrasi `20260916071704` menonaktifkannya lagi. Rantai reasoning final:
  ollama p1 → openrouter p3 → cerebras `zai-glm-4.7` p5 → cerebras `gpt-oss-120b` p6.
  **Pelajaran:** jangan `UPDATE ... SET is_active = TRUE` massal per-provider saat patch kredensial.
- Cloudflare default (`@cf/black-forest-labs/flux-1-schnell`) masih nonaktif; aktifkan hanya setelah
  `base_url` (account id real) + `api_key` dipatch dalam satu UPDATE.
- Opsional: provisioning Resend untuk kanal email; tanpa itu insiden tetap tercatat di `operator_alerts`.

## Commit Proposal

`fix(providers): persist operator alerts to DB sink and alert on silent email no-op`
