# Ollama Cloud Gemma 4 Reasoning Fallback

Created: 2026-07-12 18:00:00

## Objective
Tambah Ollama Cloud `gemma4:31b-cloud` sebagai provider reasoning fallback BikinStiker. Pollinations tetap prioritas pertama.

## Scope
- Tambah provider `ollama` pada constraint `image_generation_configs.provider_name`.
- Seed konfigurasi reasoning Ollama Cloud sebagai priority 3, sesudah dua konfigurasi Pollinations saat ini.
- Tambah request adapter Ollama native API di `generate-sticker`.
- Jaga cache, observability, email alert, parsing, dan silent fallback existing.
- Tambah test untuk format request/respons dan kegagalan provider.
- Dokumentasikan setup API key tanpa menyimpan secret di repo.

## Milestones
1. Database config dan secret setup. ✅
2. Adapter Ollama Cloud pada Edge Function. ✅
3. Test dan verifikasi lokal. ✅
4. Deploy, setup credential, dan smoke test. (pending — butuh akses Supabase CLI / Dashboard)

## Tasks
- [x] Migration `supabase/migrations/20260712000029_add_ollama_reasoning_provider.sql`.
- [x] Drop dan recreate CHECK constraint dengan `ollama`.
- [x] Insert config reasoning `ollama` tanpa `api_key`, `ON CONFLICT DO NOTHING`.
- [x] Provider config: `provider_name=ollama`, `model_name=gemma4:31b-cloud`, `base_url=https://ollama.com`, `priority=3`, `route_scope=reasoning`, `timeout_ms=30000`.
- [x] Tambah `"ollama"` ke tipe `ProviderName`.
- [x] Tambah `callOllamaReasoning()`: `POST ${baseUrl}/api/chat`, header `Authorization: Bearer <api_key>`, body `stream:false format:"json" options.num_predict`.
- [x] Tambah case `"ollama"` pada `callReasoningProvider()`.
- [x] Export `callOllamaReasoning`, `ImageGenerationConfig`, `ProviderError`, `ProviderName`, `FallbackPolicy` untuk test.
- [x] Perbarui `.env.example` dengan dokumentasi operasional Ollama.
- [x] 7 unit test: success, success with preset guidance, 401 throw, empty content, no api_key, non-JSON fallback, missing message.content.
- [x] Jalankan `deno test --no-check --config supabase/functions/generate-sticker/deno.json --allow-env --allow-net supabase/functions/generate-sticker/index_test.ts`.
- [x] Jalankan `flutter analyze` (1 warning pre-existing).
- [x] Jalankan `flutter test` (132/132 lulus).

### Pending (manual)
- [ ] Deploy migration: `supabase db push`.
- [ ] Isi API key Ollama di Supabase Dashboard: `UPDATE image_generation_configs SET api_key = '...' WHERE provider_name = 'ollama' AND route_scope = 'reasoning';`

## Risks
- Ollama Cloud API membutuhkan key. Jika key tidak dipatch, reasoning Gemma 4 gagal → fallback prompt lokal digunakan (tidak crash). ⚠️ Tanpa key kini throw `ProviderError` segera, bukan kirim HTTP request sia-sia.
- Ollama Cloud model bisa deprecated. Jika terjadi, seed row menjadi inactive dan reasoning fallback ke lokal.
- API native Ollama (`/api/chat`) berbeda format dengan OpenAI-compatible. Jika Ollama mengubah respons `message.content`, parser perlu adaptasi.

## Progress Log
- 2026-07-12 18:00:00 — Scope dipilih.
- 2026-07-12 18:00:00 — Implementasi awal selesai.
- 2026-07-12 18:00:00 — 🔧 Review fix: model ID diperbaiki ke `gemma4:31b`, key diwajibkan, test coverage diperkuat.

## Notes
- Saat ini priority 3, setelah Cerebras (priority 4-6) ditambahkan setelah Ollama.
- Rujukan Ollama: https://docs.ollama.com/cloud
- Model direct API: `gemma4:31b` (tanpa `-cloud`; suffix cloud untuk daemon lokal).
- Direct cloud API: `POST https://ollama.com/api/chat` dengan header `Authorization: Bearer <OLLAMA_API_KEY>`.
- API key WAJIB; fungsi `requireApiKey` gagal duluan sebelum HTTP.
- Credential DB-driven (konsisten dengan provider BikinStiker lain).
- Deployment command: `supabase db push` lalu patch `api_key` via SQL Editor.
- Proposed commit: `feat(reasoning): add Ollama Cloud Gemma 4 as fallback reasoning provider`
