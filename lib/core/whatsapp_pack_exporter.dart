import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/sticker_pack.dart';
import '../data/models/sticker_pack_item.dart';

const String kContentProviderAuthority =
    'com.alamaby.bikin_stiker.stickercontentprovider';

sealed class WhatsAppExportResult {
  const WhatsAppExportResult();
}

class WhatsAppExportSuccess extends WhatsAppExportResult {
  const WhatsAppExportSuccess();
}

class WhatsAppExportNotInstalled extends WhatsAppExportResult {
  const WhatsAppExportNotInstalled();
}

class WhatsAppExportError extends WhatsAppExportResult {
  final String message;
  const WhatsAppExportError(this.message);
}

class WhatsAppPackExporter {
  static const _channel = MethodChannel('com.alamaby.bikin_stiker/whatsapp');

  Future<WhatsAppExportResult> exportPack({
    required StickerPack pack,
    required List<StickerPackItem> items,
    Future<String?> Function(String packId, List<StickerPackItem> items)?
    prepareFn,
  }) async {
    final waInstalled = await _isWhatsAppInstalled();
    if (!waInstalled) {
      return const WhatsAppExportNotInstalled();
    }

    if (prepareFn != null) {
      final prepareError = await prepareFn(pack.id, items);
      if (prepareError != null) {
        return WhatsAppExportError(prepareError);
      }
    }

    final cacheError = await _verifyLocalCache(pack, items);
    if (cacheError != null) return cacheError;

    try {
      await _writePacksIndex(pack, items);
    } catch (e) {
      return WhatsAppExportError('Failed to write pack index: $e');
    }

    try {
      await _launchEnableStickerPack(pack);
      return const WhatsAppExportSuccess();
    } catch (e) {
      return WhatsAppExportError('Failed to launch WhatsApp: $e');
    }
  }

  Future<bool> _isWhatsAppInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWhatsAppInstalled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<WhatsAppExportError?> _verifyLocalCache(
    StickerPack pack,
    List<StickerPackItem> items,
  ) async {
    final appDir = await getApplicationSupportDirectory();

    final trayFile = File(
      '${appDir.path}/tray_icons_v2/${pack.packIdentifier}.png',
    );
    final trayExists = await trayFile.exists();
    if (!trayExists) {
      return const WhatsAppExportError(
        'Tray icon not ready. Please try again.',
      );
    }

    // Validate tray icon PNG
    if (!await _validatePngFile(trayFile, 96, 96)) {
      return const WhatsAppExportError(
        'Tray icon is invalid. Please try again.',
      );
    }

    for (final item in items) {
      final stickerFile = File(
        '${appDir.path}/pack_stickers_v2/${pack.packIdentifier}/${item.stickerGenerationId}.webp',
      );
      if (!await stickerFile.exists()) {
        return const WhatsAppExportError(
          'Some stickers are not cached. Please pull to refresh.',
        );
      }

      // Full validation of WebP file
      if (!await _validateWebpFile(stickerFile)) {
        return const WhatsAppExportError(
          'Some stickers are invalid. Please pull to refresh.',
        );
      }
    }

    return null;
  }

