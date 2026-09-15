# Migrasi flutter_markdown ke flutter_markdown_plus

Created: 2026-09-15 15:32:08

## Objective
Ganti dependency `flutter_markdown` (discontinued, versi terakhir `0.7.7+1`) dengan `flutter_markdown_plus` (pengganti resmi oleh Foresight Mobile) tanpa mengubah perilaku rendering dokumen legal, lalu verifikasi build/test dan bump versi aplikasi.

## Scope
- `pubspec.yaml`: hapus `flutter_markdown: ^0.7.7+1`, tambah `flutter_markdown_plus: ^1.0.12`.
- `lib/presentation/screens/legal/legal_consent_screen.dart`: ganti import.
- Bump versi `0.26.5+87` -> `0.26.6+88` (maintenance/patch).
- Regenerate `pubspec.lock`.
- Verifikasi: analyze, test, build APK split-per-abi, smoke render tab Privacy/Terms EN+ID.
- Update `PROJECT_MEMORY.md`.

## Milestones
1. Persist plan + bump versi.
2. Migrasi dependency (pubspec + import).
3. Verifikasi statis & dinamis (pub get, analyze, test, build).
4. Dokumentasi project memory + commit proposal.

## Tasks
- [x] Tulis plan file ini
- [x] Bump `pubspec.yaml` versi ke `0.26.6+88`
- [x] Ganti dependency ke `flutter_markdown_plus: ^1.0.12`
- [x] Ganti import di `legal_consent_screen.dart`
- [x] `flutter pub get`
- [x] `flutter analyze`
- [x] `flutter test` (198/198, +1 test widget baru)
- [x] `flutter build apk --split-per-abi` (3 ABI sukses)
- [x] Smoke test render dokumen legal via widget test (heading/list/tabel EN; dokumen ID dicek `legal_documents_test.dart`)
- [x] Update `PROJECT_MEMORY.md`

## Risks
- Maintainer bukan Google lagi (Foresight Mobile, proyek kecil). Mitigasi: skor pub 160/160, rilis patch rutin, pemakaian kita sederhana (tanpa `onTapLink`/`bulletBuilder`/LaTeX/custom builder).
- Breaking change historis `bulletBuilder` -> `MarkdownBulletParameters` tidak berdampak (tidak dipakai).
- Perbedaan rendering minor pada tabel/heading tidak terduga. Mitigasi: smoke test visual EN+ID.
- `flutter_markdown_plus` butuh Dart >= 3.4 / Flutter >= 3.22; proyek di Flutter 3.41.7 / Dart 3.11.5 (aman).

## Progress Log
- 2026-09-15 15:32:08 — Plan dibuat. Menunggu eksekusi migrasi.
- 2026-09-15 16:20:00 — Eksekusi selesai. `flutter_markdown` dihapus, `flutter_markdown_plus 1.0.12` terpasang; import `legal_consent_screen.dart:6` diganti; versi naik ke `0.26.6+88`. Verifikasi: `flutter pub get` OK, `flutter analyze` 0 issue (57.6s), `flutter test` 198/198 (197 lama + 1 test baru `test/markdown_render_test.dart`), `flutter build apk --split-per-abi` sukses 3 ABI (armeabi-v7a 21.4MB, arm64-v8a 23.3MB, x86_64 24.7MB). API `Markdown`/`MarkdownStyleSheet` identik, tanpa perubahan kode lain.
- 2026-09-15 16:20:00 — Catatan: smoke test dokumen legal dilakukan lewat widget test render (heading, bullet, tabel + verifikasi `Table` widget), bukan test device; dokumen markdown asli EN+ID tetap diverifikasi `legal_documents_test.dart`. Uji visual device belum dijalankan.

## Notes
- Analisa awal: pemakaian `flutter_markdown` terlokalisir di 1 file (`legal_consent_screen.dart`) dengan API `Markdown` + `MarkdownStyleSheet` dasar.
- Versi target `flutter_markdown_plus` saat plan dibuat: `1.0.12` (Juli 2026).
- Commit proposal: `fix(deps): migrate flutter_markdown to flutter_markdown_plus (discontinued)`.
