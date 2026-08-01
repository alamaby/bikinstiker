import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sticker_pack.dart';
import '../models/sticker_pack_item.dart';

/// Repository for managing sticker packs - collections of 3-30 stickers
/// with tray icons for native WhatsApp import.
abstract class StickerPackRepository {
  /// Fetch all accessible (active, unlocked) packs for the current user.
  Future<List<StickerPack>> fetchUserPacks();

  /// Get full pack details including all sticker items with signed URLs.
  Future<({StickerPack pack, List<StickerPackItem> items})> getPackDetail(
    String packId,
  );

  /// Create a new empty pack.
  /// Returns the new pack's ID, identifier, and tray icon path.
  Future<({String packId, String packIdentifier, String trayIconPath})>
  createPack(String name);

  /// Add a sticker to a pack.
  /// Returns the new item ID and updated pack size.
  Future<({String itemId, int packSize})> addStickerToPack({
    required String packId,
    required String stickerId,
    required List<String> emojis,
    String? accessibilityText,
  });

  /// Remove a sticker from a pack.
  /// Returns the updated pack size.
  Future<int> removeStickerFromPack({
    required String packId,
    required String stickerId,
  });

  /// Rename a pack.
  /// Returns the new name.
  Future<String> renamePack({required String packId, required String newName});

  /// Soft-delete a pack (sets is_active=false).
  Future<void> deletePack(String packId);

  /// Set the tray icon from a source sticker.
  /// Returns the new tray icon path.
  Future<String> setTrayIcon({
    required String packId,
    required String sourceStickerId,
  });

  /// Get a signed URL for a pack's tray icon.
  /// Returns null if the tray icon doesn't exist.
  Future<String?> signedUrlForTrayIcon(String trayIconPath);

  /// Download sticker WebP bytes from signed URLs and cache them locally
  /// for the ContentProvider to serve.
  /// Skips files that already exist on disk.
  /// [packIdentifier] must match the pack_identifier used by ContentProvider.
  Future<void> cachePackStickersLocally(
    String packIdentifier,
    List<({String stickerId, String signedUrl})> stickers,
  );

  /// Download tray icon PNG from a signed URL and cache it locally.
  /// Skips if file already exists on disk.
  /// [packIdentifier] must match the pack_identifier used by ContentProvider.
  Future<void> cacheTrayIconLocally(
    String packIdentifier,
    String signedTrayUrl,
  );

  /// Invoke the derive-tray-icon Edge Function to generate a 96x96 PNG
  /// tray icon from the first sticker in the pack.
  Future<({bool ok, String? error})> invokeDeriveTrayIcon({
    required String packId,
    required String sourceStickerId,
  });

  /// Ensure all sticker files + tray icon are cached locally for export.
  /// Self-healing: fetches missing assets. Returns null on success or error string.
  /// [packId] is the UUID (for Edge Function), [packIdentifier] is the string
  /// identifier (for ContentProvider cache paths).
  Future<String?> preparePackForExport({
    required String packId,
    required String packIdentifier,
    required List<StickerPackItem> items,
  });
}

class SupabaseStickerPackRepository implements StickerPackRepository {
  final SupabaseClient _client;

  SupabaseStickerPackRepository(this._client);

