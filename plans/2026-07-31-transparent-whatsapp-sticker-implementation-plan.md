# Transparent WhatsApp Sticker - Implementation Plan

Created: 2026-07-31 16:04:16

## Objective

Hilangkan background kotak putih pada stiker WhatsApp. Stiker baru diproses dengan
chroma background extraction di Edge Function: provider menghasilkan background
magenta solid, edge-connected flood-fill menghapusnya, white outline dibuat
programatik. Stiker lama TIDAK diproses ulang (scope dikunci oleh user).

## Scope

- Stiker baru saja. Stiker lama tetap memakai asset lama; user generate ulang bila ingin versi transparan.
- Ubah prompt: hapus `pure white background` dan `thick white border`, tambah flat chroma magenta `#FF00FF` + margin.
- Edge Function chroma extraction: perimeter detect, flood-fill edge-connected, soft alpha, despill, white outline.
- Quality gate: output tidak aman -> ProviderError retryable -> failover ke provider berikutnya.
- Normalisasi PNG/WebP transparan 512x512 (tanpa `canvas.fill(0xFFFFFFFF)`).
- Tray icon transparan 96x96.
- Flutter cache namespace baru `pack_stickers_v2` + alpha validation.
- WhatsApp `image_data_version` "1" -> "2".
- Version bump `0.16.3+62` -> `0.16.4+63`.
- Tanpa provider baru, tanpa API background-removal berbayar.

## Out of Scope

- Legacy sticker conversion (Opsi A dikunci user).
- Animated stickers, iOS StickerPack.
- Migrasi asset original lama.
- Perubahan schema DB (tidak diperlukan untuk scope stiker baru).

## Milestones

1. Plan + baseline
2. Image processing module (`image_processing.ts`)
3. Prompt + integrasi generate-sticker
4. Tray icon transparan
5. Flutter cache v2 + ContentProvider + exporter
6. Test + dokumentasi + verifikasi

## Tasks

- [x] Tulis plan file ini
- [x] Buat `supabase/functions/generate-sticker/image_processing.ts`
- [x] Integrasi ke `generate-sticker/index.ts`
- [x] Test `image_processing_test.ts` (13 test, lulus)
- [x] Update `derive-tray-icon/index.ts`: transparent canvas 96x96
- [x] Flutter `sticker_pack_repository.dart`: `pack_stickers_v2` + alpha check VP8X
- [x] Flutter `whatsapp_pack_exporter.dart`: path v2 + `image_data_version` "2"
- [x] Android `StickerContentProvider.kt`: path `pack_stickers_v2`
- [x] `pack_detail_screen.dart`: path v2
- [x] Bump `pubspec.yaml` 0.16.4+63
- [x] Update README.md + docs/terms-of-service.md + PROJECT_MEMORY.md
- [x] Verifikasi Flutter: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --split-per-abi`
- [ ] Deploy edge functions (pending, butuh Supabase CLI)
- [ ] Smoke test WhatsApp (light/dark theme) setelah deploy

## Risks

- Provider mengabaikan chroma / gradient background -> quality gate reject + failover.
- Objek mengandung magenta -> flood-fill edge-connected + despill hanya di fringe.
- Foreground menyentuh tepi -> prompt margin + reject bila foreground ratio tinggi.
- Halo chroma dari JPEG -> soft alpha + despill + Lab-ish distance.
- WebP > 100 KB -> quality fallback loop.
- Tray icon cached lama masih putih -> cache lokal di-flush; tray re-derive dari PNG transparan baru.

## Progress Log

- 2026-07-31 16:04:16 — Root cause dikonfirmasi: prompt `pure white background`, `canvas.fill(0xFFFFFFFF)`, PNG derivative putih, tray icon putih, config OpenRouter JPEG. Scope stiker-baru-saja diputuskan (Opsi A).
- 2026-07-31 16:20:00 — Build mode. Plan file dibuat. Implementation dimulai.
- 2026-07-31 17:10:00 — Implementasi selesai. `image_processing.ts` + 13 test lulus. Integrasi `index.ts` (processing retryable di chain, `encodeStickerAssets`), `derive-tray-icon` transparan, Flutter cache v2 + alpha validation, `image_data_version` 2, pubspec 0.16.4+63. Bug `rgbaAt` tanpa `*4` diperbaiki.
- 2026-07-31 17:45:00 — Verifikasi bersih: `deno test` 83/83 (13 + 70), `flutter analyze` 0 issue, `flutter test` 143/143, `flutter build apk --split-per-abi` sukses. Plan task verifikasi dicentang. Menunggu deploy edge functions.

## Notes

- TOGAF diterapkan proporsional (bugfix, bukan enterprise).
- ImageScript 1.2.15: `Image.decode`, `bitmap` RGBA non-premultiplied, `encodeWEBP(quality)`, `encode()` PNG.
- Threshold awal: perimeter uniformity >= 0.8, transparent ratio 0.05..0.90, outline radius 10px @512, inner tolerance ~35 / outer ~70 (distance RGB). Kalibrasi via fixture.
- Proposed commit: `fix(stickers): transparent backgrounds via chroma extraction for new stickers`
