# WhatsApp Export Detection Fix (Android 11+ Package Visibility)

Created: 2026-07-03 23:30:00

## Objective
Memperbaiki regresi deteksi "WhatsApp not installed" saat Export to WhatsApp dari pack detail. Akar masalah: native handler menggunakan `packageManager.resolveActivity(Intent(ACTION_VIEW, whatsapp://))` yang selalu return null pada Android 11+ (targetSdk 30+) karena `<queries>` AndroidManifest tidak mendeklarasikan `<intent>` yang match (action + data scheme). Fix: ganti deteksi ke `getPackageInfo` yang sudah didukung oleh `<queries><package>` yang sudah ada.

## Scope
- Edit 1 file native Android (`MainActivity.kt`)
- Tidak ada perubahan di AndroidManifest, Dart code, atau file lain
- Tidak ada perubahan UI/UX flow

## Tasks

### 1. Update `android/app/src/main/kotlin/com/alamaby/bikin_stiker/MainActivity.kt`

Ganti handler `isWhatsAppInstalled` (line 37-43) dari `resolveActivity` ke `getPackageInfo`:

```kotlin
"isWhatsAppInstalled" -> {
    val pm = packageManager
    val installed = try {
        pm.getPackageInfo("com.whatsapp", 0)
        true
    } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
        try {
            pm.getPackageInfo("com.whatsapp.w4b", 0)
            true
        } catch (_: android.content.pm.PackageManager.NameNotFoundException) {
            false
        }
    }
    result.success(installed)
}
```

Catatan:
- `getPackageInfo` diizinkan oleh `<queries><package>` yang sudah ada di AndroidManifest (tidak butuh `<intent>` declaration)
- Cek WhatsApp utama dulu (`com.whatsapp`), fallback ke WhatsApp Business (`com.whatsapp.w4b`)
- Jangan sentuh handler `launchWhatsAppStickerActivity` (line 44-69) — gunakan `setPackage("com.whatsapp")` eksplisit yang sudah aman
- Import `NameNotFoundException` bisa inline-qualified (seperti di atas) atau ditambahkan ke daftar import di atas

### 2. Verifikasi perubahan kompatibel dengan kode Dart
- `lib/core/whatsapp_pack_exporter.dart:68-75` `_isWhatsAppInstalled()` — tidak perlu diubah, tetap memanggil method channel yang sama
- `lib/presentation/screens/packs/pack_detail_screen.dart:208-266` `_onExportToWhatsApp` — flow error handling `WhatsAppExportNotInstalled` tetap dipakai

### 3. (Opsional) Tambah `<intent>` di `<queries>` sebagai defense-in-depth

Hanya jika testing menunjukkan `launchWhatsAppStickerActivity` juga gagal di Android 11+. Tambahkan ke AndroidManifest.xml:
```xml
<intent>
    <action android:name="com.whatsapp.intent.action.ENABLE_STICKER_PACK"/>
</intent>
```

TIDAK dilakukan sekarang karena `launchWhatsAppStickerActivity` menggunakan `setPackage("com.whatsapp")` eksplisit yang aman.

## Risks
- **Risiko rendah**: `getPackageInfo` adalah API standar yang sudah stabil. `<queries><package>` di AndroidManifest sudah sesuai requirement Android 11+.
- **Test coverage**: Tidak ada unit test native Kotlin. Verifikasi hanya bisa dilakukan dengan build APK + run di device fisik.
- **Behavior change**: dari "WhatsApp terinstall DAN terdaftar sebagai handler `whatsapp://`" menjadi "WhatsApp terinstall" (apapun varian atau build). Untuk use case ini (export ke WhatsApp), lebih akurat.
- **Edge case**: WhatsApp di-disabled (uninstalled tapi package record masih ada di system cache) — `getPackageInfo` mungkin masih return data valid. Existing code juga punya behavior ini, jadi tidak ada regresi baru.

## Validation
- Build APK debug: `flutter build apk --debug`
- Install di device Android 11+ dengan WhatsApp terinstall → buka Pack Detail → Export to WhatsApp → activity ENABLE_STICKER_PACK WhatsApp muncul (bukan snackbar "not installed")
- Install di device/emulator tanpa WhatsApp → Export to WhatsApp → snackbar "WhatsApp is not installed. Please install WhatsApp first." tetap muncul
- Test kedua varian: WhatsApp utama + WhatsApp Business (install w4b, uninstall utama, ulangi)

## Out of scope
- Tidak ada perubahan di iOS (saat ini sticker export Android-only)
- Tidak ada perubahan di content provider logic (StickerContentProvider.kt)
- Tidak ada perubahan di export flow prep (WebP re-encoding, tray icon derivation)

## Catatan
- Jika setelah fix ditemukan juga bahwa `launchWhatsAppStickerActivity` gagal dengan `ActivityNotFoundException`, tambahkan task #3 (defense-in-depth `<intent>` di queries) secara terpisah.
- Pertimbangkan untuk extract `WA_PACKAGES` list sebagai konstanta di MainActivity companion untuk DRY.