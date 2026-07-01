/// Search keywords per emoji for typeahead search.
/// Curated for common queries.
const kEmojiKeywords = <String, List<String>>{
  // Smileys
  '😀': ['smile', 'happy', 'grin', 'face', 'grinning'],
  '😃': ['smile', 'happy', 'grin', 'face', 'grinning', 'eyes'],
  '😄': ['smile', 'happy', 'grin', 'face', 'eyes', 'laugh'],
  '😁': ['grin', 'happy', 'face', 'beaming'],
  '😆': ['laugh', 'happy', 'grin', 'face'],
  '😅': ['nervous', 'sweat', 'smile', 'face'],
  '🤣': ['rolling', 'laugh', 'floor', 'lol'],
  '😂': ['laugh', 'joy', 'tears', 'funny', 'lol', 'crying'],
  '🙂': ['slight', 'smile', 'face'],
  '🙃': ['upside', 'down', 'face', 'silly'],
  '😉': ['wink', 'face'],
  '😊': ['blush', 'happy', 'face', 'shy'],
  '😇': ['angel', 'halo', 'innocent', 'face'],
  '🥰': ['love', 'hearts', 'smiling', 'adore', 'face'],
  '😍': ['love', 'heart', 'eyes', 'smiling', 'in love'],
  '🤩': ['star', 'eyes', 'excited', 'wow', 'face'],
  '😘': ['kiss', 'love', 'face'],
  '😗': ['kiss', 'face'],
  '😚': ['kiss', 'closed', 'eyes', 'face'],
  '😙': ['kiss', 'smile', 'face'],
  '🥲': ['tear', 'smile', 'sad', 'face'],
  '😋': ['yum', 'delicious', 'face', 'tongue'],
  '😛': ['tongue', 'face', 'playful'],
  '😜': ['crazy', 'tongue', 'wink', 'face', 'silly'],
  '🤪': ['zany', 'crazy', 'face', 'wild'],
  '😝': ['gross', 'tongue', 'face', 'yuck'],
  '🤑': ['money', 'face', 'rich', 'dollar'],
  '🤗': ['hug', 'face', 'warm'],
  '🤭': ['oops', 'face', 'giggle', 'shy'],
  '🤫': ['shush', 'quiet', 'secret', 'face'],
  '🤔': ['thinking', 'hmm', 'consider', 'face'],
  '🫡': ['salute', 'respect', 'face'],
  '🤐': ['zip', 'mouth', 'quiet', 'face'],
  '🤨': ['raised', 'eyebrow', 'skeptical', 'face'],
  '😐': ['neutral', 'face', 'meh'],
  '😑': ['expressionless', 'face'],
  '😶': ['no', 'mouth', 'face', 'silent'],
  '❤️': ['love', 'heart', 'red', 'valentine'],
  '🔥': ['fire', 'lit', 'hot', 'flame'],
  '✨': ['sparkle', 'shine', 'magic'],
  '💯': ['hundred', 'perfect', '100'],
  '⭐': ['star', 'favorite'],
  '🌟': ['star', 'shine', 'glow'],
  '😏': ['smirk', 'face', 'sly'],
  '😒': ['unamused', 'face', 'bored'],
  '🙄': ['eye', 'roll', 'face'],
  '😬': ['grimace', 'face', 'awkward'],
  '🤥': ['lying', 'nose', 'face', 'pinocchio'],
  '😌': ['relieved', 'face', 'calm'],
  '😔': ['sad', 'face', 'pensive'],
  '😪': ['sleepy', 'face', 'tired'],
  '🤤': ['drool', 'face', 'yummy'],
  '😴': ['sleep', 'sleepy', 'zzz', 'tired', 'face'],
  '😷': ['mask', 'sick', 'face', 'ill'],
  '🤒': ['thermometer', 'sick', 'face', 'ill'],
  '🤕': ['bandage', 'hurt', 'face', 'injured'],
  '🤢': ['nauseous', 'sick', 'face', 'green'],
  '🤮': ['vomit', 'sick', 'face', 'puke'],
  '🥵': ['hot', 'face', 'sweating'],
  '🥶': ['cold', 'face', 'freezing'],
  '🥴': ['woozy', 'face', 'drunk', 'dizzy'],
  '😵': ['dizzy', 'face', 'knocked out'],
  '🤯': ['mind', 'blown', 'face', 'explode', 'shocked'],
  '🥳': ['party', 'face', 'celebrate', 'birthday'],
  '🥸': ['disguise', 'face', 'incognito'],
  '😎': ['cool', 'sunglasses', 'awesome', 'face'],
  '🤓': ['nerd', 'face', 'geek', 'smart'],
  '🧐': ['monocle', 'face', 'fancy', 'inspect'],
  '😕': ['confused', 'face'],
  '😟': ['worried', 'face', 'sad'],
};

/// Search emojis by query.
/// Returns list of matching emoji strings.
List<String> searchEmojis(String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return [];
  final results = <String>[];
  for (final entry in kEmojiKeywords.entries) {
    if (entry.value.any((kw) => kw.contains(q))) {
      results.add(entry.key);
    }
  }
  return results;
}
