# Sticker Caption Overlay — Implementation Plan

Created: 2026-07-01 12:00:00

## Objective

Add optional short caption (max 10 chars) rendered directly onto the sticker image at top or bottom position.

## Scope

- DB columns: `caption_text` + `caption_position` on `sticker_generations`
- Server-side: validation, prompt injection, negative prompt sanitization, DB write
- Client-side: TextField + position picker, state, bloc, repository
- Deterministic post-processing (not LLM-enhanced)

## Architecture

Caption bypasses LLM enhancement layer. Flow:

```
user input → LLM enhancement (cached: v2|presetId|styleDescriptor|userInput)
       ↓
enhanced positive
       ↓
+ caption clause (deterministic)
- text artifacts from negative (if caption present)
       ↓
final prompt → image model
```

Complements the reasoning system prompt update (`20260701000004`) which handles
user-explicit text requests in the free-form prompt.

## Files Changed

| File | Type |
|---|---|
| `supabase/migrations/20260701000005_add_caption_columns.sql` | NEW |
| `supabase/functions/generate-sticker/index.ts` | MODIFY |
| `lib/presentation/blocs/sticker_gen/sticker_gen_bloc.dart` | MODIFY |
| `lib/data/repositories/sticker_repository.dart` | MODIFY |
| `lib/presentation/screens/home/home_screen.dart` | MODIFY |
| `PROJECT_MEMORY.md` | UPDATE |

## DB Migration

```sql
ALTER TABLE public.sticker_generations
    ADD COLUMN IF NOT EXISTS caption_text     TEXT,
    ADD COLUMN IF NOT EXISTS caption_position TEXT;

ALTER TABLE public.sticker_generations
    ADD CONSTRAINT sticker_generations_caption_position_check
    CHECK (caption_position IS NULL OR caption_position IN ('top', 'bottom'));

ALTER TABLE public.sticker_generations
    ADD CONSTRAINT sticker_generations_caption_text_length_check
    CHECK (caption_text IS NULL OR length(caption_text) <= 10);
```

## Server Changes (generate-sticker/index.ts)

1. **Input validation**: caption max 10 chars, regex `^[A-Z0-9 .!?-]+$`
2. **`appendCaptionClause()`**: deterministic text clause with position
3. **`sanitizeNegativePrompt()`**: strip text artifacts when caption present
4. **`buildFinalPrompt()` / `buildEnhancedFinalPrompt()`**: accept caption params
5. **DB update**: write `caption_text` + `caption_position`

## Client Changes

### Bloc
- `StickerGenSubmitted`: add optional `caption` + `captionPosition`

### Repository
- `generate()`: accept optional `caption` + `captionPosition`, forward in body

### UI (home_screen.dart)
- New state: `_captionCtrl`, `_captionPosition`
- Caption TextField: max 10 chars, uppercase + digits + ` .!?-`, auto-uppercase
- Position picker: SegmentedButton (Top/Bottom), visible only when caption non-empty
- Default position: bottom

## Verification

- `supabase db push` (requires SUPABASE_DB_PASSWORD)
- `supabase functions deploy generate-sticker`
- `flutter analyze && flutter test`

## Propose Commit Message

`feat(sticker): add optional caption overlay with top/bottom positioning`