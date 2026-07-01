import 'package:shared_preferences/shared_preferences.dart';

/// Tracks recently used emojis for the "Recent" tab in the emoji picker.
///
/// Stores up to 10 most recent emojis in SharedPreferences.
class RecentEmojisService {
  RecentEmojisService._();

  static const _prefsKey = 'recent_emojis_v1';
  static const _maxRecent = 10;

  /// Load recently used emojis from SharedPreferences.
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? [];
  }

  /// Add an emoji to the recent list.
  ///
  /// Moves it to the front (most recent). Deduplicates.
  static Future<void> add(String emoji) async {
    final current = await load();
    current.remove(emoji);
    current.insert(0, emoji);
    if (current.length > _maxRecent) {
      current.removeRange(_maxRecent, current.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, current);
  }
}
