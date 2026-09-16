# Provider Chain RCA + Silent Operator Alert Remediation

Created: 2026-09-16 12:49:56

## Objective

Menjelaskan dan memperbaiki dua cacat produksi yang saling terkait pada rantai provider LLM
BikinStiker: (1) rantai reasoning/image yang rusak karena drift konfigurasi + model provider
usang, dan (2) kanal alert operator (`Resend`) yang gagal secara senyap sehingga kerusakan itu
tidak pernah terdeteksi.

## Scope

- Analisis 10 log LLM terakhir di `prompt_enhancement_logs` + `image_generation_attempt_logs`.
- Validasi silang ke `image_generation_configs` (kredensial, aktif, placeholder URL).
- Perbaikan observability + deteksi alert di `operator_alerts.ts` dan call site-nya.
- **DB alert sink** (`operator_alerts`) sebagai kanal primer yang selalu berhasil; email Resend jadi kanal kedua opsional.
- Guard runtime agar config aktif-tapi-tak-usable tidak lagi membakar attempt/latency.
- Migrasi remediasi non-destruktif + view health untuk operator.
- **Di luar scope:** rotasi kredensial produksi (Ollama/Cloudflare/Cerebras) — itu tindakan PATCH
  manual lewat SQL Editor oleh pemilik; skema reward/billing; perubahan Flutter.

## Milestones

1. Fase 1 — Evidence & RCA (baca-saja).
2. Fase 2 — Perbaikan kanal alert + deteksi.
3. Fase 3 — Guard runtime config tak-usable.
4. Fase 4 — Migrasi remediasi non-destruktif.
5. Fase 5 — Verifikasi (deno check/test) & handoff patch kredensial.

## Tasks

### Fase 1 — Evidence & RCA
- [x] Tarik 10 log terakhir `prompt_enhancement_logs` + pasangan `image_generation_attempt_logs`.
- [x] Validasi `image_generation_configs`: kredensial, `is_active`, placeholder `base_url`.
- [x] Konfirmasi efek hilir di `sticker_generations` (48/48 sukses = degradasi senyap).
- [x] Telusuri mengapa email alert tidak terkirim.

### Fase 2 — Alert channel + detection
- [x] `console.warn` saat env alert kurang (sebut nama var yang hilang + konteks insiden).
- [x] `ALERTABLE_ERROR_TYPES` — deteksi berbasis `errorType` (422 `schema_mismatch`, `missing_api_key`, `opaque_output`, dll).
- [x] `safeAlertText` memetakan error sintetis kita sendiri (mis. `missing_api_key`) bukan sebagai "Provider rejected auth".
- [x] Tambah keyword `archived`/`deprecated` pada deteksi berbasis pesan.
- [x] Dedupe: klaim slot sebelum fetch, **lepaskan bila kirim gagal** + log kegagalan dengan konteks.
- [x] Recipient list kosong (`OPERATOR_ALERT_TO` = `" , "`) juga berisik + tidak mengonsumsi slot dedupe.
- [x] Tes baru: warn-saat-secret-kosong, errorType-based detection, dedupe release/keep, recipient kosong.

### Fase 3 — Runtime guard
- [x] `partitionRunnableConfigs()` — buang config aktif tanpa `api_key` (kecuali `pollinations`) atau `base_url` placeholder, dengan `console.warn` per config.
- [x] Terapkan di `loadReasoningConfigs()` dan `callImageProviderChain()`.
- [x] `surprise-me`: alert `no_active_provider_config` ketika rantai reasoning kosong.
- [x] Tes `partitionRunnableConfigs` (4 kasus).

### Fase 4 — Migrasi remediasi
- [x] `20260916000001_remediate_provider_chain_rca.sql`: nonaktifkan Cloudflare default tanpa key / ber-placeholder.
- [x] Nonaktifkan cerebras `gemma-4-31b` (diarsipkan upstream) + catat alasan di `notes`.
- [x] Sengaja **tidak** menonaktifkan ollama (401 bisa transien) — didokumentasikan sebagai aksi manual.
- [x] Partial index `idx_image_generation_configs_unconfigured` + view `image_generation_active_configs_health`.
- [x] Revoke view dari `anon, authenticated, PUBLIC`; grant ke `service_role`.
- [x] **Applied ke produksi** (`20260916000001`, dikonfirmasi via `supabase_migrations.schema_migrations`).

