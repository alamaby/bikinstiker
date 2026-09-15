# Migrasi flutter_markdown → flutter_markdown_plus

Date: 2026-09-15
Time: 16:21:23
Topic: migrate-flutter-markdown-to-plus
Status: done (analyze/test/build + commit `f3fda05`)

## Task / Problem
`flutter_markdown 0.7.7+1` discontinued (30 Mei 2025) - changelog terakhirnya hanya menandai discontinued. Perlu pindah ke pengganti resmi tanpa mengubah perilaku rendering dokumen legal.

## Key Files Changed
- `pubspec.yaml` - `flutter_markdown: ^0.7.7+1` → `flutter_markdown_plus: ^1.0.12`; versi app `0.26.5+87` → `0.26.6+88`
- `pubspec.lock` - lockfile di-regenerate
- `lib/presentation/screens/legal/legal_consent_screen.dart:6` - import diganti
- `test/markdown_render_test.dart` (NEW) - regression test widget (heading, bullet list, tabel gaya legal + `Table` widget)
- `plans/2026-09-15-migrate-flutter-markdown-to-plus.md` (NEW)

## Technical / Business Decisions
- Pilih Opsi A (drop-in fork) ketimbang hapus dependency dan render manual: API `Markdown`/`MarkdownStyleSheet` identik, pemakaian proyek hanya dasar (tanpa `onTapLink`/`bulletBuilder`/LaTeX/custom builder) sehingga breaking change historis (`bulletBuilder` → `MarkdownBulletParameters`) tak terdampak.
- Bump patch + build number sebagai maintenance, bukan minor feature.

## Assumptions & Risks
- Maintainer bukan Google lagi (Foresight Mobile, proyek kecil; golden test sempat di-disable sementara). Mitigasi: skor pub 160/160, rilis patch rutin, surface bug kecil.
- Uji visual dokumen legal di device nyata belum dijalankan - hanya widget test render. Dokumen markdown asli EN+ID tetap diverifikasi `legal_documents_test.dart`.

## Blockers / Unresolved
- Tidak ada.

## Verification
- `flutter pub get` OK
- `flutter analyze` 0 issue
- `flutter test` 198/198 (197 lama + 1 baru)
- `flutter build apk --split-per-abi` sukses 3 ABI (armeabi-v7a 21.4MB, arm64-v8a 23.3MB, x86_64 24.7MB)

## Commit
- `fix(deps): migrate flutter_markdown to flutter_markdown_plus (discontinued)` (`f3fda05`)

## Related
- Plan: `plans/2026-09-15-migrate-flutter-markdown-to-plus.md`
