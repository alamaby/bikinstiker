import 'package:flutter_test/flutter_test.dart';

import 'package:bikin_stiker/core/constants/presets.dart';

void main() {
  test('preset ids match the server contract', () {
    const expectedIds = {
      'kawaii',
      'pixel_art',
      'vector_flat',
      'chibi_3d',
      'retro_sticker',
    };
    final actualIds = kStickerPresets.map((p) => p.id).toSet();
    expect(actualIds, equals(expectedIds));
  });
}
