# WhatsApp Installed Detection Fix Plan

Created: 2026-07-03 16:42:43

## Objective
Fix the sticker pack detail export flow that incorrectly shows "WhatsApp is not installed" even when WhatsApp is installed.

## Scope
- Android native WhatsApp detection in `MainActivity.kt`.
- Flutter export result mapping in `lib/core/whatsapp_pack_exporter.dart` if needed.
- Export UX in `lib/presentation/screens/packs/pack_detail_screen.dart` only if message handling needs refinement.
- Project memory update after implementation.

## Milestones
1. Replace fragile WhatsApp detection based on `whatsapp://` activity resolution.
2. Use Android package visibility-safe package checks for `com.whatsapp` and `com.whatsapp.w4b`.
3. Keep the existing MethodChannel + ActivityResultLauncher export path intact.
4. Document suggested verification commands and commit message.

## Tasks
- [ ] Update `MainActivity.kt` `isWhatsAppInstalled` handler to check installed packages directly via `PackageManager`.
- [ ] Support both consumer WhatsApp (`com.whatsapp`) and WhatsApp Business (`com.whatsapp.w4b`) in detection.
- [ ] Optionally choose the installed package when launching `ENABLE_STICKER_PACK` instead of always hardcoding `com.whatsapp`.
- [ ] Review Dart exporter result handling so native errors are not mislabeled as "not installed".
- [ ] Format changed Kotlin/Dart files if applicable.
- [ ] Update `PROJECT_MEMORY.md` with bug fix summary, changed files, verification commands, and proposed commit message.

## Risks
- If only WhatsApp Business is installed, `ENABLE_STICKER_PACK` must target `com.whatsapp.w4b`; otherwise launch may fail after detection succeeds.
- Android 11+ package visibility requires `<queries>` entries, already present in `AndroidManifest.xml` for both WhatsApp packages.
- Some OEM builds may throw `NameNotFoundException`; detection must safely return false only after checking both packages.

## Notes
Likely root cause: `MainActivity.kt` currently detects WhatsApp using `Intent.ACTION_VIEW` with `whatsapp://` and `resolveActivity()`. WhatsApp may be installed but not expose a default activity for that URI under current Android/package-visibility behavior, so the native method returns `false`, and Flutter maps that to `WhatsAppExportNotInstalled`.

Proposed implementation: use `packageManager.getPackageInfo()` or API-level compatible `PackageManager.PackageInfoFlags` checks for `com.whatsapp` and `com.whatsapp.w4b`, then return the installed package name to Dart or keep a boolean plus use a helper on launch.
