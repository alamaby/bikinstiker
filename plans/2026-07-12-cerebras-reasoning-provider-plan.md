# Cerebras Cloud Reasoning Provider

Created: 2026-07-12

## Objective
Tambah Cerebras sebagai provider fallback route `reasoning` untuk BikinStiker.

## Scope
- Supabase backend: migration + Edge Function + test.
- Tidak ada perubahan Flutter.

## Tasks
- [x] Migration `20260712000031`: extend CHECK + seed 3 config (gemma-4-31b, zai-glm-4.7, gpt-oss-120b).
- [x] `ProviderName` extended: `"cerebras"`.
- [x] `callCerebrasReasoning()`: OpenAI-compatible adapter.
- [x] DB-driven reasoning params via `request_options` (reasoning_effort, reasoning_format).
- [x] Switch case `"cerebras"`.
- [x] 6 unit test.
- [x] `.env.example` + `PROJECT_MEMORY.md`.
- [x] Deno test 68/68.

### Pending (manual)
- [ ] `supabase db push`.
- [ ] Patch satu `CEREBRAS_API_KEY` ke tiga row Cerebras via SQL Editor.
- [ ] Deploy `generate-sticker` Edge Function.
- [ ] Smoke test: cek prompt_enhancement_logs provider `cerebras`.

## Risks
- `max_completion_tokens: 800` perlu monitoring; jika banyak schema_mismatch, naikkan.
- Satu API key dipakai tiga model; rotasi key harus update semua row `provider_name = 'cerebras'`.

## Progress Log
- 2026-07-12 — Migration + adapter + test selesai. 68/68 Deno test lulus.

## Notes
- Endpoint: `https://api.cerebras.ai/v1/chat/completions`
- Model IDs: `gemma-4-31b`, `zai-glm-4.7`, `gpt-oss-120b`
- Reasoning doc: https://inference-docs.cerebras.ai/capabilities/reasoning
- Proposed commit: `feat(reasoning): add Cerebras Cloud fallback provider`
