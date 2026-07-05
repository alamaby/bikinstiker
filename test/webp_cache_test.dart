// Tests for StickerPackRepository public contract.
// Private helpers (_isValidWebpCache, _parseWebPDims) are exercised
// through integration; here we test the typed input/output contract.

import 'package:bikin_stiker/data/models/sticker_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickerPack sort enum', () {
    test('StickerPackSort enum has expected values', () {
      expect(StickerPackSort.values.length, 3);
      expect(StickerPackSort.values, contains(StickerPackSort.newest));
      expect(StickerPackSort.values, contains(StickerPackSort.oldest));
      expect(StickerPackSort.values, contains(StickerPackSort.nameAsc));
    });
  });

  group('StickerPack round-trip', () {
    test('fromJson -> toJson -> fromJson is stable', () {
      final original = StickerPack(
        id: 'p1',
        userId: 'u1',
        name: 'Test Pack',
        packIdentifier: 'u1.p1',
        trayIconPath: 'tray/u1/p1.png',
        stickerCount: 10,
        isActive: true,
        isLocked: false,
        lockedAt: null,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 6, 15),
        firstStickerSignedUrl: 'https://example.com/sticker.webp',
      );

      final json = original.toJson();
      final reconstructed = StickerPack.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.firstStickerSignedUrl,
          original.firstStickerSignedUrl);
      expect(reconstructed.canExport, true); // 10 stickers, not locked
    });

    test('canExport requires at least 3 stickers', () {
      final pack = StickerPack.fromJson({
        'id': 'p1',
        'user_id': 'u1',
        'name': 'Too Few',
        'pack_identifier': 'u1.p1',
        'tray_icon_path': 'tray/u1/p1.png',
        'sticker_count': 2,
        'is_active': true,
        'is_locked': false,
        'locked_at': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(pack.canExport, false);
    });

    test('canAddStickers is false when at capacity (30)', () {
      final pack = StickerPack.fromJson({
        'id': 'p1',
        'user_id': 'u1',
        'name': 'Full Pack',
        'pack_identifier': 'u1.p1',
        'tray_icon_path': 'tray/u1/p1.png',
        'sticker_count': 30,
        'is_active': true,
        'is_locked': false,
        'locked_at': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(pack.canAddStickers, false);
    });
  });
}