### Fase 4b — DB alert sink (durable, selalu tercatat)
- [x] `20260916065125_operator_alert_sink.sql`: tabel `public.operator_alerts` + 3 index + RLS deny-all + view `operator_alerts_needing_attention`.
- [x] **Applied ke produksi** via MCP `apply_migration`; 15 kolom terverifikasi.
- [x] `operator_alerts.ts`: `recordOperatorAlert()` (menerima `service`), `updateAlertEmailStatus()`, `dispatchOperatorAlert()`.
- [x] `queueOperatorAlert(params, service)` — DB sink dulu, email belakangan; `service` diteruskan eksplisit (bukan module singleton, menghindari race antar-request di isolate yang sama).
- [x] `sanitizeStoredError()` — redact + truncate 500 char sebelum disimpan.
- [x] `errorMessage` ditambahkan ke `OperatorAlertParams` dan diisi di kelima call site.
- [x] `failoverWillContinue` surprise-me dihitung benar (sisa config dalam pass ini, atau masih ada pass kedua).
- [x] 9 tes baru untuk DB sink + sanitize + dispatch.

### Fase 4c — Deploy & regresi pasca-patch kredensial
- [x] Edge function terdeploy: `generate-sticker` **v38**, `surprise-me` **v6** (dikonfirmasi via `list_edge_functions`).
- [x] Verifikasi kode live: 12/12 marker baru PRESENT, marker lama ABSENT (via `get_edge_function`).
- [x] Patch kredensial Ollama + Cerebras dikerjakan pemilik.
- [x] **Regresi terdeteksi & diperbaiki**: UPDATE backfill key Cerebras ikut `SET is_active = TRUE` ke semua row cerebras, sehingga `gemma-4-31b` (archived) aktif kembali. Migrasi `20260916071704_deactivate_archived_cerebras_model.sql` di-apply untuk menonaktifkannya lagi.
- [x] Rantai reasoning final: ollama p1, openrouter p3, cerebras `zai-glm-4.7` p5, cerebras `gpt-oss-120b` p6.

### Fase 5 — Verifikasi & handoff
- [x] `deno check index.ts` bersih (generate-sticker & surprise-me).
- [x] `deno test`: generate-sticker **134/134**; surprise-me 15/15; `_shared` 6, `list-presets` 7, `showcase-preview` 6, `showcase-purchase-copy` 13 semuanya lulus.
- [x] Simulasi dampak migrasi via query baca-saja: tepat 1 baris Cloudflare (step1+step2) dan 1 baris Cerebras (step3) tersentuh; sisa aktif = 4 default + 2 reasoning.
- [x] **Konfirmasi definitif RCA:** `supabase secrets list` menunjukkan `RESEND_API_KEY` / `OPERATOR_ALERT_TO` / `OPERATOR_ALERT_FROM` **tidak pernah ada** — guard lama `return` senyap pada setiap insiden.
- [x] Verifikasi produksi: `image_generation_active_configs_health` menunjukkan Cloudflare + cerebras `gemma-4-31b` sudah `is_active=false`.
- [ ] **Smoke test end-to-end:** jalankan satu generation nyata, lalu pastikan `operator_alerts` terisi bila ada insiden dan `prompt_enhancement_logs` tidak lagi habis ke fallback.
- [ ] **Opsional:** provisioning Resend (set 3 secret) untuk kanal email; tanpa itu insiden tetap tercatat di `operator_alerts`.
- [x] **Catatan operasional:** jangan pernah `UPDATE ... SET is_active = TRUE` secara massal per-provider saat patch kredensial — model known-bad (mis. Cerebras archived) akan ikut aktif kembali.

## Risks

- **Migrasi menonaktifkan Cloudflare p1** → failover image kehilangan satu lapis. Mitigasi: baris ini memang selalu gagal `missing_api_key`, jadi tak ada kehilangan nyata; Pixazo p2 sudah menjadi provider efektif.
- **Dedupe per-isolate** — masih bisa spam email setelah cold start. Belum diperbaiki (butuh dedupe persisten di DB); dicatat sebagai utang teknis.
- **Ollama dibiarkan aktif** — memutuskan apakah 401 = key revoked vs akun suspended butuh uji di luar DB; bila ternyata permanen, rantai reasoning tetap mencoba 1× per request sampai dinonaktifkan manual.
- **`partitionRunnableConfigs` heuristik placeholder** bisa salah menandai URL sah yang kebetulan memuat `<`. Mitigasi: pola dibatasi kata kunci konfigurasi yang lazim (`SET_ACCOUNT_ID`, `PLACEHOLDER`, `CHANGEME`, `YOUR_`, `<...>`), plus 4 unit test.
- **`sticker_generation_id` selalu null** di `prompt_enhancement_logs` (enhance jalan sebelum row dibuat) — korelasi hasil akhir harus via timestamp. Tidak diperbaiki di iterasi ini.
- **DB sink = single point** — jika insert ke `operator_alerts` gagal, insiden hanya tersisa di `function_logs`. Mitigasi: `recordOperatorAlert` men-`console.error` kegagalan, dan `dispatchOperatorAlert` memperingatkan bila insiden tak tercatat di mana pun.
- **Volume `operator_alerts`** bisa tumbuh tanpa batas (satu baris per insiden, tanpa dedupe di DB — dedupe hanya di email). Belum ada retensi/purge; perlu pemantauan ukuran.
- **Deploy belum dilakukan** — semua perbaikan kode belum aktif di produksi; sampai redeploy, perilaku lama masih berlaku.

