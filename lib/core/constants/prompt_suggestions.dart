import 'dart:math';

class PromptSuggestion {
  final String text;
  final List<String> presetTags;
  const PromptSuggestion(this.text, this.presetTags);
}

const kPromptSuggestions = <PromptSuggestion>[
  // Kawaii / cute (15 prompts)
  PromptSuggestion('a smiling boba tea cup waving hello', ['kawaii', 'anime']),
  PromptSuggestion('a sleepy panda eating bamboo', ['kawaii', 'vinyl_toy']),
  PromptSuggestion(
    'a cute corgi wearing a party hat',
    ['kawaii', 'photoreal'],
  ),
  PromptSuggestion('a tiny dragon drinking coffee', ['kawaii', 'claymation']),
  PromptSuggestion(
    'a happy cloud with a rainbow tail',
    ['kawaii', 'sticker_sheet'],
  ),
  PromptSuggestion(
    'a chibi robot holding a heart balloon',
    ['kawaii', 'anime'],
  ),
  PromptSuggestion(
    'a round hamster with a tiny backpack',
    ['kawaii', 'line_doodle'],
  ),
  PromptSuggestion(
    'a smiling sushi piece on a conveyor belt',
    ['kawaii', 'pop_art'],
  ),
  PromptSuggestion(
    'a cheerful mushroom wearing a beret',
    ['kawaii', 'riso_print'],
  ),
  PromptSuggestion(
    'a baby fox curled up on a crescent moon',
    ['kawaii', 'embroidery'],
  ),
  PromptSuggestion(
    'a giggling avocado with a tiny hat',
    ['kawaii', 'claymation'],
  ),
  PromptSuggestion(
    'a pastel bunny holding a lollipop',
    ['kawaii', 'vinyl_toy'],
  ),
  PromptSuggestion(
    'a cute axolotl in a teacup',
    ['kawaii', 'anime'],
  ),
  PromptSuggestion(
    'a happy snail with a sparkly shell',
    ['kawaii', 'sticker_sheet'],
  ),
  PromptSuggestion(
    'a tiny elephant blowing bubbles',
    ['kawaii', 'photoreal'],
  ),

  // Retro / vintage (5 prompts)
  PromptSuggestion(
    'a vintage radio playing jazz',
    ['riso_print', 'pop_art'],
  ),
  PromptSuggestion(
    'a retro soda bottle with sunglasses',
    ['riso_print'],
  ),
  PromptSuggestion(
    'a neon sign saying HELLO in cursive',
    ['neon_cyber', 'pop_art'],
  ),
  PromptSuggestion(
    'a polaroid camera with a flash',
    ['riso_print', 'photoreal'],
  ),
  PromptSuggestion(
    'a classic muscle car with flames',
    ['pop_art', 'line_doodle'],
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
    ['line_doodle', 'embroidery'],
  ),

  // Action / dynamic (4 prompts)
  PromptSuggestion(
    'a cat surfing a pizza wave',
    ['pop_art', 'anime'],
  ),
  PromptSuggestion(
    'a rocket launching from a book',
    ['pop_art', 'claymation'],
  ),
  PromptSuggestion(
    'a wizard casting a sparkly spell',
    ['anime', 'neon_cyber'],
  ),
  PromptSuggestion(
    'a ninja cat throwing stars',
    ['anime', 'line_doodle'],
  ),

  // 3D / toy-like (3 prompts)
  PromptSuggestion(
    'a tiny astronaut floating in space',
    ['claymation', 'vinyl_toy'],
  ),
  PromptSuggestion(
    'a robot made of cardboard boxes',
    ['claymation', 'sticker_sheet'],
  ),
  PromptSuggestion(
    'a toy pirate ship in a bottle',
    ['vinyl_toy', 'origami'],
  ),
];

List<String> suggestionsForPreset(String presetId) {
  final matched = kPromptSuggestions
      .where((s) => s.presetTags.contains(presetId))
      .map((s) => s.text)
      .toList();
  if (matched.isEmpty) {
    return kPromptSuggestions.map((s) => s.text).toList();
  }
  return matched;
}

String randomSuggestionFor(String presetId) {
  final list = suggestionsForPreset(presetId);
  return list[Random().nextInt(list.length)];
}
