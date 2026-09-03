# Guest Mission Auth Wall + Iklan Tetap Tampil

Created: 2026-09-03 22:13:15

## Objective
Mission tetap `visible` untuk guest (`AuthStatus.guest`, `isAnonymous=true`, role `authenticated`) namun setiap aksi klaim (`DailyCheckinCard.onClaim`, `_MissionTile.onComplete` untuk `watch_video_ad`/`share_app_daily`/mission biasa/achievements) di-intercept dan diarahkan ke `AuthScreen(mode: guestAuthWall)` (sign-in / sign-up). Iklan banner (`AdsBannerWidget`) yang sebelumnya `eligible = !isGuest && !isPlus` diubah agar tetap tampil untuk guest — monetisasi tetap jalan.

## Scope
- Gate client di `MissionsScreen` (Daily Rewards + Quick Rewards + Achievements).
- Ubah eligibility iklan: `AdsBannerWidget` + gate di `Home` + `Profile`.
- Reuse `AuthScreen` wall flow yang sudah ada (`AuthSignUpRequested(upgradeGuest:true)` / `AuthGoogleSignInRequested(upgradeGuest:true)` + auto `Navigator.pop`).
- Reuse string l10n existing (`signInRequired`, `createAccountKeepSticker`, dll) — tanpa key baru.

Out of scope: perubahan DB RLS/RPC, migrasi kredit guest, perubahan `MissionBloc`.

## Milestones
1. M1 — Mission gate (Flutter): helper `_openAuthWall` di `MissionsScreen`, wrap 3 handler.
2. M2 — Ads tetap tampil: refactor eligibility jadi `!isPlus` + perbaiki race `initState`.
3. M3 — Verifikasi: `flutter analyze`, `flutter test`, manual guest→tap→wall→signUp→kembali.

## Tasks
- [x] T1 — `missions_screen.dart`: tambah `_openAuthWall` + guard `isGuest` di `DailyCheckinCard.onClaim` dan `_MissionTile.onComplete` (quickRewards + achievements).
- [x] T2 — `ads_banner_widget.dart`: `eligible = !isPlus` (hapus `!isGuest`), fix race `initState` + reactive via `didChangeDependencies`.
- [x] T3 — `home_screen.dart:543`: `showAd = !isPlus` (hapus `!isGuest`). `profile_screen.dart` ads sudah tanpa gate (119).
- [x] T4 — `flutter analyze` 0 issues (72.7s).
- [x] T5 — `flutter test` 183/183 hijau.
- [ ] T6 — Manual smoke: fresh anon → Missions → tap semua tipe mission → wall muncul; iklan missions/home/profile terlihat untuk guest; plus tetap tidak lihat iklan.

## Risks
- **R1 AdMob fill-rate** — guest = segmen terbesar, request naik. Mitigasi: pastikan `AdConfigService.bannerAdUnitId(missions)` valid.
- **R2 Race AdsBannerWidget** — `initState` load sebelum eligibility final bisa leak `BannerAd`. Mitigasi: hitung sync + listen perubahan `SubscriptionBloc`.
- **R3 Wasted SSV** — jika gate terlambat, `watch_video_ad` akan grant ke wallet guest yang hilang saat migrasi Google. Gate UI mencegah; hardening server bisa fase 2.
- **R4 UX agresif** — semua klik ke wall. Mitigasi: tetap tampilkan reward + `TierBadge`, hanya button yang redirect.

## Progress Log
- 2026-09-03 22:13:15 — Plan created. Owner konfirmasi: (1) iklan tetap di Home/Profile juga, (2) reuse l10n.
- 2026-09-03 22:14:00 — Implementasi M1-M2 dimulai.
- 2026-09-03 22:20:00 — Implementasi selesai. `flutter analyze` 0 issues, `flutter test` 183/183. File: `lib/presentation/screens/missions/missions_screen.dart`, `lib/presentation/widgets/ads_banner_widget.dart`, `lib/presentation/screens/home/home_screen.dart`.
- 2026-09-03 22:32:00 — Commit `32e3d32` — `feat(missions): gate guest mission claims to auth wall and show ads for guests`.
- 2026-09-03 22:35:00 — Review temuan: F1 HIGH (AdsBannerWidget tidak reaktif), F2 MEDIUM (_isGuest rapuh). Plan perbaikan: `plans/2026-09-03-guest-mission-review-fixes-plan.md`.
- 2026-09-03 22:41:00 — Fix F1+F2 selesai. `flutter analyze` 0 issues, `flutter test` 183/183.

## Notes
- Pola `home_screen.dart:357` `_openAuthWall() => push(MaterialPageRoute(AuthScreen guestAuthWall))` di-reuse tanpa infra baru.
- `MissionBloc` tetap trust caller; gate purely UI. Jika ingin defense-in-depth, tambah `IF is_anonymous THEN RAISE` di RPC fase berikutnya (tidak untuk plan ini).
- Guest wallet & `complete_mission` tetap allow di DB — tidak diubah, karena gate UI yang mengarahkan upgrade dulu sebelum klaim.
