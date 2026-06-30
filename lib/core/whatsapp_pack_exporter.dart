import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/sticker_pack.dart';
import '../data/models/sticker_pack_item.dart';

/// Authority used by the StickerContentProvider in AndroidManifest.xml.
/// Must match exactly: applicationId + ".stickercontentprovider"
const String kContentProviderAuthority =
    'com.alamaby.bikin_stiker.stickercontentprovider';

/// Result of attempting to export a sticker pack to WhatsApp.
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

/// Orchestrates the native WhatsApp sticker pack import flow:
/// 1. Checks WhatsApp is installed
/// 2. Writes packs_index.json for the ContentProvider to read
/// 3. Launches the ENABLE_STICKER_PACK intent
class WhatsAppPackExporter {
  /// Export [pack] with its [items] to WhatsApp.
  ///
  /// Calls [prepareFn] to self-heal missing cache before launching.
  Future<WhatsAppExportResult> exportPack({
    required StickerPack pack,
    required List<StickerPackItem> items,
    Future<String?> Function(String packId, List<StickerPackItem> items)?
    prepareFn,
  }) async {
    // 1. Check WhatsApp is installed
    final waInstalled = await _isWhatsAppInstalled();
    if (!waInstalled) {
      return const WhatsAppExportNotInstalled();
    }

    // 2. Self-heal: ensure all assets are cached locally
    if (prepareFn != null) {
      final prepareError = await prepareFn(pack.id, items);
      if (prepareError != null) {
        return WhatsAppExportError(prepareError);
      }
    }

    // 3. Final verification of local cache
    final cacheError = await _verifyLocalCache(pack, items);
    if (cacheError != null) return cacheError;

    // 4. Write packs_index.json for ContentProvider
    try {
      await _writePacksIndex(pack, items);
    } catch (e) {
      return WhatsAppExportError('Failed to write pack index: $e');
    }

    // 5. Launch intent
    try {
      await _launchEnableStickerPack(pack);
      return const WhatsAppExportSuccess();
    } catch (e) {
      return WhatsAppExportError('Failed to launch WhatsApp: $e');
    }
  }

  Future<bool> _isWhatsAppInstalled() async {
    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'whatsapp://',
      );
      return await intent.canResolveActivity() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<WhatsAppExportError?> _verifyLocalCache(
    StickerPack pack,
    List<StickerPackItem> items,
  ) async {
    final appDir = await getApplicationSupportDirectory();

    // Check tray icon
    final trayFile = File('${appDir.path}/tray_icons/${pack.id}.png');
    if (!await trayFile.exists()) {
      return const WhatsAppExportError(
        'Tray icon not ready. Please try again.',
      );
    }

    // Check all sticker files
    for (final item in items) {
      final stickerFile = File(
        '${appDir.path}/pack_stickers/${pack.id}/${item.stickerGenerationId}.webp',
      );
      if (!await stickerFile.exists()) {
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

    final stickerFiles = items
        .map((item) => '${item.stickerGenerationId}.webp')
        .toList();

    final packsArray = [
      {
        'identifier': pack.packIdentifier,
        'name': pack.name,
        'publisher': 'BikinStiker',
        'tray_icon_file': '${pack.id}.png',
        'android_play_store_link':
            'https://play.google.com/store/apps/details?id=com.alamaby.bikin_stiker',
        'ios_app_store_link': '',
        'animated_sticker_pack': false,
        'sticker_count': items.length,
        'sticker_files': stickerFiles,
      },
    ];

    await indexFile.writeAsString(jsonEncode(packsArray));
  }

  Future<void> _launchEnableStickerPack(StickerPack pack) async {
    final intent = AndroidIntent(
      action: 'com.whatsapp.intent.action.ENABLE_STICKER_PACK',
      arguments: <String, dynamic>{
        'sticker_pack_id': pack.packIdentifier,
        'sticker_pack_authority': kContentProviderAuthority,
        'sticker_pack_name': pack.name,
      },
      package: 'com.whatsapp',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }
}
