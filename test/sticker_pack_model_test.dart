import 'package:bikin_stiker/data/models/sticker_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseJson = {
    'id': 'pack-1',
    'user_id': 'user-1',
    'name': 'My Pack',
    'pack_identifier': 'user-1.pack-1',
    'tray_icon_path': 'tray_icons/user-1/pack-1.png',
    'sticker_count': 5,
    'is_active': true,
    'is_locked': false,
    'locked_at': null,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  group('StickerPack.fromJson', () {
    test('parses basic fields', () {
      final pack = StickerPack.fromJson(baseJson);

      expect(pack.id, 'pack-1');
      expect(pack.userId, 'user-1');
      expect(pack.name, 'My Pack');
      expect(pack.packIdentifier, 'user-1.pack-1');
      expect(pack.trayIconPath, 'tray_icons/user-1/pack-1.png');
      expect(pack.stickerCount, 5);
      expect(pack.isActive, isTrue);
      expect(pack.isLocked, isFalse);
      expect(pack.lockedAt, isNull);
    });

    test('parses firstStickerSignedUrl when present', () {
      final json = {
        ...baseJson,
        'first_sticker_signed_url': 'https://storage.example.com/sticker1.png',
      };
      final pack = StickerPack.fromJson(json);

      expect(pack.firstStickerSignedUrl,
          'https://storage.example.com/sticker1.png');
    });

    test('firstStickerSignedUrl is null when absent', () {
      final pack = StickerPack.fromJson(baseJson);
      expect(pack.firstStickerSignedUrl, isNull);
    });

    test('parses lockedAt when present', () {
      final json = {
        ...baseJson,
        'locked_at': '2026-06-01T12:00:00Z',
        'is_locked': true,
      };
      final pack = StickerPack.fromJson(json);

      expect(pack.isLocked, isTrue);
      expect(pack.lockedAt, isNotNull);
      expect(pack.lockedAt!.year, 2026);
      expect(pack.lockedAt!.month, 6);
      expect(pack.lockedAt!.day, 1);
    });
  });

  group('StickerPack.copyWith', () {
    test('copies firstStickerSignedUrl', () {
      final original = StickerPack.fromJson(baseJson);
      expect(original.firstStickerSignedUrl, isNull);

      final withUrl = original.copyWith(
          firstStickerSignedUrl: 'https://storage.example.com/sticker1.png');

      expect(withUrl.firstStickerSignedUrl,
          'https://storage.example.com/sticker1.png');
      // Other fields unchanged
      expect(withUrl.name, original.name);
      expect(withUrl.id, original.id);
    });

    test('copyWith preserves existing firstStickerSignedUrl when null passed',
        () {
      final withUrl = StickerPack.fromJson({
        ...baseJson,
        'first_sticker_signed_url': 'https://existing.url',
      });
      final cleared = withUrl.copyWith(firstStickerSignedUrl: null);

      // copyWith with null does NOT clear (null is treated as "keep existing")
      // But since copyWith uses `??`, null means keep existing
      expect(cleared.firstStickerSignedUrl, 'https://existing.url');
    });
  });

  group('StickerPack business logic', () {
    test('canAddStickers: true when active, not locked, < 30 stickers', () {
      final pack = StickerPack.fromJson(baseJson);
      expect(pack.canAddStickers, isTrue);
    });

    test('canAddStickers: false when locked', () {
      final pack = StickerPack.fromJson({...baseJson, 'is_locked': true});
      expect(pack.canAddStickers, isFalse);
    });

    test('canAddStickers: false when at 30 stickers', () {
      final pack = StickerPack.fromJson({...baseJson, 'sticker_count': 30});
      expect(pack.canAddStickers, isFalse);
    });

    test('canExport: true when active, not locked, >= 3 stickers', () {
      final pack = StickerPack.fromJson({...baseJson, 'sticker_count': 3});
      expect(pack.canExport, isTrue);
    });

    test('canExport: false when < 3 stickers', () {
      final pack = StickerPack.fromJson({...baseJson, 'sticker_count': 2});
      expect(pack.canExport, isFalse);
    });

    test('canExport: false when locked', () {
      final pack = StickerPack.fromJson({
        ...baseJson,
        'is_locked': true,
        'sticker_count': 5,
      });
      expect(pack.canExport, isFalse);
    });

    test('canDelete: true for any active pack', () {
      final pack = StickerPack.fromJson(baseJson);
      expect(pack.canDelete, isTrue);
    });

    test('canRename: false when locked', () {
      final pack = StickerPack.fromJson({...baseJson, 'is_locked': true});
      expect(pack.canRename, isFalse);
    });
  });

  group('StickerPack Equatable', () {
    test('two packs with same props are equal', () {
      final pack1 = StickerPack.fromJson(baseJson);
      final pack2 = StickerPack.fromJson(baseJson);
      expect(pack1, equals(pack2));
    });

    test('packs with different firstStickerSignedUrl are not equal', () {
      final pack1 = StickerPack.fromJson(baseJson);
      final pack2 = StickerPack.fromJson({
        ...baseJson,
        'first_sticker_signed_url': 'https://different.url',
      });
      expect(pack1, isNot(equals(pack2)));
    });
  });

  group('StickerPack.toJson', () {
    test('round-trips firstStickerSignedUrl', () {
      final original = StickerPack.fromJson({
        ...baseJson,
        'first_sticker_signed_url': 'https://storage.example.com/sticker1.png',
      });
      final json = original.toJson();

      expect(json['first_sticker_signed_url'],
          'https://storage.example.com/sticker1.png');
    });

    test('round-trip preserves all fields', () {
      final original = StickerPack.fromJson(baseJson);
      final reconstructed = StickerPack.fromJson(original.toJson());

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.stickerCount, original.stickerCount);
      expect(reconstructed.isLocked, original.isLocked);
    });
  });
}