## Progress Log

- 2026-09-16 12:49:56 — RCA selesai (Fase 1) dan perbaikan kode dieksekusi (Fase 2–4). Mengubah `operator_alerts.ts` (warn senyap, `ALERTABLE_ERROR_TYPES`, `safeAlertText`, rilis dedupe saat gagal), `generate-sticker/index.ts` (`partitionRunnableConfigs` + penerapan), `surprise-me/index.ts` (alert config kosong), kedua `index_test.ts` (+13 tes). Migrasi remediasi `20260916000001_remediate_provider_chain_rca.sql` ditulis (belum di-apply ke produksi). Verifikasi lokal: deno check bersih, 125/125 + 15/15 tes lulus. Pending: patch kredensial + `db push` + redeploy oleh pemilik.
- 2026-09-16 13:05:00 — Remediasi kedua: guard recipient kosong (`OPERATOR_ALERT_TO=" , "`) kini berisik dan tidak lagi mengonsumsi slot dedupe (dipindah setelah validasi recipient). Simulasi dampak migrasi dijalankan baca-saja terhadap produksi: 2 baris tersentuh, sisa 4 default + 2 reasoning aktif (ollama + openrouter). Semua suite fungsi hijau.
- 2026-09-16 13:55:00 — Migrasi `20260916000001` dikonfirmasi **sudah ter-apply** di produksi (`schema_migrations` + `image_generation_active_configs_health`). `supabase secrets list` membuktikan tiga env alert tidak pernah ada → RCA alert tervalidasi definitif. Sesuai keputusan pemilik, ditambahkan **DB alert sink**: migrasi `20260916065125_operator_alert_sink.sql` (tabel + view + RLS deny-all) di-apply via MCP; `operator_alerts.ts` di-refactor agar DB write selalu terjadi lebih dulu, email jadi kanal kedua opsional; `queueOperatorAlert` menerima `service` eksplisit. generate-sticker 134/134, surprise-me 15/15, semua suite hijau. Produksi **belum** menjalankan kode baru — edge function masih versi lama (diverifikasi lewat `get_edge_function`), deploy menunggu `supabase login` pemilik.
- 2026-09-16 14:17:04 — Pemilik deploy kedua edge function (`generate-sticker` v38, `surprise-me` v6) dan patch kredensial Ollama + Cerebras. Verifikasi kode live: 12/12 marker baru PRESENT, marker lama ABSENT. **Regresi ditemukan**: backfill key Cerebras ikut `SET is_active = TRUE` massal sehingga `gemma-4-31b` (archived) aktif kembali; diperbaiki lewat migrasi `20260916071704_deactivate_archived_cerebras_model.sql` (ter-apply). File migrasi lokal di-rename agar versinya cocok dengan `schema_migrations` (`...065125`, `...071704`) sehingga `db push` berikutnya tidak menganggapnya migrasi baru.

## Notes

- **Standar referensi:** domain ini adalah rating/billing berbasis pemakaian (kredit + biaya per
  generation), sehingga mengacu Oracle C2M + TM Forum ODA. Tidak ada deviasi struktural: perubahan
  hanya pada *routing* provider (proses bisnis ops), bukan model domain atau skema tagihan.
- **Temuan inti RCA:** tiga fault drift yang saling menutupi — Ollama 401 (sejak 09-11), Cerebras
  `gemma-4-31b` diarsipkan upstream (09-16), Cloudflare default `api_key IS NULL` + `base_url`
  placeholder tapi `is_active=TRUE` (sejak 09-02). Rantai reasoning menyusut ke `openrouter/free`
  saja (lifetime 27 ok / 51 fail) dan gagal senyap ke `buildFinalPrompt()` deterministik.
- **Temuan alert:** `sendOperatorAlert` `return` tanpa log saat salah satu dari tiga env kosong —
  sehingga "belum dikonfigurasi" tak terbedakan dari "terkirim".
- Keputusan sadar: **tidak** menambah constraint NOT NULL/CHECK pada `api_key` (karena
  `pollinations` sah tanpa key); guardrail diletakkan sebagai partial index + guard runtime.
