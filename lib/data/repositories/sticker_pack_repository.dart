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
        final urls = await _client.storage.from('stickers').createSignedUrls(paths, 3600);
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

    final items = itemRows
        .map((r) {
          final row = r as Map<String, dynamic>;
          final path = row['sticker_path'] as String?;
          return StickerPackItem.fromJson(
            row,
            signedUrl: path != null ? signedUrls[path] : null,
          );
        })
        .toList();

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
      final res = await _client.storage
          .from('tray_icons')
          .createSignedUrl(trayIconPath, 3600);
      return res;
    } catch (_) {
      return null;
    }
  }
}
