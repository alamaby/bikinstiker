import 'dart:math';

class PromptSuggestion {
  final String text;
  final List<String> presetTags;
  const PromptSuggestion(this.text, this.presetTags);
}

const kPromptSuggestions = <PromptSuggestion>[
  // Kawaii / cute (15 prompts)
  PromptSuggestion('a smiling boba tea cup waving hello', ['kawaii', 'anime']),
  PromptSuggestion(
    'a sleepy panda eating bamboo',
    ['kawaii', 'vinyl_toy', 'origami'],
  ),
  PromptSuggestion(
    'a cute corgi wearing a party hat',
    ['kawaii', 'photoreal'],
  ),
  PromptSuggestion(
    'a tiny dragon drinking coffee',
    ['kawaii', 'claymation', 'stained_glass'],
  ),
  PromptSuggestion(
    'a happy cloud with a rainbow tail',
    ['kawaii', 'sticker_sheet', 'vector_flat', 'watercolor'],
  ),
  PromptSuggestion(
    'a chibi robot holding a heart balloon',
    ['kawaii', 'anime', 'chibi_3d', 'caricature'],
  ),
  PromptSuggestion(
    'a round hamster with a tiny backpack',
    ['kawaii', 'line_doodle', 'minimal_line'],
  ),
  PromptSuggestion(
    'a smiling sushi piece on a conveyor belt',
    ['kawaii', 'pop_art'],
  ),
  PromptSuggestion(
    'a cheerful mushroom wearing a beret',
    ['kawaii', 'riso_print', 'vector_flat'],
  ),
  PromptSuggestion(
    'a baby fox curled up on a crescent moon',
    ['kawaii', 'embroidery', 'stained_glass', 'origami', 'watercolor'],
  ),
  PromptSuggestion(
    'a giggling avocado with a tiny hat',
    ['kawaii', 'claymation', 'caricature'],
  ),
  PromptSuggestion(
    'a pastel bunny holding a lollipop',
    ['kawaii', 'vinyl_toy', 'chibi_3d'],
  ),
  PromptSuggestion(
    'a cute axolotl in a teacup',
    ['kawaii', 'anime', 'watercolor'],
  ),
  PromptSuggestion(
    'a happy snail with a sparkly shell',
    ['kawaii', 'sticker_sheet', 'vector_flat'],
  ),
  PromptSuggestion(
    'a tiny elephant blowing bubbles',
    ['kawaii', 'photoreal'],
  ),

  // Retro / vintage (5 prompts)
  PromptSuggestion(
    'a vintage radio playing jazz',
    ['riso_print', 'pop_art', 'retro_sticker', 'pixel_art'],
  ),
  PromptSuggestion(
    'a retro soda bottle with sunglasses',
    ['riso_print', 'retro_sticker'],
  ),
  PromptSuggestion(
    'a neon sign saying HELLO in cursive',
    ['neon_cyber', 'pop_art'],
  ),
  PromptSuggestion(
    'a polaroid camera with a flash',
    ['riso_print', 'photoreal', 'retro_sticker'],
  ),
  PromptSuggestion(
    'a classic muscle car with flames',
    ['pop_art', 'line_doodle', 'retro_sticker'],
  ),

  // Spooky / dark (3 prompts)
  PromptSuggestion(
    'a friendly ghost holding a lantern',
    ['stained_glass', 'embroidery'],
  ),
  PromptSuggestion(
    'a cute skull with flower crown',
    ['stained_glass', 'riso_print'],
  ),
  PromptSuggestion(
    'a black cat with glowing eyes',
    ['line_doodle', 'embroidery', 'minimal_line', 'origami'],
  ),

  // Action / dynamic (4 prompts)
  PromptSuggestion(
    'a cat surfing a pizza wave',
    ['pop_art', 'anime', 'caricature'],
  ),
  PromptSuggestion(
    'a rocket launching from a book',
    ['pop_art', 'claymation'],
  ),
  PromptSuggestion(
    'a wizard casting a sparkly spell',
    ['anime', 'neon_cyber', 'pixel_art', 'stained_glass'],
  ),
  PromptSuggestion(
    'a ninja cat throwing stars',
    ['anime', 'line_doodle', 'pixel_art', 'minimal_line'],
  ),

  // 3D / toy-like (3 prompts)
  PromptSuggestion(
    'a tiny astronaut floating in space',
    ['claymation', 'vinyl_toy', 'lego_voxel', 'chibi_3d', 'neon_cyber'],
  ),
  PromptSuggestion(
    'a robot made of cardboard boxes',
    ['claymation', 'sticker_sheet', 'lego_voxel'],
  ),
  PromptSuggestion(
    'a toy pirate ship in a bottle',
    ['vinyl_toy', 'origami', 'lego_voxel'],
  ),
];

