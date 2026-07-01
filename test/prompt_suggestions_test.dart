import 'package:bikin_stiker/core/constants/prompt_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

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
