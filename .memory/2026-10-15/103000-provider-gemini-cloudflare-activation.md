# Provider Activation: Gemini fallback + Cloudflare draft — 2026-10-15

## Task / Problem
Susun urutan prioritas rantai gambar: Gemini Free sebagai mid-fallback
sekarang, Cloudflare Workers Free sebagai primary menyusul (butuh Account
ID + API token yang belum ada).

## Key files changed (submodule bikinstiker-supabase)
- `supabase/functions/generate-sticker/index.ts` (`callGemini`): hapus
  pengiriman `generationConfig.negativePrompt` — field tidak ada di API
  resmi Gemini (`responseModalities` saja yang valid), berisiko 400 setiap
  reasoning menghasilkan negative prompt (hampir selalu). Param jadi
  `_negative` (diabaikan; avoidance tetap di positive prompt).
- `supabase/migrations/20261015000002_activate_gemini_image_fallback.sql`
  (NEW): flag flip `is_active=true`, priority 13. Rantai akhir:
  Pixazo Flux (p2,3,5) -> Gemini 2.5-flash-image (p13) -> Pollinations
  Flux (p100); semua `fallback_policy='always'`.
- Cloudflare TIDAK disentuh (3 config tetap inactive, tanpa key,
  base_url placeholder) — draft aktivasi di bawah, manual oleh owner.

## Decisions
- Gemini p13 (biarkan prioritas lama): Pixazo tetap primary (blast radius
  nol), Gemini mid-fallback, Pollinations terakhir. Minimal change.
- Cloudflare Flux p1 sebagai primary ditunda sampai kredensial siap;
  rollout aman via `image_generation_user_overrides` (uji di user sendiri
  tanpa memengaruhi user lain).
- Privacy Gemini: keputusan unpaid+disclosure vs billing-aktif ditunda ke
  owner (menyentuh Privacy Policy).

## Assumptions / Risks
- Model `gemini-2.5-flash-image` GA, pensiun 2027-03-15; free ±500 RPD
  (klaim pihak ketiga) vs demand ~1/14 hari — longgar.
- Unpaid quota => Google boleh pakai prompt/output untuk training + human
  review; jangan kirim data sensitif. Counter: user ID di luar EEA/UK
  tidak dapat proteksi Paid otomatis.
- Cloudflare: lisensi Flux Apache-2.0 OK; SDXL/DreamShaper wajib cek link
  Terms di docs Cloudflare saat aktivasi; ketentuan komersial Workers AI
  tidak eksplisit ("verify before shipping").
- Deploy edge function `generate-sticker` WAJIB setelah merge (kode berubah)
  + `db push` migrasi — keduanya BELUM dijalankan.

## Verification
- `deno test index_test.ts`: 125 passed, 0 failed.
- `deno check index.ts`: OK.
- `deno lint`: 8 problem pre-existing (STICKER_SIZE, buildPositiveFallback,
  callPixazoFlux negative, require-await x3, dsb. — SK5 known); tidak ada
  dari perubahan ini.

## Cloudflare activation draft (MANUAL, jangan commit secret)
```sql
-- via Supabase dashboard SQL editor, setelah buat token di
-- dash.cloudflare.com (butuh izin Workers AI) + catat Account ID:
UPDATE public.image_generation_configs
SET base_url = 'https://api.cloudflare.com/client/v4/accounts/<ACCOUNT_ID>/ai/run',
    api_key = '<CLOUDFLARE_API_TOKEN>'
WHERE provider_name = 'cloudflare'
  AND model_name = '@cf/black-forest-labs/flux-1-schnell';
-- smoke test via user override dulu, lalu:
UPDATE public.image_generation_configs
SET is_active = true, priority = 1
WHERE provider_name = 'cloudflare'
  AND model_name = '@cf/black-forest-labs/flux-1-schnell';
-- SDXL/DreamShaper: aktifkan hanya setelah lisensi diverifikasi.
```

## Commit proposal
submodule: `feat(provider): activate gemini image fallback, drop invalid negativePrompt`
superproject: `chore(providers): wire gemini fallback activation`
