import 'package:bikin_stiker/data/models/sticker_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickerPreset.fromJson', () {
    test('parses a full preset payload', () {
      final json = {
        'id': 'kawaii',
        'label': 'Kawaii',
        'description': 'Cute pastel chibi',
        'emoji': '\u{1F496}',
        'requiredRole': 'free',
        'validFrom': null,
        'validUntil': null,
      };
      final preset = StickerPreset.fromJson(json);

      expect(preset.id, 'kawaii');
      expect(preset.label, 'Kawaii');
      expect(preset.description, 'Cute pastel chibi');
      expect(preset.emoji, '\u{1F496}');
      expect(preset.requiredRole, StickerPresetRole.free);
      expect(preset.validFrom, isNull);
      expect(preset.validUntil, isNull);
      expect(preset.isCurrentlyValid, isTrue);
    });

    test('parses preset with time window', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': 'holiday',
        'label': 'Holiday Special',
        'description': 'Seasonal festive',
        'emoji': '\u{2728}',
        'requiredRole': 'free',
        'validFrom': now.subtract(const Duration(days: 1)).toIso8601String(),
        'validUntil': now.add(const Duration(days: 30)).toIso8601String(),
      };
      final preset = StickerPreset.fromJson(json);

      expect(preset.validFrom, isNotNull);
      expect(preset.validUntil, isNotNull);
      expect(preset.isCurrentlyValid, isTrue);
    });

    test('isCurrentlyValid returns false when expired', () {
      final json = {
        'id': 'expired',
        'label': 'Expired',
        'description': 'Gone',
        'emoji': null,
        'requiredRole': 'free',
        'validFrom': null,
        'validUntil': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      };
      final preset = StickerPreset.fromJson(json);

      expect(preset.isCurrentlyValid, isFalse);
    });

    test('isCurrentlyValid returns false when not yet started', () {
      final json = {
        'id': 'future',
        'label': 'Future',
        'description': 'Not yet',
        'emoji': null,
        'requiredRole': 'free',
        'validFrom': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'validUntil': null,
      };
      final preset = StickerPreset.fromJson(json);

      expect(preset.isCurrentlyValid, isFalse);
    });

    test('parses all three role values', () {
      for (final raw in ['guest', 'free', 'plus']) {
        final json = {
          'id': 'test_$raw',
          'label': 'Test',
          'description': 'Test',
          'emoji': null,
          'requiredRole': raw,
          'validFrom': null,
          'validUntil': null,
        };
        final preset = StickerPreset.fromJson(json);
        expect(
          preset.requiredRole,
          raw == 'guest'
              ? StickerPresetRole.guest
              : raw == 'plus'
              ? StickerPresetRole.plus
              : StickerPresetRole.free,
        );
      }
    });

    test('defaults to free for unknown role', () {
      final json = {
        'id': 'test',
        'label': 'Test',
        'description': 'Test',
        'emoji': null,
        'requiredRole': 'unknown',
        'validFrom': null,
        'validUntil': null,
      };
      final preset = StickerPreset.fromJson(json);
      expect(preset.requiredRole, StickerPresetRole.free);
    });

    test('handles null emoji gracefully', () {
      final json = {
        'id': 'no_emoji',
        'label': 'No Emoji',
        'description': 'Plain',
        'emoji': null,
        'requiredRole': 'free',
        'validFrom': null,
        'validUntil': null,
      };
      final preset = StickerPreset.fromJson(json);
      expect(preset.emoji, isNull);
    });
  });
}
