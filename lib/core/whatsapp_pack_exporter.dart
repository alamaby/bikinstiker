import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

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
  static const _channel =
      MethodChannel('com.alamaby.bikin_stiker/whatsapp');

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

    final trayFile = File('${appDir.path}/tray_icons/${pack.packIdentifier}.png');
    final trayExists = await trayFile.exists();
    developer.log(
      'Verify cache: tray=${trayFile.path}, exists=$trayExists, '
      'size=${trayExists ? await trayFile.length() : "N/A"}',
      name: 'WhatsAppPackExporter',
    );
    if (!trayExists) {
      return const WhatsAppExportError(
        'Tray icon not ready. Please try again.',
      );
    }

    for (final item in items) {
      final stickerFile = File(
        '${appDir.path}/pack_stickers/${pack.packIdentifier}/${item.stickerGenerationId}.webp',
      );
      if (!await stickerFile.exists()) {
        developer.log(
          'Verify cache: MISSING sticker ${item.stickerGenerationId}',
          name: 'WhatsAppPackExporter',
        );
        return const WhatsAppExportError(
          'Some stickers are not cached. Please pull to refresh.',
        );
      }
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
        .map((item) => {
              'file_name': '${item.stickerGenerationId}.webp',
              'emoji': item.emojis.isNotEmpty
                  ? item.emojis.join(',')
                  : '🙂',
              'accessibility_text': (item.accessibilityText ?? '').isNotEmpty
                  ? item.accessibilityText!
                  : 'Sticker',
            })
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
        'image_data_version': '1',
        'whatsapp_will_not_cache_stickers': false,
        'animated_sticker_pack': false,
        'sticker_count': items.length,
        'stickers': stickers,
      },
    ];

    final jsonStr = jsonEncode(packsArray);
    await indexFile.writeAsString(jsonStr);
    developer.log(
      'Wrote packs_index.json: ${jsonStr.length} chars to ${indexFile.path}',
      name: 'WhatsAppPackExporter',
    );
  }

  Future<void> _launchEnableStickerPack(StickerPack pack) async {
    developer.log(
      'Launching via MethodChannel: id=${pack.packIdentifier}, '
      'authority=$kContentProviderAuthority, name=${pack.name}',
      name: 'WhatsAppPackExporter',
    );

    final resultCode = await _channel.invokeMethod<int>(
      'launchWhatsAppStickerActivity',
      {
        'sticker_pack_id': pack.packIdentifier,
        'sticker_pack_authority': kContentProviderAuthority,
        'sticker_pack_name': pack.name,
        'sticker_pack_publisher': 'BikinStiker',
      },
    );

    developer.log(
      'WhatsApp activity result code: $resultCode',
      name: 'WhatsAppPackExporter',
    );

    if (resultCode != null && resultCode != -1) {
      // RESULT_OK = -1, RESULT_CANCELED = 0
      // resultCode 0 means user cancelled or activity rejected
      developer.log(
        'Activity finished with code $resultCode (non-OK)',
        name: 'WhatsAppPackExporter',
      );
    }
  }
}
