# WhatsApp Sticker Pack Export - Implementation Plan

Created: 2026-06-30 18:00:00

## Objective
Wire the existing `sticker_packs` mechanism to native WhatsApp sticker pack import on
Android. The user taps **Export to WhatsApp** on `PackDetailScreen`, the app launches
`com.whatsapp.intent.action.ENABLE_STICKER_PACK`, WhatsApp reads pack metadata + sticker
bytes via a new `StickerContentProvider`, and the user installs the pack into WhatsApp.

Reference: https://context7.com/whatsapp/stickers (official whatsapp/stickers repo).

This plan adds the missing piece; it does NOT redesign existing pack screens, DB schema,
or share helpers. iOS is explicitly out of scope (deferred per TODO.md).

## Confirmed Decisions
- Native WA import via `ENABLE_STICKER_PACK` intent + `StickerContentProvider` (not OS share sheet).
- Tray icon 96x96 PNG auto-derived from first sticker via new Edge Function.
- Android-only (iOS deferred per TODO.md).
- ContentProvider authority: `com.alamaby.bikin_stiker.stickercontentprovider`.

## Scope
- Android-only native WhatsApp sticker pack import via `ENABLE_STICKER_PACK` intent.
- Tray icon (96x96 PNG, <=50 KB) auto-derived from the first sticker added to a pack
  via a new Edge Function.
- Storage migration for the missing `tray_icons` bucket.
- New `StickerContentProvider` (Kotlin) serving pack metadata + sticker WebP bytes from
  app internal storage.
- Flutter wiring: cache sticker bytes locally on add, launch intent on export, error
  handling for missing WhatsApp / failed ContentProvider lookup.
- Reuses: `pack.canExport` predicate, `StickerPackRepository`, `share_helper.dart`
  download pattern, `imagescript` for tray resize, `share_plus` stays for single sticker.

## Out of Scope
- iOS StickerPack framework integration (deferred).
- Changing existing pack screens' UX (rename, delete, add-sticker sheet).
- Updating `set_tray_icon` RPC behavior beyond what is needed.
- New credit deductions for export (export is free).
- Animated stickers (we ship static 512x512 WebP).

## Architecture Overview

```
[User taps Export to WhatsApp]
        |
        v
[PackDetailScreen] --(launch intent)--> [WhatsApp]
                                            |
                                            v
                              [StickerContentProvider.query()]
                                            |
                                            v
              [Read filesDir/pack_stickers/{pack_id}/*.webp
               + filesDir/tray_icons/{pack_id}.png]

First-sticker trigger:
  add_sticker_to_pack RPC succeeds
        -> Flutter downloads WebP -> filesDir/pack_stickers/{pack_id}/{sticker_id}.webp
        -> if first sticker in pack:
              Edge Function derive-tray-icon
                -> fetch sticker WebP (service role)
                -> resize to 96x96 PNG via imagescript
                -> upload to tray_icons/{uid}/{pack_id}.png
              Flutter downloads tray PNG -> filesDir/tray_icons/{pack_id}.png
```

## Milestones
1. **M1** Storage layer: `tray_icons` bucket migration
2. **M2** Tray icon pipeline: `derive-tray-icon` Edge Function
3. **M3** Flutter local cache + auto-derive on add-sticker
4. **M4** `StickerContentProvider` (Kotlin) + manifest
5. **M5** Intent launch via `android_intent_plus`
6. **M6** Error handling + UX
7. **M7** Sync `PROJECT_MEMORY.md` and `TODO.md`

## Tasks

### M1 - Storage layer
- [ ] Create `supabase/migrations/20260629000023_tray_icons_bucket.sql`
  - INSERT `tray_icons` bucket (private)
  - RLS owner-SELECT only via `storage.foldername(name)[1] = auth.uid()::text`
  - No INSERT/UPDATE/DELETE for authenticated users (Edge Function uses service role)

### M2 - Tray icon pipeline
- [ ] Create `supabase/functions/derive-tray-icon/index.ts`
  - POST `{pack_id, source_sticker_id}` with bearer JWT
  - Verify `auth.uid()` owns the pack via `SELECT ... WHERE user_id = auth.uid()`
  - Verify `source_sticker_id` is the `position=1` item in the pack
  - Skip if tray already exists at `tray_icons/{uid}/{pack_id}.png`
  - Fetch sticker WebP via service role
  - Decode via `imagescript.Image.decode(bytes)`, resize to 96x96 contain-on-white, encode PNG
  - Size-check <=50 KB; compress if needed
  - Upload to `tray_icons/{uid}/{pack_id}.png` via service role
  - Return `{trayIconPath, sizeBytes}`

### M3 - Flutter local cache + auto-derive
- [ ] Extend `StickerPackRepository`:
  - `cachePackStickersLocally(packId, [(stickerId, signedUrl)])`
  - `cacheTrayIconLocally(packId, signedTrayUrl)`
  - `invokeDeriveTrayIcon(packId, sourceStickerId)` -> calls `functions.invoke('derive-tray-icon', ...)`
- [ ] Implementation: `getApplicationDocumentsDirectory()` (persistent), HTTP GET + write file, skip-if-exists
- [ ] Extend `StickerPackBloc.AddSticker` handler:
  - After RPC succeeds, download new sticker WebP locally
  - If pack size is now 1 AND tray file missing, invoke `derive-tray-icon` then `signedUrlForTrayIcon` then `cacheTrayIconLocally`
  - Fire-and-forget on try/catch; failures set `state.errorMessage` but do not roll back

