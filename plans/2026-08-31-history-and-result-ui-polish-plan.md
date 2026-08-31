# History & Result UI Polish (5 findings)

Created: 2026-08-31 00:00:00

## Objective
Lima perbaikan UI pada layar Riwayat Stiker, sheet pratinjau riwayat, panel hasil generate, dan dialog konfirmasi Surprise Me gratis. Murni Flutter (tanpa backend/migrasi).

## Scope
- `lib/presentation/screens/history/history_screen.dart` (filter bar, tile label, preview sheet)
- `lib/presentation/screens/history/widgets/history_filter_chips.dart` (tidak ada perubahan struktural)
- `lib/core/localization/preset_localizations.dart` (ekstrak helper by-id + humanize)
- `lib/presentation/screens/home/home_screen.dart` (reveal anim, styled dialog)
- `pubspec.yaml` (version bump)

## Keputusan desain (dikonfirmasi user)
- Poin 4: **overlay** Lottie di atas stiker (reveal) + hapus ruang kosong 72px di atas "Selesai".
- Poin 2: **hapus Share** di sheet pratinjau + **tambah StickerFeedbackButtons** (gated `!isGuest`) agar konsisten dengan `_ResultPanel`.
- Poin 5: **AlertDialog ber-style** (tanpa key ARB baru; pakai key yang ada).

## Milestones
1. Filter bar 1 baris horizontal-scroll
2. Label preset ramah user (helper by-id + humanize) + wiring tile/sheet
3. Sheet pratinjau: hapus Share + tambah feedback
4. Panel hasil: reveal animasi overlay + hapus space
5. Dialog Surprise Me: tipografi ber-style
6. Version bump + verifikasi + memory

## Tasks
- [x] P1: `_FilterBar` Wrap → `SingleChildScrollView(Axis.horizontal)` + `Row(mainAxisSize.min)` dengan separator `SizedBox(width:8)`; `HistorySearchField` tetap di baris bawah
- [x] P3a: `preset_localizations.dart` — ekstrak `localizedPresetLabelById(l10n, presetId, {serverLabel})`; `localizedPresetLabel` delegasi; helper `humanizePresetId(id)` (underscore→spasi, title-case) sebagai fallback ketika `serverLabel` kosong
- [x] P3b: `_HistoryTile` & `_StickerPreviewSheet` — lookup preset via `context.read<PresetBloc>().state.presets` by `item.presetName`, lalu `localizedPresetLabelById(...)`; ganti `${item.presetName}` → `$presetLabel`
- [x] P2: `_StickerPreviewSheet` — hapus `FilledButton.icon(share)`; tambah `StickerFeedbackButtons(stickerGenerationId: item.id)` gated `!isGuest` (mirror `_ResultPanel`); tambah import `sticker_feedback_buttons.dart` + `auth_bloc.dart`; hapus import `share_helper.dart` (tak terpakai)
- [x] P4: `_ResultPanel` success — hapus `Center(Lottie 72)` + `SizedBox(4)` di atas baris Done; baris "Selesai" tetap di paling atas; ganti `AspectRatio(image)` → `_StickerReveal(imageUrl)`; buat `_StickerReveal` StatefulWidget + `SingleTickerProviderStateMixin`: `AnimationController` 900ms forward sekali, `AnimatedBuilder` opacity hold 70% lalu fade 30%, `addStatusListener(completed)` → unmount overlay
- [x] P5: `showDialog` Surprise Me — `title` Row `[Icon(casino/bolt, primary), Expanded(Text(... w800))]`; `content` bungkus body di panel tinted (`primary.alpha 0.08`, radius 12, padding 14); free body 16/w600, paid/insufficient sekunder 13
- [x] Bump pubspec `0.26.0+82` → `0.26.1+83` (patch, sesuai commit `fix(ux):`)
- [x] Verifikasi: `flutter pub get` OK; `flutter analyze` 0 issues; `flutter test` 183/183 lulus; `flutter build apk --split-per-abi` sukses (3 APK: 21.3/23.2/24.6 MB)
- [ ] Update `PROJECT_MEMORY.md`

## Risks
- Lottie `success-sparkle.json` durasi tidak diketahui → controller 900ms tetap; `addStatusListener` safety unmount mencegah overlay menetap.
- Filter horizontal menurunkan discoverability chip ke-4 sedikit (mitigasi: padding 16 + chip pertama selalu terlihat).
- Widget test `test/history_filter_sheet_test.dart` mungkin menyentuh layout `Wrap` → perlu cek & tweak bila gagal.
- `StickerFeedbackRepository` butuh auth → gated `!isGuest` seperti `_ResultPanel`.

## Progress Log
- 2026-08-31 00:00:00 — Plan dibuat.
- 2026-08-31 (eksekusi) — Semua 5 poin + bump versi + verifikasi selesai. `flutter analyze` 0 issues; `flutter test` 183/183; APK 3 ABI sukses. Murni Flutter, tanpa backend/migrasi/key ARB baru.

## Notes
- `PresetBloc` root-level (`app.dart:109`) → lookup di tile/sheet aman.
- `item.presetName` = id preset (dipakai sebagai `presetId` di `_regenerate` history_screen.dart:394).
- Tanpa key ARB baru (semuaICATIONS pakai key yang sudah ada).
- Proposed commit (Conventional Commits, 1 baris): `fix(ux): single-row history filters, hide share+add feedback, localized preset label, sticker reveal animation, surprise dialog typography`