  /// Validates a PNG file has correct dimensions and is a valid PNG.
  Future<bool> _validatePngFile(File file, int expectedWidth, int expectedHeight) async {
    if (!await file.exists()) return false;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 24) return false;
      // PNG signature
      if (!(bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)) {
        return false;
      }
      // IHDR chunk at offset 8, dimensions at offset 16-23
      final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      return width == expectedWidth && height == expectedHeight;
    } catch (_) {
      return false;
    }
  }

  /// Validates a WebP file: RIFF/WEBP signature, VP8X/VP8L, 512x512, <=100KB, actual alpha.
  Future<bool> _validateWebpFile(File file) async {
    if (!await file.exists()) return false;
    try {
      final size = await file.length();
      if (size <= 0 || size > 100 * 1024) return false;

      final raf = await file.open();
      final header = Uint8List(30);
      final read = await raf.readInto(header);
      await raf.close();
      if (read < 30) return false;

      // RIFF....WEBP signature
      if (header[0] != 0x52 ||
          header[1] != 0x49 ||
          header[2] != 0x46 ||
          header[3] != 0x46) {
        return false;
      }
      if (header[8] != 0x57 ||
          header[9] != 0x45 ||
          header[10] != 0x42 ||
          header[11] != 0x50) {
        return false;
      }

      // Check chunk type: VP8X (extended/alpha) or VP8L (lossless)
      final chunk = String.fromCharCodes(header.sublist(12, 16));
      if (chunk != 'VP8X' && chunk != 'VP8L') return false;

      // Require an alpha channel: VP8L is always alpha-capable; VP8X stores an
      // alpha flag (0x10) in its flags byte. Opaque WebP caches must not be reused.
      if (chunk == 'VP8X' && (header[20] & 0x10) == 0) return false;

      // Verify dimensions are 512x512
      final dims = _parseWebPDims(header, chunk);
      return dims == const (512, 512);
    } catch (_) {
      return false;
    }
  }

  /// Parse WebP dimensions from header bytes.
  static (int, int)? _parseWebPDims(Uint8List header, String chunk) {
    if (chunk == 'VP8X') {
      final w =
          (header[24] & 0xff) |
          ((header[25] & 0xff) << 8) |
          ((header[26] & 0xff) << 16);
      final h =
          (header[27] & 0xff) |
          ((header[28] & 0xff) << 8) |
          ((header[29] & 0xff) << 16);
      return (w + 1, h + 1);
    } else if (chunk == 'VP8L') {
      final w =
          (header[21] & 0xff) |
          ((header[22] & 0xff) << 8) |
          ((header[23] & 0x3f) << 16);
      final h =
          (header[24] & 0xff) |
          ((header[25] & 0xff) << 8) |
          ((header[26] & 0x3f) << 16);
      return (w + 1, h + 1);
    }
    return null;
  }

  Future<void> _writePacksIndex(
    StickerPack pack,
    List<StickerPackItem> items,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final indexFile = File('${appDir.path}/packs_index.json');

    final stickers = items
        .map(
          (item) => {
            'file_name': '${item.stickerGenerationId}.webp',
            'emoji': item.emojis.isNotEmpty ? item.emojis.join(',') : '🙂',
            'accessibility_text': (item.accessibilityText ?? '').isNotEmpty
                ? item.accessibilityText!
                : 'Sticker',
          },
        )
        .toList();

    final packsArray = [
      {
        'identifier': pack.packIdentifier,
        'name': pack.name,
        'publisher': 'BikinStiker',
        'tray_icon_file': '${pack.packIdentifier}.png',
        'android_play_store_link':
            'https://play.google.com/store/apps/details?id=com.alamaby.bikin_stiker',
        'ios_app_download_link': '',
        'sticker_pack_publisher_email': '',
        'sticker_pack_publisher_website': '',
        'sticker_pack_privacy_policy_website': '',
        'sticker_pack_license_agreement_website': '',
        'image_data_version': '2',
        'whatsapp_will_not_cache_stickers': false,
        'animated_sticker_pack': false,
        'sticker_count': items.length,
        'stickers': stickers,
      },
    ];

    final jsonStr = jsonEncode(packsArray);
    await indexFile.writeAsString(jsonStr);
  }

  Future<void> _launchEnableStickerPack(StickerPack pack) async {
    final resultCode = await _channel
        .invokeMethod<int>('launchWhatsAppStickerActivity', {
          'sticker_pack_id': pack.packIdentifier,
          'sticker_pack_authority': kContentProviderAuthority,
          'sticker_pack_name': pack.name,
          'sticker_pack_publisher': 'BikinStiker',
        });

    if (resultCode != null && resultCode != -1) {
      // RESULT_OK = -1, RESULT_CANCELED = 0
    }
  }
}