### M4 - StickerContentProvider (Kotlin)
- [ ] Create `android/app/src/main/kotlin/com/alamaby/bikin_stiker/StickerContentProvider.kt`
  - `onCreate()` -> true
  - `query()`:
    - `.../metadata` -> all packs (cursor)
    - `.../metadata/{pack_identifier}` -> single pack cursor
    - `.../stickers/{pack_identifier}/{sticker_filename}` -> `OpenableUri` via `ParcelFileDescriptor`
  - Columns: `sticker_pack_identifier, sticker_pack_name, sticker_pack_publisher, sticker_pack_icon, android_play_store_link, ios_app_store_link, animated_sticker_pack`
  - Hardcoded: publisher=`BikinStiker`, play link = app store URL, animated=0
  - Read metadata from `filesDir/packs_index.json` (written by Flutter pre-export)
  - Read WebP from `filesDir/pack_stickers/{pack_id}/{sticker}.webp`
- [ ] Update `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <provider
      android:name=".StickerContentProvider"
      android:authorities="${applicationId}.stickercontentprovider"
      android:enabled="true"
      android:exported="true"
      android:readPermission="com.whatsapp.sticker.READ" />
  ```
  - Add `<queries>` packages for `com.whatsapp` + `com.whatsapp.w4b` (Android 11+ visibility)

### M5 - Intent launch (Flutter)
- [ ] Add `android_intent_plus: ^5.2.0` to `pubspec.yaml`
- [ ] Create `lib/core/whatsapp_pack_exporter.dart`:
  - Sealed result: `success | whatsappNotInstalled | contentProviderError(String)`
  - Check WhatsApp via `AndroidIntent.canLaunch(...)` with `whatsapp://`
  - Write `packs_index.json` to `getApplicationSupportDirectory()`
  - Launch:
    ```dart
    AndroidIntent(
      action: 'com.whatsapp.intent.action.ENABLE_STICKER_PACK',
      arguments: {
        'sticker_pack_id': pack.packIdentifier,
        'sticker_pack_authority': 'com.alamaby.bikin_stiker.stickercontentprovider',
        'sticker_pack_name': pack.name,
      },
      package: 'com.whatsapp',
    ).launch()
    ```
- [ ] Register `WhatsAppPackExporter` in `lib/core/di.dart`
- [ ] Wire `PackDetailScreen._buildBottomBar` to call exporter; show progress overlay; show snackbar on each error

### M6 - Error handling + UX
- [ ] Pre-export sanity: tray icon file exists; all sticker files exist; pack size >= 3
- [ ] Manual refresh button on `PackDetailScreen` re-downloads missing files
- [ ] All errors via existing snackbar pattern

### M7 - Documentation sync
- [ ] Update `PROJECT_MEMORY.md` (migration 023, edge fn, bloc, exporter, decision #X)
- [ ] Update `TODO.md` (move WhatsApp import to Completed; keep iOS deferred)

## Files Created
- `supabase/migrations/20260629000023_tray_icons_bucket.sql`
- `supabase/functions/derive-tray-icon/index.ts`
- `android/app/src/main/kotlin/com/alamaby/bikin_stiker/StickerContentProvider.kt`
- `lib/core/whatsapp_pack_exporter.dart`

## Files Modified
- `android/app/src/main/AndroidManifest.xml` (provider + queries)
- `pubspec.yaml` (`android_intent_plus`)
- `lib/data/repositories/sticker_pack_repository.dart` (cache + derive methods)
- `lib/presentation/blocs/sticker_pack/sticker_pack_bloc.dart` (cache hooks)
- `lib/presentation/screens/packs/pack_detail_screen.dart` (export wiring)
- `lib/core/di.dart` (exporter registration)
- `PROJECT_MEMORY.md`, `TODO.md`

## Risks
- **R1** Wrong authority -> silent WhatsApp failure. Mitigation: pin via `${applicationId}.stickercontentprovider`, single Dart constant, smoke-test launch with logcat.
- **R2** Tray >50 KB. Mitigation: encode + size check, downscale if exceeded.
- **R3** Signed URL 1h expiry. Mitigation: cache WebP in `getApplicationDocumentsDirectory()` (persistent, not temp).
- **R4** Pack identifier must stay stable across renames (currently does - `{uid}-{pid}`).
- **R5** Existing pre-feature packs have no cache. Mitigation: auto-cache + derive on first Export tap.
- **R6** iOS deferred - clearly documented.

## Verification Commands (for you to run)
```bash
dart format lib/ android/app/src/main/kotlin/
flutter analyze && flutter test

cd supabase && git pull origin main && cd ..
supabase db push
supabase functions deploy derive-tray-icon

flutter build apk --release
adb install build/app/outputs/flutter-apk/bikin_stiker-0.6.5+18-release.apk

# Smoke: sign in -> generate 3+ stickers -> My Packs -> Create -> Add 3 stickers
# -> wait for tray icon derivation -> tap Export to WhatsApp
# -> WA opens with pack preview -> Add -> verify in WA tray

# Negative: uninstall WA -> Export -> expect "WhatsApp is not installed" snackbar
adb logcat | grep -E "StickerContentProvider|ENABLE_STICKER_PACK"
```

## Proposed Commit Messages
- `feat(supabase): add tray_icons bucket for WhatsApp sticker pack tray icons`
- `feat(edge): add derive-tray-icon function to generate 96x96 PNG tray icon`
- `feat(android): add StickerContentProvider for native WhatsApp sticker import`
- `feat(sticker-packs): export pack to WhatsApp via ENABLE_STICKER_PACK intent`
- `docs(memory): sync PROJECT_MEMORY.md and TODO.md with WhatsApp pack export`

Single combined: `feat(whatsapp): native sticker pack export via Android ContentProvider + intent`
