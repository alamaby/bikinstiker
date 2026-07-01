import 'package:bikin_stiker/core/constants/emoji_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kEmojiCategories', () {
    test('has 11 categories (1 Recent + 10)', () {
      expect(kEmojiCategories.length, 11);
    });

    test('first category is Recent with empty emojis', () {
      final recent = kEmojiCategories.first;
      expect(recent.name, 'Recent');
      expect(recent.icon, '🕘');
      expect(recent.emojis, isEmpty);
    });

    test('non-Recent categories have at least 30 emojis each', () {
      for (final cat in kEmojiCategories.skip(1)) {
        expect(
          cat.emojis.length,
          greaterThanOrEqualTo(30),
          reason: '${cat.name} should have at least 30 emojis',
        );
      }
    });

    test('all emojis are unique within their category', () {
      for (final cat in kEmojiCategories) {
        final uniqueEmojis = cat.emojis.toSet();
        expect(
          uniqueEmojis.length,
          cat.emojis.length,
          reason: '${cat.name} has duplicate emojis',
        );
      }
    });

    test('total emojis across non-Recent categories is at least 300', () {
      final total = kEmojiCategories
          .skip(1)
          .fold<int>(0, (sum, cat) => sum + cat.emojis.length);
      expect(total, greaterThanOrEqualTo(300));
    });

    test('all categories have non-empty name and icon', () {
      for (final cat in kEmojiCategories) {
        expect(cat.name, isNotEmpty);
        expect(cat.icon, isNotEmpty);
      }
    });
  });
}
