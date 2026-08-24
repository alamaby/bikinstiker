# Cloudflare Workers AI Provider Plan

Created: 2026-08-24 00:00:00

## Objective
Menambahkan Cloudflare Workers AI sebagai provider image generation baru di `supabase/functions/generate-sticker`, mencakup 7 model yang diminta, terintegrasi dengan sistem failover DB-driven yang sudah ada (`image_generation_configs`). Nilai real credential disimpan di `.env` (tidak commit), sample di `.env.example`.

Models target:
- `https://developers.cloudflare.com/workers-ai/models/stable-diffusion-xl-lightning/` — `@cf/bytedance/stable-diffusion-xl-lightning`
- `https://developers.cloudflare.com/workers-ai/models/flux-2-klein-4b/` — `@cf/black-forest-labs/flux-2-klein-4b`
- `https://developers.cloudflare.com/workers-ai/models/flux-1-schnell/` — `@cf/black-forest-labs/flux-1-schnell`
- `https://developers.cloudflare.com/workers-ai/models/dreamshaper-8-lcm/` — `@cf/lykon/dreamshaper-8-lcm`
- `https://developers.cloudflare.com/workers-ai/models/stable-diffusion-v1-5-img2img/` — `@cf/runwayml/stable-diffusion-v1-5-img2img`
- `https://developers.cloudflare.com/workers-ai/models/stable-diffusion-v1-5-inpainting/` — `@cf/runwayml/stable-diffusion-v1-5-inpainting`
- `https://developers.cloudflare.com/workers-ai/models/stable-diffusion-xl-base-1.0/` — `@cf/stabilityai/stable-diffusion-xl-base-1.0`

## Scope
- In scope: Edge Function `generate-sticker` (`supabase/functions/generate-sticker/index.ts:97`, `callProvider():808`, `callImageProviderChain():1374`), migrasi `image_generation_configs` (`20260626000005`), `.env.example` credential docs, operator alerts (`operator_alerts.ts:72`), image post-processing tetap via `image_processing.ts`.
- Out scope awal: UI Flutter untuk img2img/inpainting (butuh upload `image_b64` + `mask`) — ditunda ke Fase 3.
- Env: hanya tambah sample di `.env.example`; nilai real di `.env` (gitignored). Tidak ada `supabase secrets set` untuk provider image (DB-driven), konsisten `pixazo`/`ollama`/`cerebras`.

## Milestones
1. Fase 0 — Persiapan & validasi REST contract (0.5d)
2. Fase 1 — Core `cloudflare` text-to-image (3 model stabil) (2-3d)
3. Fase 2 — Perluasan text-to-image (2 model tambahan: xl-lightning + flux-2-klein) (1-2d)
4. Fase 3 — img2img & inpainting (butuh perubahan kontrak input) (3-5d, optional)
5. Fase 4 — Observability, docs & cleanup (0.5d)

## Tasks
- [x] Fase 0.1 — Spike `curl` ke `POST https://api.cloudflare.com/client/v4/accounts/{ACCOUNT_ID}/ai/run/@cf/black-forest-labs/flux-1-schnell` untuk konfirmasi format response (JSON `{result:{image:base64}}` vs `image/*` binary) — tentukan branch parsing di `callCloudflare()`. **Done**: flux=JSON b64 JPEG; sdxl/dreamshaper=binary PNG; error shape `{success:false,errors:[{code,message}]}`.
- [x] Fase 0.2 — Putuskan storage credential: **base_url penuh account-scoped** di DB dengan placeholder `SET_ACCOUNT_ID` di migrasi (account id tidak masuk git); patch real account id + token post-deploy dalam satu UPDATE.
- [x] Fase 0.3 — Putuskan prioritas: **Cloudflare priority 5 (last-resort)** — konservatif, tidak mengubah perilaku provider existing; promosi via `UPDATE priority` tanpa redeploy. (Deviasi dari opsi p1.)
- [x] Fase 1.1 — Migration `supabase/migrations/20260824000001_add_cloudflare_provider.sql`: CHECK constraint + seed 3 rows idempotent (`WHERE NOT EXISTS`). **Catatan**: `timeout_ms=90000` (bukan 60000) mengikuti pola pixazo karena SDXL 20-step butuh >30s.
- [x] Fase 1.2 — `index.ts`: `ProviderName+="cloudflare"`, interface `CloudflareImageResponse`, `contentTypeFromBytes()` sniff JPEG/PNG/WebP magic bytes, `buildCloudflareRequestBody()` allowlist per-model-family (flux: hanya `prompt`+`steps`; SD family: +`negative_prompt`,`num_steps`,`height`,`width`,`guidance`,`seed`), `callCloudflare()` handle JSON base64 & binary, guard img2img/inpainting (`model_requires_input_image`), case dispatcher.
- [x] Fase 1.3 — Unit test: 8 test baru (flux JSON success + strip negative_prompt, sdxl binary success + passthrough params, missing key, 400 non-retryable, 429 retryable, JSON tanpa image schema_mismatch, trailing slash, img2img guard). Total 78/78 lulus.
- [ ] Fase 1.5 — Manual verify end-to-end: `supabase db push` migrasi + patch credential + `supabase functions deploy generate-sticker` + generate sticker real via app (pending user).
- [ ] Fase 2.1 — Migration tambahan 2 rows (`sdxl-lightning`, `flux-2-klein-4b`) reuse `callCloudflare`.
- [ ] Fase 2.2 — Test regression prioritas `priority ASC, created_at ASC` (`loadDefaultConfigs():850`).
- [ ] Fase 3.1 — Design kontrak baru untuk img2img/inpainting: field `image_b64` + `mask` optional di request `generate-sticker`, validasi `strength` 0-1, update Flutter.
- [ ] Fase 3.2 — `callCloudflare` cabang img2img/inpainting (guard sudah ada).
- [ ] Fase 3.3 — UI Flutter: picker image + mask editor (defer sampai demand ada) — alternatif: Edge Function terpisah `refine-sticker`.
- [ ] Fase 4.1 — Label analytics + verifikasi alert redaction `Authorization: Bearer` (sudah tercakup `sanitizeAlertError` existing — cek coverage header Bearer).
- [ ] Fase 4.2 — Verifikasi produksi: `image_generation_provider_attempt_analytics` menampilkan cloudflare rows.

