import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/data/models/sticker_preset.dart';

StickerPreset _preset({
  required String id,
  required StickerPresetRole role,
  DateTime? validFrom,
  DateTime? validUntil,
}) {
  return StickerPreset.fromJson({
    'id': id,
    'label': id,
    'description': 'desc',
    'emoji': '✨',
    'requiredRole': role.name,
    if (validFrom != null) 'validFrom': validFrom.toIso8601String(),
    if (validUntil != null) 'validUntil': validUntil.toIso8601String(),
  });
}

void main() {
  group('isSeasonal', () {
    test('permanent preset has no window and is not seasonal', () {
      final p = _preset(id: 'kawaii', role: StickerPresetRole.free);
      expect(p.isSeasonal, isFalse);
    });

    test('preset with an end date is seasonal', () {
      final p = _preset(
        id: 'back_to_school_doodle',
        role: StickerPresetRole.free,
        validUntil: DateTime.utc(2026, 9, 20, 16, 59, 59),
      );
      expect(p.isSeasonal, isTrue);
    });

    test('window start without end date is still not seasonal', () {
      final p = _preset(
        id: 'future',
        role: StickerPresetRole.free,
        validFrom: DateTime.utc(2026, 9, 1),
      );
      expect(p.isSeasonal, isFalse);
    });
  });

  group('isLockedFor', () {
    final guestPreset = _preset(id: 'g', role: StickerPresetRole.guest);
    final freePreset = _preset(id: 'f', role: StickerPresetRole.free);
    final plusPreset = _preset(id: 'p', role: StickerPresetRole.plus);

    test('guest presets selectable by every role', () {
      expect(guestPreset.isLockedFor(StickerPresetRole.guest), isFalse);
      expect(guestPreset.isLockedFor(StickerPresetRole.free), isFalse);
      expect(guestPreset.isLockedFor(StickerPresetRole.plus), isFalse);
    });

    test('free presets locked only for guests', () {
      expect(freePreset.isLockedFor(StickerPresetRole.guest), isTrue);
      expect(freePreset.isLockedFor(StickerPresetRole.free), isFalse);
      expect(freePreset.isLockedFor(StickerPresetRole.plus), isFalse);
    });

    test('plus presets locked for guests and free users', () {
      expect(plusPreset.isLockedFor(StickerPresetRole.guest), isTrue);
      expect(plusPreset.isLockedFor(StickerPresetRole.free), isTrue);
      expect(plusPreset.isLockedFor(StickerPresetRole.plus), isFalse);
    });
  });

  group('fromJson time window', () {
    test('parses ISO timestamps with offset into DateTimes', () {
      final p = StickerPreset.fromJson(const {
        'id': 'cozy_study_club',
        'label': 'Cozy Study Club',
        'description': 'desc',
        'requiredRole': 'plus',
        'inputMode': 'subject',
        'validFrom': '2026-08-31T17:00:00+00:00',
        'validUntil': '2026-09-30T16:59:59+00:00',
      });
      expect(p.validFrom!.toUtc().year, 2026);
      expect(p.validUntil!.isBefore(DateTime.parse('2026-10-01T00:00:00Z')),
          isTrue);
      expect(p.requiredRole, StickerPresetRole.plus);
    });

    test('null windows stay null', () {
      final p = StickerPreset.fromJson(const {
        'id': 'kawaii',
        'label': 'Kawaii',
        'description': 'desc',
        'requiredRole': 'free',
      });
      expect(p.validFrom, isNull);
      expect(p.validUntil, isNull);
    });
  });
}
