# Typography Presets Implementation Plan

Created: 2026-07-02 10:00:00

## Objective
Add 10 text-only typography sticker presets to BikinStiker with server-side validation and dynamic UI adaptation.

## Scope
- [x] Add `input_mode` column to `sticker_presets` table
- [x] Seed 10 typography presets (6 free + 4 plus)
- [x] Expose `inputMode` in list-presets API
- [x] Enforce text-only constraints in generate-sticker edge function
- [x] Update Flutter model with `StickerPresetInputMode` enum
- [x] Dynamic UI: label, hint, maxLength, hide caption
- [x] Text-only suggestions and Surprise Me

## Milestones
1. Database migration complete
2. Edge functions updated
3. Flutter model updated
4. UI adapted for text-only presets
5. Suggestions system updated

## Tasks
- [x] Create migration `20260702000012_typography_presets.sql`
- [x] Update `list-presets/index.ts` to expose `inputMode`
- [x] Update `generate-sticker/index.ts` with text-only validation
- [x] Update `sticker_preset.dart` model
- [x] Update `home_screen.dart` UI
- [x] Update `prompt_suggestions.dart` with typography suggestions
- [x] Update `surprise_me_button.dart` with `textOnly` flag
- [x] Update `prompt_suggestion_chip.dart` with `textOnly` flag
- [x] Update `PROJECT_MEMORY.md`

## Risks
- Existing presets default to `input_mode='subject'` (non-breaking)
- Text-only presets limited to 20 chars (server-enforced)
- Caption nulled server-side for text-only (no client bypass)

## Notes
- Typography presets have `reasoning_guidance` for text preservation
- Failover chain unchanged: pixazo/flux → pixazo/sdxl → openrouter → gemini → pollinations
- All 10 presets seed via `ON CONFLICT DO UPDATE` (idempotent)
