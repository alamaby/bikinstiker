import 'package:bikin_stiker/core/constants/emoji_keywords.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('searchEmojis', () {
    test('returns empty list for empty query', () {
      expect(searchEmojis(''), isEmpty);
    });

    test('returns matching emojis for "love"', () {
      final results = searchEmojis('love');
      expect(results, isNotEmpty);
      // Should contain common love emojis
      expect(results, contains('❤️'));
      expect(results, contains('😍'));
    });

    test('returns matching emojis for "happy"', () {
      final results = searchEmojis('happy');
      expect(results, isNotEmpty);
      expect(results, contains('😀'));
    });

    test('returns empty list for no match', () {
      final results = searchEmojis('zzzzz999');
      expect(results, isEmpty);
    });

    test('is case insensitive', () {
      final lower = searchEmojis('happy');
      final upper = searchEmojis('HAPPY');
      expect(lower, equals(upper));
    });

    test('trims whitespace', () {
      final results = searchEmojis('  happy  ');
      expect(results, isNotEmpty);
    });

    test('returns multiple results for "cool"', () {
      final results = searchEmojis('cool');
      expect(results.length, greaterThanOrEqualTo(1));
    });
  });

  group('kEmojiKeywords', () {
    test('has at least 50 entries', () {
      expect(kEmojiKeywords.length, greaterThanOrEqualTo(50));
    });

    test('all entries have non-empty emoji key', () {
      for (final key in kEmojiKeywords.keys) {
        expect(key, isNotEmpty);
      }
    });

    test('all entries have non-empty keywords list', () {
      for (final entry in kEmojiKeywords.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} has no keywords');
      }
    });
  });
}
