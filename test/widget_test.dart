import 'dart:io';

import 'package:bikin_stiker/core/constants/presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preset IDs match server contract', () {
    final file = File('supabase/functions/generate-sticker/index.ts');
    final content = file.readAsStringSync();

    // Extract PRESETS object content
    final presetsStart = content.indexOf(
      'const PRESETS: Record<string, string> = {',
    );
    if (presetsStart == -1) {
      throw StateError('Could not find PRESETS declaration in index.ts');
    }

    final presetsBodyStart = content.indexOf('{', presetsStart);
    if (presetsBodyStart == -1) {
      throw StateError('Could not find PRESETS object body');
    }

    final presetsEnd = content.indexOf('};', presetsBodyStart);
    if (presetsEnd == -1) {
      throw StateError('Could not find end of PRESETS object');
    }

    final presetsContent = content.substring(presetsBodyStart + 1, presetsEnd);

    // Parse IDs from the PRESETS object
    final idRegex = RegExp(
      r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:',
      multiLine: true,
    );
    final matches = idRegex.allMatches(presetsContent);
    final serverIds = Set<String>.from(matches.map((m) => m.group(1)));

    final clientIds = kStickerPresets.map((p) => p.id).toSet();
    expect(clientIds, unorderedElementsEqualTo(serverIds));
  });
}