## Risks
- Response Cloudflare REST belum 100% pasti (JSON vs binary) — butuh spike `curl` sebelum code freeze; mitigasi handle keduanya.
- `base_url` mengandung `ACCOUNT_ID` → leak di log/alert; mitigasi `sanitizeAlertError` redact query `key` + `api_key`.
- `flux-2-klein-4b` doc minim (multipart object required) → risiko 400 schema; mitigasi tunda ke Fase 2.
- img2img/inpainting butuh perubahan API publik + storage RLS → risiko scope creep; mitigasi pisah Fase 3.
- Billing per step/tile ($0.000053/512 tile) → butuh `fallback_policy='always'` + monitor `prompt_enhancement_logs`/`attempt_logs`.
- Migrasi `priority` bump bisa menggeser urutan failover existing; mitigasi idempotent `WHERE NOT EXISTS` + test `loadConfigsForRequest():897`.

## Progress Log
- 2026-08-24 00:00:00 — Plan dibuat. 7 model diklasifikasi: 5 text-to-image, 1 img2img, 1 inpainting. Draft `.env.example` disiapkan (2 var: `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`). Investigasi provider existing selesai (`pixazo` multi-model pattern `callPixazo():796`).
- 2026-08-24 00:05:00 — `.env.example` di-update dengan blok Cloudflare (DB-driven docs). TODO + PROJECT_MEMORY di-update.
- 2026-08-24 01:30:00 — **Fase 0 selesai (spike live)**: flux-1-schnell=200 JSON `result.image` base64 JPEG (~173 neurons/4 step); sdxl-base-1.0=200 binary PNG; dreamshaper-8-lcm=200 binary PNG; error shape `{success:false,errors:[{code,message}]}` (404 no-route code 7000). **Temuan kritis**: flux-1-schnell menolak `negative_prompt` dgn 400 code 5006 "Additional or unevaluated properties not allowed" → adapter wajib allowlist param per model family.
- 2026-08-24 02:00:00 — **Fase 1 selesai**: migrasi `20260824000001_add_cloudflare_provider.sql` (CHECK+seed 3 rows p5 always 90s), adapter `callCloudflare()` + `buildCloudflareRequestBody()` + `contentTypeFromBytes()` di index.ts, dispatcher case, guard img2img/inpainting. Verifikasi: deno test 78/78 (+8 baru), flutter analyze 0 issues, flutter test 133/133. Pending user: `supabase db push` + patch credential + deploy function (Fase 1.5).
- 2026-08-24 03:00:00 — **Review + remediation selesai**. Temuan: (H1) seed `is_active=true` tanpa credential → alert noise `missing_api_key`; dikonfirmasi via MCP read prod DB bahwa migrasi belum ter-deploy & chain aktif live = pixazo p1-p3 + pollinations p4 → migrasi diedit in-place jadi `is_active=false` + aktivasi digabung patch credential. (M1) flux-2-klein-4b multipart tidak kompatibel adapter JSON — dicatat di Fase 2, wajib live-test schema dulu. (M2) `.env.example` `CLOUDFLARE_AI_BASE_URL` tidak dibaca kode → dihapus. (L1) +2 test: result-as-string varian, non-image payload rejection → deno 80/80. Live prod DB juga menunjukkan config produksi banyak di-hand-tune pasca-deploy (policy/model berbeda dari seed migrasi) — normal, seed tetap idempotent.

## Notes
- Referensi domain standar: tidak ada deviasi TM Forum ODA / TOGAF untuk provider ini.
- Provider image lain tidak berubah; `verify_jwt = true` di `supabase/config.toml:38` tetap.
- Key rotation: `UPDATE public.image_generation_configs SET api_key='...' WHERE provider_name='cloudflare'` — satu token shared untuk semua model `@cf/*` di account yang sama.
- Alternatif dipertimbangkan: simpan `ACCOUNT_ID` di `request_options` — ditolak karena menyimpang dari pola `base_url` penuh yang dipakai `pixazo` (`https://gateway.pixazo.ai/...`).