const kTypographySuggestions = <PromptSuggestion>[
  // Bold Slogan
  PromptSuggestion('YOLO', ['bold_slogan']),
  PromptSuggestion('YAY', ['bold_slogan']),
  PromptSuggestion('BOSS', ['bold_slogan']),
  PromptSuggestion('SAY HI', ['bold_slogan']),
  PromptSuggestion('NOPE', ['bold_slogan']),
  PromptSuggestion('EPIC', ['bold_slogan']),

  // Bubble Letter
  PromptSuggestion('WOW', ['bubble_letter']),
  PromptSuggestion('YUM', ['bubble_letter']),
  PromptSuggestion('OMG', ['bubble_letter']),
  PromptSuggestion('HI', ['bubble_letter']),
  PromptSuggestion('BFF', ['bubble_letter']),
  PromptSuggestion('LOL', ['bubble_letter']),

  // Comic Sound FX
  PromptSuggestion('POW', ['comic_sound_fx']),
  PromptSuggestion('BOOM', ['comic_sound_fx']),
  PromptSuggestion('ZAP', ['comic_sound_fx']),
  PromptSuggestion('WHAM', ['comic_sound_fx']),
  PromptSuggestion('CRASH', ['comic_sound_fx']),
  PromptSuggestion('BAM', ['comic_sound_fx']),

  // Retro Badge Text
  PromptSuggestion('CERTIFIED COOL', ['retro_badge_text']),
  PromptSuggestion('OG', ['retro_badge_text']),
  PromptSuggestion('EST 2026', ['retro_badge_text']),
  PromptSuggestion('NUMBER ONE', ['retro_badge_text']),
  PromptSuggestion('VINTAGE', ['retro_badge_text']),
  PromptSuggestion('SALE', ['retro_badge_text']),

  // Handwritten Note
  PromptSuggestion('thank you', ['handwritten_note']),
  PromptSuggestion('you got this', ['handwritten_note']),
  PromptSuggestion('good luck', ['handwritten_note']),
  PromptSuggestion('love ya', ['handwritten_note']),
  PromptSuggestion('miss you', ['handwritten_note']),
  PromptSuggestion('sorry', ['handwritten_note']),

  // Cute Chat Text
  PromptSuggestion('omw', ['cute_chat_text']),
  PromptSuggestion('brb', ['cute_chat_text']),
  PromptSuggestion('ttyl', ['cute_chat_text']),
  PromptSuggestion('kk', ['cute_chat_text']),
  PromptSuggestion('same', ['cute_chat_text']),
  PromptSuggestion('nice', ['cute_chat_text']),

  // Chrome 3D Text (plus)
  PromptSuggestion('BOSS', ['chrome_3d_text']),
  PromptSuggestion('SALE', ['chrome_3d_text']),
  PromptSuggestion('VIP', ['chrome_3d_text']),
  PromptSuggestion('NEW', ['chrome_3d_text']),
  PromptSuggestion('HOT', ['chrome_3d_text']),
  PromptSuggestion('LIT', ['chrome_3d_text']),

  // Neon Sign Text (plus)
  PromptSuggestion('OPEN', ['neon_sign_text']),
  PromptSuggestion('HELLO', ['neon_sign_text']),
  PromptSuggestion('LOVE', ['neon_sign_text']),
  PromptSuggestion('OPEN 24H', ['neon_sign_text']),
  PromptSuggestion('BAR', ['neon_sign_text']),
  PromptSuggestion('CAFE', ['neon_sign_text']),

  // Graffiti Tag Text (plus)
  PromptSuggestion('YO', ['graffiti_tag_text']),
  PromptSuggestion('AIGHT', ['graffiti_tag_text']),
  PromptSuggestion('SICK', ['graffiti_tag_text']),
  PromptSuggestion('FIRE', ['graffiti_tag_text']),
  PromptSuggestion('WASSUP', ['graffiti_tag_text']),
  PromptSuggestion('NAH', ['graffiti_tag_text']),

  // Luxury Gold Text (plus)
  PromptSuggestion('THANK YOU', ['luxury_gold_text']),
  PromptSuggestion('CHEERS', ['luxury_gold_text']),
  PromptSuggestion('VIP', ['luxury_gold_text']),
  PromptSuggestion('CONGRATS', ['luxury_gold_text']),
  PromptSuggestion('GOLD', ['luxury_gold_text']),
  PromptSuggestion('LEGEND', ['luxury_gold_text']),
];

/// Returns suggestion texts tagged with [presetId].
///
/// If no suggestion carries the tag (e.g. a newly added DB preset that does
/// not have curated suggestions yet), falls back to the whole pool so the
/// "Surprise me" button always offers something. The server-side reasoning
/// layer adapts any prompt to the preset's style, so a loose fallback match
/// is acceptable.
List<String> suggestionsForPreset(String presetId, {bool textOnly = false}) {
  final source = textOnly ? kTypographySuggestions : kPromptSuggestions;
  final matched = source
      .where((s) => s.presetTags.contains(presetId))
      .map((s) => s.text)
      .toList();
  if (matched.isEmpty) {
    return source.map((s) => s.text).toList();
  }
  return matched;
}

/// Picks a random suggestion for [presetId], avoiding an immediate repeat of
/// [avoid] when the pool has more than one entry.
///
/// Pass the currently displayed/entered suggestion as [avoid] so consecutive
/// taps never yield the same value. [rng] is injectable for deterministic
/// tests.
String randomSuggestionFor(
  String presetId, {
  bool textOnly = false,
  String? avoid,
  Random? rng,
}) {
  final list = suggestionsForPreset(presetId, textOnly: textOnly);
  final pool = list.length > 1 && list.contains(avoid)
      ? list.where((s) => s != avoid).toList()
      : list;
  return pool[(rng ?? Random()).nextInt(pool.length)];
}
