import 'dart:math';

import 'package:bikin_stiker/core/constants/prompt_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Active preset IDs from production `sticker_presets` (audited 2026-08-25).
/// Regression net for tag coverage; new DB presets must be added here.
const kActiveImagePresetIds = <String>[
  'anime',
  'caricature',
  'chibi_3d',
  'claymation',
  'embroidery',
  'kawaii',
  'lego_voxel',
  'line_doodle',
  'minimal_line',
  'neon_cyber',
  'origami',
  'photoreal',
  'pixel_art',
  'pop_art',
  'retro_sticker',
  'riso_print',
  'stained_glass',
  'sticker_sheet',
  'vector_flat',
  'vinyl_toy',
  'watercolor',
];

const kActiveTextPresetIds = <String>[
  'bold_slogan',
  'bubble_letter',
  'chrome_3d_text',
  'comic_sound_fx',
  'cute_chat_text',
  'graffiti_tag_text',
  'handwritten_note',
  'luxury_gold_text',
  'neon_sign_text',
  'retro_badge_text',
];

void main() {
  group('suggestionsForPreset', () {
    test('returns matching presets for kawaii', () {
      final result = suggestionsForPreset('kawaii');
      expect(result, isNotEmpty);
      // All results should contain 'kawaii' in some suggestion's tags
      for (final text in result) {
        final match = kPromptSuggestions.any(
          (s) => s.text == text && s.presetTags.contains('kawaii'),
        );
        expect(match, isTrue, reason: '$text should have kawaii tag');
      }
    });

    test('returns matching presets for anime', () {
      final result = suggestionsForPreset('anime');
      expect(result, isNotEmpty);
      for (final text in result) {
        final match = kPromptSuggestions.any(
          (s) => s.text == text && s.presetTags.contains('anime'),
        );
        expect(match, isTrue, reason: '$text should have anime tag');
      }
    });

    test('returns all suggestions for unknown preset', () {
      final result = suggestionsForPreset('nonexistent_preset');
      expect(result.length, kPromptSuggestions.length);
    });
  });

  group('randomSuggestionFor', () {
    test('returns non-empty string', () {
      final result = randomSuggestionFor('kawaii');
      expect(result, isNotEmpty);
    });

    test('returns different values over multiple calls (probabilistic)', () {
      final results = <String>{};
      for (var i = 0; i < 20; i++) {
        results.add(randomSuggestionFor('kawaii'));
      }
      // With 15 kawaii prompts, 20 random calls should produce at least 2 unique values
      expect(results.length, greaterThanOrEqualTo(2));
    });

    test('never repeats the avoided suggestion when pool has >1 entry', () {
      const avoid = 'a sleepy panda eating bamboo';
      for (var i = 0; i < 100; i++) {
        final result = randomSuggestionFor(
          'vinyl_toy',
          avoid: avoid,
          rng: Random(i),
        );
        expect(result, isNot(avoid));
      }
    });

    test('uses seeded rng deterministically', () {
      final a = randomSuggestionFor('kawaii', rng: Random(42));
      final b = randomSuggestionFor('kawaii', rng: Random(42));
      expect(a, b);
    });

    test('avoid=null keeps default behavior', () {
      final result = randomSuggestionFor('kawaii', avoid: null, rng: Random(7));
      expect(result, isNotEmpty);
    });
  });

  group('preset tag coverage contract', () {
    test('every active image preset has at least 3 tagged suggestions', () {
      for (final presetId in kActiveImagePresetIds) {
        final matched = kPromptSuggestions
            .where((s) => s.presetTags.contains(presetId))
            .length;
        expect(
          matched,
          greaterThanOrEqualTo(3),
          reason: 'Image preset "$presetId" has only $matched tagged '
              'suggestion(s); add tags in kPromptSuggestions.',
        );
      }
    });

    test('every active text preset has at least 3 tagged suggestions', () {
      for (final presetId in kActiveTextPresetIds) {
        final matched = kTypographySuggestions
            .where((s) => s.presetTags.contains(presetId))
            .length;
        expect(
          matched,
          greaterThanOrEqualTo(3),
          reason: 'Text preset "$presetId" has only $matched tagged '
              'suggestion(s); add tags in kTypographySuggestions.',
        );
      }
    });
  });

  group('kPromptSuggestions', () {
    test('contains at least 25 suggestions', () {
      expect(kPromptSuggestions.length, greaterThanOrEqualTo(25));
    });

    test('all suggestions have non-empty text', () {
      for (final s in kPromptSuggestions) {
        expect(s.text, isNotEmpty);
        expect(s.presetTags, isNotEmpty);
      }
    });
  });
}
