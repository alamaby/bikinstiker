# Review Fixes — Guest Mission Auth Wall + Ads Tetap Tampil

Created: 2026-09-03 22:35:00

## Objective
Perbaiki temuan code review pasca `32e3d32` (`feat(missions): gate guest mission claims to auth wall and show ads for guests`) agar gate guest dan eligibility iklan benar-benar reaktif, bebas race, dan konsisten di seluruh lokasi.

## Scope
- In: `AdsBannerWidget` reaktivitas, `MissionsScreen` context guard, verifikasi `flutter analyze`/`flutter test`.
- Out: perubahan DB/RPC, migrasi kredit, key l10n baru, perubahan `MissionBloc`.

## Review Temuan (dari commit 32e3d32)

### F1 — HIGH — `AdsBannerWidget` tidak reaktif terhadap perubahan subscription
**Lokasi:** `lib/presentation/widgets/ads_banner_widget.dart:42-60`
**Temuan:** `didChangeDependencies` memakai `context.read<SubscriptionBloc>()`. `read` tidak mendaftarkan dependency, sehingga perubahan `SubscriptionBloc.state.isPlus` (mis. upgrade Plus → ad harus hilang, atau initial `unknown` → `loaded`) tidak memicu `didChangeDependencies`. Akibat: (a) upgrade Plus tidak menghilangkan banner sampai rebuild parent, (b) cold-start dengan `unknown` bisa salah load.
**Risiko:** Plus masih lihat iklan; guest/verified tetap konsisten tapi edge-case subscription timing.
**Fix:** Jadikan `build` yang reaktif via `BlocBuilder<SubscriptionBloc, SubscriptionState>` (atau `context.select`). Load/dispose banner dipicu dari builder, bukan dari `didChangeDependencies` saja. `initState` tidak lagi `read` bloc — defer sepenuhnya ke builder.

### F2 — MEDIUM — `MissionsScreen._isGuest` pakai `State.context.read`
**Lokasi:** `lib/presentation/screens/missions/missions_screen.dart:55,280,346,414`
**Temuan:** `bool get _isGuest => context.read<AuthBloc>().state.isGuest` memakai `State.context` (outer), dipanggil dari closure `SliverChildBuilderDelegate` yang punya `inner context` berbeda. Secara fungsi masih benar (bloc sama di tree), tapi (a) tidak reaktif terhadap perubahan auth (mis. setelah upgrade guest→authenticated, list tile tidak rebuild sampai `setState`/bloc emit lain), (b) melanggar idiom `read` di luar `build` vs `watch`/`select`.
**Risiko:** Setelah tap wall → sign-up sukses → `Navigator.pop` → kembali ke Missions, `_isGuest` sudah `false` (benar) tapi tile tidak rebuild; untungnya next tap akan baca ulang jadi lolos. Edge kecil, tapi pattern rapuh.
**Fix:** Hitung `final isGuest = context.watch<AuthBloc>().state.isGuest` (atau `context.select`) di `build` tepat sebelum `CustomScrollView`, lalu capture `isGuest` ke closure `onClaim`/`onComplete`. Alternatif: `context.read` di closure memakai `inner context` dari delegate, bukan `State.context`.

### F3 — LOW — `AdsBannerWidget.initState` read sebelum `didChangeDependencies`
**Lokasi:** `ads_banner_widget.dart:32-39`
**Temuan:** `initState` memanggil `_syncEligibility()` yang `read` bloc sebelum element fully mounted. Di Flutter, `read` di `initState` diperbolehkan jika provider sudah ada, tapi tetap rawan bila `SubscriptionBloc` belum di-provide di atas (di app memang sudah, jadi tidak crash). Namun pola ini duplikat dengan `didChangeDependencies`.
**Fix:** Hapus `_syncEligibility` di `initState`; cukup rely pada `BlocBuilder` (F1) — single source of truth.

### F4 — LOW — Placeholder vs SizedBox inconsistency
**Lokasi:** `ads_banner_widget.dart:106-112`
**Temuan:** Saat `!eligible` return `SizedBox.shrink()` (0 height) sedangkan saat loading return `_Placeholder()` (64 height). Transisi eligible→ineligible menyebabkan layout shift. Tidak blocking, tapi bisa diperhalus.
**Fix:** Biarkan shrink untuk ineligible (Plus) — memang sengaja hilang. Tidak perlu fix sekarang; catat.

### F5 — INFO — Tidak ada widget test untuk gate
**Temuan:** Belum ada `test/missions_guest_gate_test.dart` yang mem verifikasi tap → wall. Bukan blocker rilis, tapi untuk regresi.
**Fix:** Fase berikutnya (opsional) — tidak dikerjakan di fix ini agar tetap kecil.

## Tasks
- [x] R1 — Refactor `AdsBannerWidget` jadi reaktif: `build` pakai `BlocBuilder<SubscriptionBloc, SubscriptionState>`, load/dispose via post-frame, hapus `didChangeDependencies`+`_syncEligibility` pattern lama.
- [x] R2 — `MissionsScreen`: ganti `_isGuest` getter jadi local `isGuest` di `build` (watch) dan pakai closure capture; hapus getter `State.context.read` yang rapuh.
- [x] R3 — `flutter analyze` 0 issues + `flutter test` 183/183.
- [x] R4 — Update `plans/2026-09-03-guest-mission-auth-wall-and-ads-plan.md` Progress Log.
- [x] R5 — Commit `58ac28f` `fix(missions,ads): reactive gate and banner eligibility for guest flow` + push `58ac28f` ke `origin/main`.

## Risks
- Refactor `AdsBannerWidget` yang reaktif menambah rebuild tiap `SubscriptionBloc` emit — cost negligible (satu banner per screen).
- Post-frame `_loadAd` bisa dipicu berulang jika builder sering rebuild — guard dengan `_bannerAd == null && !_isLoaded && !_hasError`.

## Progress Log
- 2026-09-03 22:35:00 — Plan created dari review commit 32e3d32 (F1 HIGH, F2 MEDIUM, F3-F5 LOW/INFO).
- 2026-09-03 22:36:00 — Fix dimulai.
- 2026-09-03 22:41:00 — R1+R2 selesai. `flutter analyze` 0 issues, `flutter test` 183/183.
- 2026-09-03 22:42:00 — Commit `58ac28f` + push ke `origin/main`. Done.

## Notes
- Sengaja tidak ubah `home_screen.dart:541` dan `profile_screen.dart:119` — sudah benar (`BlocBuilder` / tanpa gate). Hanya `AdsBannerWidget` internal yang perlu reaktif.
- Reuse l10n tetap (konfirmasi user #2). Tidak tambah key baru.
