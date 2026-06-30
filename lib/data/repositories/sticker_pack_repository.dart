import 'dart:io';

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
  Future<void> cachePackStickersLocally(
    String packId,
    List<({String stickerId, String signedUrl})> stickers,
  );

  /// Download tray icon PNG from a signed URL and cache it locally.
  /// Skips if file already exists on disk.
  Future<void> cacheTrayIconLocally(String packId, String signedTrayUrl);

  /// Invoke the derive-tray-icon Edge Function to generate a 96x96 PNG
  /// tray icon from the first sticker in the pack.
  Future<({bool ok, String? error})> invokeDeriveTrayIcon({
    required String packId,
    required String sourceStickerId,
  });

  /// Ensure all sticker files + tray icon are cached locally for export.
  /// Self-healing: fetches missing assets. Returns null on success or error string.
  Future<String?> preparePackForExport(
    String packId,
    List<StickerPackItem> items,
  );
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
    String packId,
    List<({String stickerId, String signedUrl})> stickers,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final packDir = Directory('${appDir.path}/pack_stickers/$packId');
    if (!await packDir.exists()) {
      await packDir.create(recursive: true);
    }

    for (final sticker in stickers) {
      final file = File('${packDir.path}/${sticker.stickerId}.webp');
      if (await file.exists()) continue;

      try {
        final response = await http.get(Uri.parse(sticker.signedUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes, flush: true);
        }
      } catch (_) {
        // Non-fatal: ContentProvider will fail with FileNotFoundException
        // if user tries to export before cache is warm.
      }
    }
  }

  @override
  Future<void> cacheTrayIconLocally(String packId, String signedTrayUrl) async {
    final appDir = await getApplicationSupportDirectory();
    final trayDir = Directory('${appDir.path}/tray_icons');
    if (!await trayDir.exists()) {
      await trayDir.create(recursive: true);
    }

    final file = File('${trayDir.path}/$packId.png');
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
  Future<String?> preparePackForExport(
    String packId,
    List<StickerPackItem> items,
  ) async {
    // 1. Cache all sticker WebP files locally
    final stickerPairs = <({String stickerId, String signedUrl})>[];
    for (final item in items) {
      if (item.stickerSignedUrl != null) {
        stickerPairs.add((
          stickerId: item.stickerGenerationId,
          signedUrl: item.stickerSignedUrl!,
        ));
      }
    }
    if (stickerPairs.isNotEmpty) {
      await cachePackStickersLocally(packId, stickerPairs);
    }

    // 2. Check if tray icon is cached locally
    final appDir = await getApplicationSupportDirectory();
    final trayFile = File('${appDir.path}/tray_icons/$packId.png');
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
      await cacheTrayIconLocally(packId, trayUrl);
    }

    return null; // success
  }
}