  @override
  Future<List<StickerPack>> fetchUserPacks() async {
    final rows = await _client.rpc('get_user_packs');
    return (rows as List)
        .map((r) => StickerPack.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<({StickerPack pack, List<StickerPackItem> items})> getPackDetail(
    String packId,
  ) async {
    final res = await _client.rpc(
      'get_pack_detail',
      params: {'p_pack_id': packId},
    );
    final json = res as Map<String, dynamic>;
    final pack = StickerPack.fromJson(json['pack'] as Map<String, dynamic>);
    final itemRows = json['items'] as List? ?? const [];

    // Collect all sticker paths to fetch signed URLs in batch
    final paths = <String>[];
    for (final row in itemRows) {
      final path = (row as Map<String, dynamic>)['sticker_path'] as String?;
      if (path != null && path.isNotEmpty) {
        paths.add(path);
      }
    }

    // Fetch signed URLs for all sticker paths
    final signedUrls = <String, String>{};
    if (paths.isNotEmpty) {
      try {
        final urls = await _client.storage
            .from('stickers')
            .createSignedUrls(paths, 3600);
        for (int i = 0; i < paths.length; i++) {
          final signedUrl = urls[i];
          if (signedUrl.signedUrl.isNotEmpty) {
            signedUrls[paths[i]] = signedUrl.signedUrl;
          }
        }
      } catch (_) {
        // If batch fails, we'll skip signed URLs
      }
    }

    final items = itemRows.map((r) {
      final row = r as Map<String, dynamic>;
      final path = row['sticker_path'] as String?;
      return StickerPackItem.fromJson(
        row,
        signedUrl: path != null ? signedUrls[path] : null,
      );
    }).toList();

    return (pack: pack, items: items);
  }

  @override
  Future<({String packId, String packIdentifier, String trayIconPath})>
  createPack(String name) async {
    final res = await _client.rpc('create_pack', params: {'p_name': name});
    final row = (res as List).first as Map<String, dynamic>;
    return (
      packId: row['pack_id'] as String,
      packIdentifier: row['pack_identifier'] as String,
      trayIconPath: row['tray_icon_path'] as String,
    );
  }

  @override
  Future<({String itemId, int packSize})> addStickerToPack({
    required String packId,
    required String stickerId,
    required List<String> emojis,
    String? accessibilityText,
  }) async {
    final res = await _client.rpc(
      'add_sticker_to_pack',
      params: {
        'p_pack_id': packId,
        'p_sticker_id': stickerId,
        'p_emojis': emojis,
        'p_accessibility_text': accessibilityText,
      },
    );
    final row = (res as List).first as Map<String, dynamic>;
    return (
      itemId: row['item_id'] as String,
      packSize: row['pack_size'] as int,
    );
  }

  @override
  Future<int> removeStickerFromPack({
    required String packId,
    required String stickerId,
  }) async {
    final res = await _client.rpc(
      'remove_sticker_from_pack',
      params: {'p_pack_id': packId, 'p_sticker_id': stickerId},
    );
    return res as int;
  }

  @override
  Future<String> renamePack({
    required String packId,
    required String newName,
  }) async {
    final res = await _client.rpc(
      'rename_pack',
      params: {'p_pack_id': packId, 'p_name': newName},
    );
    return res as String;
  }

  @override
  Future<void> deletePack(String packId) async {
    await _client.rpc('delete_pack', params: {'p_pack_id': packId});
  }

  @override
  Future<String> setTrayIcon({
    required String packId,
    required String sourceStickerId,
  }) async {
    final res = await _client.rpc(
      'set_tray_icon',
      params: {
        'p_pack_id': packId,
        'p_source_type': 'sticker',
        'p_sticker_id': sourceStickerId,
      },
    );
    return res as String;
  }

  @override
  Future<String?> signedUrlForTrayIcon(String trayIconPath) async {
    try {
      // trayIconPath may be "tray_icons/{uid}/{packId}.png" — strip bucket prefix
      final objectPath = trayIconPath.startsWith('tray_icons/')
          ? trayIconPath.substring('tray_icons/'.length)
          : trayIconPath;
      final res = await _client.storage
          .from('tray_icons')
          .createSignedUrl(objectPath, 3600);
      return res;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cachePackStickersLocally(
    String packIdentifier,
    List<({String stickerId, String signedUrl})> stickers,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final packDir = Directory('${appDir.path}/pack_stickers_v2/$packIdentifier');
    if (!await packDir.exists()) {
      await packDir.create(recursive: true);
    }

    for (final sticker in stickers) {
      final webpFile = File('${packDir.path}/${sticker.stickerId}.webp');

      // Skip if cached WebP is valid (correct RIFF header, 512x512, < 100KB)
      if (await _isValidWebpCache(webpFile)) continue;

      // Invalid or missing: delete and re-encode
      if (await webpFile.exists()) await webpFile.delete();

      final pngTempFile = File('${packDir.path}/${sticker.stickerId}_tmp.png');

      try {
        // Download PNG from storage
        final response = await http.get(Uri.parse(sticker.signedUrl));
        if (response.statusCode != 200) continue;

        await pngTempFile.writeAsBytes(response.bodyBytes, flush: true);

        // Re-encode PNG → WebP via Android system encoder (preserves alpha)
        final qualityLevels = [75, 65, 55, 45, 35, 25];
        Uint8List? webpBytes;

        for (final q in qualityLevels) {
          final result = await FlutterImageCompress.compressWithFile(
            pngTempFile.absolute.path,
            minWidth: 512,
            minHeight: 512,
            quality: q,
            format: CompressFormat.webp,
          );
          if (result != null && result.length <= 100 * 1024) {
            webpBytes = result;
            break;
          }
        }

        // Fallback: lowest quality even if > 100KB
        if (webpBytes == null) {
          final result = await FlutterImageCompress.compressWithFile(
            pngTempFile.absolute.path,
            minWidth: 512,
            minHeight: 512,
            quality: 25,
            format: CompressFormat.webp,
          );
          if (result != null) {
            webpBytes = result;
          }
        }

        if (webpBytes != null) {
          await webpFile.writeAsBytes(webpBytes, flush: true);
        }
      } catch (e) {
        // Non-fatal
      } finally {
        // Cleanup temp PNG
        if (await pngTempFile.exists()) await pngTempFile.delete();
      }
    }
  }

  @override
  Future<void> cacheTrayIconLocally(
    String packIdentifier,
    String signedTrayUrl,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final trayDir = Directory('${appDir.path}/tray_icons_v2');
    if (!await trayDir.exists()) {
      await trayDir.create(recursive: true);
    }

    final file = File('${trayDir.path}/$packIdentifier.png');
    if (await file.exists()) return;

    try {
      final response = await http.get(Uri.parse(signedTrayUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }
    } catch (_) {
      // Non-fatal
    }
  }

  @override
  Future<({bool ok, String? error})> invokeDeriveTrayIcon({
    required String packId,
    required String sourceStickerId,
  }) async {
    try {
      await _client.functions.invoke(
        'derive-tray-icon',
        method: HttpMethod.post,
        body: {'pack_id': packId, 'source_sticker_id': sourceStickerId},
      );
      return (ok: true, error: null);
    } catch (e) {
      return (ok: false, error: e.toString());
    }
  }

  @override
  Future<String?> preparePackForExport({
    required String packId,
    required String packIdentifier,
    required List<StickerPackItem> items,
  }) async {
    // 1. Cache all stickers by downloading PNG + re-encoding to WebP
    final pngPairs = <({String stickerId, String signedUrl})>[];
    for (final item in items) {
      final pngPath = item.stickerPath?.replaceFirst('.webp', '.png');
      if (pngPath != null && pngPath.isNotEmpty) {
        try {
          final pngUrl = await _client.storage
              .from('stickers')
              .createSignedUrl(pngPath, 3600);
          pngPairs.add((
            stickerId: item.stickerGenerationId,
            signedUrl: pngUrl,
          ));
        } catch (_) {
          // Fallback to WebP if PNG URL fails
          if (item.stickerSignedUrl != null) {
            pngPairs.add((
              stickerId: item.stickerGenerationId,
              signedUrl: item.stickerSignedUrl!,
            ));
          }
        }
      } else if (item.stickerSignedUrl != null) {
        pngPairs.add((
          stickerId: item.stickerGenerationId,
          signedUrl: item.stickerSignedUrl!,
        ));
      }
    }
    if (pngPairs.isNotEmpty) {
      await cachePackStickersLocally(packIdentifier, pngPairs);
    }

    // 2. Check if tray icon is cached locally
    final appDir = await getApplicationSupportDirectory();
    final trayFile = File('${appDir.path}/tray_icons_v2/$packIdentifier.png');
    if (!await trayFile.exists()) {
      // 3. Derive tray icon from first sticker
      if (items.isEmpty) {
        return 'Pack has no stickers';
      }
      final firstItem = items.first;
      final deriveResult = await invokeDeriveTrayIcon(
        packId: packId,
        sourceStickerId: firstItem.stickerGenerationId,
      );
      if (!deriveResult.ok) {
        return 'Failed to generate tray icon: ${deriveResult.error}';
      }

      // 4. Fetch signed URL and cache tray icon
      final detail = await getPackDetail(packId);
      final trayUrl = await signedUrlForTrayIcon(detail.pack.trayIconPath);
      if (trayUrl == null) {
        return 'Failed to get tray icon URL';
      }
      await cacheTrayIconLocally(packIdentifier, trayUrl);
    }

    return null; // success
  }

  /// Check if a cached WebP file is valid (RIFF header, 512x512, <= 100KB).
  Future<bool> _isValidWebpCache(File file) async {
    if (!await file.exists()) return false;
    final size = await file.length();
    if (size <= 0 || size > 100 * 1024) return false;

    try {
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
      // alpha flag (0x10) in its flags byte. Opaque WebP caches (e.g. the old
      // white-background stickers) must not be reused.
      if (chunk == 'VP8X' && (header[20] & 0x10) == 0) return false;

      // Verify dimensions are 512x512
      final dims = _parseWebPDims(header, chunk);
      return dims == const (512, 512);
    } catch (_) {
      return false;
    }
  }

  /// Parse WebP dimensions from header bytes.
  /// Returns (width, height) or null if unparseable.
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
}
