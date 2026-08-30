# Perbaikan Review Ollama Cloud Reasoning

Created: 2026-07-12

## Objective
Perbaiki integrasi Ollama Cloud reasoning berdasarkan temuan review: model ID direct API, validasi API key, cakupan test header autentikasi, dan test suite Deno yang gagal.

## Scope
- Ubah model Ollama Cloud direct API menjadi `gemma4:31b`. ✅
- Wajibkan API key untuk provider Ollama Cloud. ✅
- Perbaiki test alert existing agar kontrak keamanan test terpenuhi. ✅
- Jalankan verifikasi Deno dan Flutter. ✅

## Tasks
- [x] Migration baru koreksi model name `gemma4:31b-cloud` → `gemma4:31b`.
- [x] Ubah `callOllamaReasoning()`: pakai `requireApiKey(cfg)`, unconditional `Authorization`.
- [x] Test sukses: assert `new Headers(init?.headers)` untuk Authorization dan Content-Type.
- [x] Ganti test no_api_key: assert `ProviderError(401, "missing_api_key")`, fetch tidak dipanggil.
- [x] Test safe alert: verifikasi raw provider error (Bearer, api_key, API_KEY) tidak bocor; error_type metadata diizinkan.
- [x] Deno test 62/62.
- [x] Flutter analyze (1 warning pre-existing).
- [x] Flutter test 132/132.

## Progress Log
- 2026-07-12 — Review menemukan model salah, key belum diwajibkan, assertion header tidak valid, test alert existing gagal.
- 2026-07-12 — Migration `20260712000030` dibuat.
- 2026-07-12 — `callOllamaReasoning` hardening selesai (`requireApiKey`).
- 2026-07-12 — Semua test Deno diperbaiki (62/62). Flutter test (132/132).
- 2026-07-12 — Dokumentasi diperbarui.

## Notes
- Direct Cloud API model ID: `gemma4:31b` (tanpa `-cloud`).
- API key WAJIB; tanpa key throw `ProviderError(401, "missing_api_key")` sebelum HTTP.
- Proposed commit: `fix(reasoning): correct Ollama Cloud model ID, enforce API key, fix test coverage`
