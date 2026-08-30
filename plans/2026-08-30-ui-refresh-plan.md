# UI Refresh Tier 1 + Tier 2 (Dark Mode, Brand, Bottom Nav, Redesign)

Created: 2026-08-30 14:20:00

## Objective
Memperindah tampilan aplikasi sesuai audit UI: Tier 1 (dark mode + font brand + component themes + sweep warna) dan Tier 2 (bottom navigation + redesign Home + preset grid + PackCard) sekaligus, dalam 2 ronde commit. Keputusan owner: Tier 1 + 2 sekaligus.

## Guardrail yang Dipertahankan
- Palet Okabe-Ito & aturan icon+text; dark palette diturunkan dari peran yang sama (sky blue #56B4E9 primary dark, orange CTA identik).
- i18n EN/ID untuk semua teks baru; font bundel (bukan fetch runtime) agar offline-safe.

## Ronde A — v0.24.0+80 (commit 3929d6e)
- Font **Plus Jakarta Sans** bundel (400–800, latin, ~30KB/weight) → TextTheme + appBar/filled/elevated.
- `AppTheme.dark()` + `themeMode: ThemeMode.system`; konstanta `AppRadii`/`AppSpacing`.
- Component themes lengkap: chip, bottomSheet, dialog, listTile, progressIndicator, divider, snackbar shape, page transitions (Zoom/Cupertino), InkSparkle splash.
- Sweep warna terprogram (23 file): `Colors.black54/26/38/45/87` → `context.textSecondary/textFaint/textPrimary`, `AppColors.surface/outline/onSurface/background` → helper `context.*` (extension `AppThemeContext`). Fix `Colors.white` selektif (sheet riwayat, tier badge & feedback chip → `onPrimary`).

## Ronde B — v0.25.0+81
- **MainShellScreen**: NavigationBar 4 tab (Beranda/Misi/Pack/Riwayat) dengan **lazy IndexedStack** (tab dibangun saat pertama dikunjungi — Missions/Packs/History butuh user tersedia). Home AppBar dirapikan (profil saja + wordmark dua warna). Ikon appbar lama dihapus (nav menggantikan); entry-point push lain (surprise CTA, add-to-pack) tetap berfungsi sebagai route.
- Kartu kredit Home: gradasi tonal primary→secondary + ikon dalam lingkaran + **saldo animasi** (AnimatedSwitcher slide-fade per perubahan nilai).
- Panel hasil sukses: Lottie `success-sparkle` di atas status Done.
- **PresetPickerSheet → grid visual 3 kolom** (tile emoji + label + badge Limited + tanggal berakhir; selected = border primary + check; locked = dim + gembok → snackbar).
- `PackCard`: `cached_network_image` (placeholder & error = placeholder tema), count i18n `packStickerCount`.
- Empty states Home/Packs: ikon dalam lingkaran lembut.

## Verifikasi
- Ronde A: analyze 0, test 183/183, APK 3 ABI.
- Ronde B: analyze 0, test 183/183, APK 3 ABI.
- Verifikasi visual (dark/light, 4 tab, semua layar) = smoke owner sebelum release.

## Risks
- Sweep otomatis bisa melewatkan kasus tepi warna (konteks shadow/blend) — ditemukan via review manual putih + analyze; risiko residu rendah, laporkan bila ada layar aneh di dark.
- Lazy IndexedStack: deep-link prefill Home tetap jalan; cold-start share claim ter-drain saat tab Misi pertama dibuka (perilaku sama seperti sebelumnya karena mission load app-level).
- `search_showcase_listings` dsb. tidak tersentuh (backend).

## Progress Log
- 2026-08-30 14:20 — Ronde A & B selesai, verifikasi hijau, siap release 0.25.0+81.

## Notes
- Disiplin ke depan: kode baru wajib pakai helper `context.*` (bukan warna hardcoded) supaya dark mode terjaga; `Colors.black*/Colors.white` dilarang di lib/ kecuali teks di atas warna brand.
