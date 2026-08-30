# Add Pixazo SDXL Base 1.0 Provider — Implementation Plan

Created: 2026-07-02 14:30:00

## Objective

Add Pixazo's free SDXL Base 1.0 as a second model under the same `provider_name='pixazo'` family. Sits at the same `priority=1` as Flux-1 Schnell; ties broken by `created_at` so Flux remains primary (created earlier) and SDXL becomes immediate secondary within the free tier. SDXL supports `negative_prompt`, so the existing negative-prompt pipeline finally lands on the wire for one of the two Pixazo models.

## Scope

- **In scope**: new migration row, edge function adapter `callPixazoSdxl()` + dispatch refactor (`callPixazo()` switches on `model_name`).
- **Out of scope**: Flutter client changes, async/getDataBatch mode, base_url convention normalization (Flux keeps its existing `/getData` suffix pattern).

## Decisions (locked)

| # | Decision | Note |
|---|---|---|
| 1 | Same `provider_name='pixazo'` | `model_name='sdxl-base-1.0'` distinguishes the row. Mirrors OpenRouter pattern (one row per model). |
| 2 | Same priority=1 | Created later than Flux → tried second within tier-1 free. |
| 3 | `fallback_policy='always'` | Match Flux behavior; let chain fail over on rate-limit. |
| 4 | `negative_prompt` now supported for SDXL | Adapter will inject it. Flux keeps ignore behavior. |
| 5 | `base_url` holds full endpoint for SDXL | Flux keeps legacy `${base}/getData` convention. Each adapter knows its URL pattern. |
| 6 | No new `ProviderName` member, no switch-case change | One provider_name, two adapter code paths via internal dispatch. |

## Architecture

```
loadConfigsForRequest(uid)
  → priority ASC, created_at ASC
     → pixazo / flux-1-schnell (priority=1, created first  → TRY FIRST)
     → pixazo / sdxl-base-1.0  (priority=1, created later → TRY SECOND)
     → openrouter (priority=2)
     → gemini     (priority=3)
     → pollinations (priority=4)

callPixazo(config, prompt, negative):
  if (config.model_name startsWith "sdxl-")
    → callPixazoSdxl(config, prompt, negative)    // uses negative_prompt
  else
    → callPixazoFlux(config, prompt, negative)    // ignores negative
```

Failover safety: same as before. 429 from either Pixazo model is retryable → cascades to OpenRouter/Gemini/Pollinations.

## Files Changed

| File | Type |
|---|---|
| `supabase/migrations/20260702000011_add_pixazo_sdxl.sql` | NEW |
| `supabase/functions/generate-sticker/index.ts` | MODIFY |
| `PROJECT_MEMORY.md` | UPDATE |

No Flutter app changes.

## API Reference (Pixazo SDXL Base 1.0)

From `https://www.pixazo.ai/models/sdxl`:

- **Submit URL**: `POST https://gateway.pixazo.ai/getImage/v1/getSDXLImage`
- **Auth header**: `Ocp-Apim-Subscription-Key: <API_KEY>` (same as Flux).
- **Other headers**: `Content-Type: application/json`, `Cache-Control: no-cache`.
- **Body**:
  ```json
  {
    "prompt": "<string, required>",
    "negative_prompt": "<string, optional — NOW WIRED>",
    "height": 1024,            // 512-1536
    "width": 1024,             // 512-1536
    "num_steps": 20,           // 1-20 (max 20)
    "guidance_scale": 5,       // 1-15 (typical 5-8)
    "seed": 40
  }
  ```
- **Response**: `{ "imageUrl": "https://...r2.dev/sdxl-base-1.0/...png" }` (NOTE: field name `imageUrl`, NOT `output`)
- **Rate limit**: 60 req/min (free preview fair use).
- **Pricing**: Free.

## DB Migration

`supabase/migrations/20260702000011_add_pixazo_sdxl.sql`:

```sql
-- Seed SDXL Base 1.0 under the existing 'pixazo' provider family.
-- Same priority=1 as Flux-1 Schnell; created_at determines order (SDXL tried second).
-- No CHECK constraint change needed (already allows 'pixazo' from migration 10).

INSERT INTO public.image_generation_configs (
    provider_name,
    model_name,
    base_url,
    api_key,
    priority,
    is_active,
    route_scope,
    fallback_policy,
    timeout_ms,
    request_options,
    label,
    notes
) VALUES (
    'pixazo',
    'sdxl-base-1.0',
    'https://gateway.pixazo.ai/getImage/v1/getSDXLImage',
    NULL,
    1,
    TRUE,
    'default',
    'always',
    90000,
    '{"num_steps": 20, "guidance_scale": 5, "height": 1024, "width": 1024}'::jsonb,
    'Pixazo SDXL Base 1.0 (FREE)',
    'Free tier, 60 req/min rate limit. Patch api_key after deploy. Supports negative_prompt.'
)
ON CONFLICT DO NOTHING;
```

Post-deploy one-off (manual via Supabase SQL editor, only if a separate API key is needed for this model):
```sql
UPDATE public.image_generation_configs
   SET api_key = '<PIXAZO_SUBSCRIPTION_KEY>'
 WHERE provider_name = 'pixazo'
   AND model_name    = 'sdxl-base-1.0'
   AND api_key IS NULL;
```

Same key as Flux row is expected, but stored per row for flexibility. Not strictly required if the row shares Flux's key.

## Edge Function Changes (`generate-sticker/index.ts`)

### 1. Add `PixazoSdxlResponse` interface (after existing `PixazoSyncResponse`)

```ts
interface PixazoSdxlResponse {
  imageUrl?: string;        // CDN URL to generated PNG
  error?: string;
  message?: string;
}
```

### 2. Rename existing `callPixazo()` → `callPixazoFlux()`

Behavior unchanged, just rename for clarity.

### 3. Add new `callPixazoSdxl()`

```ts
async function callPixazoSdxl(
  config: ImageGenerationConfig,
  prompt: string,
  negative: string | null,
): Promise<{ bytes: Uint8Array; contentType: string }> {
  const apiKey = requireApiKey(config);
  const url = (config.base_url ?? "https://gateway.pixazo.ai/getImage/v1/getSDXLImage")
      .replace(/\/$/, "");
  const opts = config.request_options ?? {};

  const body: Record<string, unknown> = { prompt };
  if (negative) body.negative_prompt = negative;

  const numSteps = Number(opts.num_steps ?? 20);
  if (Number.isFinite(numSteps) && numSteps >= 1 && numSteps <= 20) body.num_steps = numSteps;
  const guidance = Number(opts.guidance_scale ?? 5);
  if (Number.isFinite(guidance) && guidance >= 1 && guidance <= 15) body.guidance_scale = guidance;
  const seed = Number(opts.seed);
  if (Number.isFinite(seed)) body.seed = seed;
  const height = Number(opts.height ?? 1024);
  if (Number.isFinite(height) && height >= 512 && height <= 1536) body.height = height;
  const width = Number(opts.width ?? 1024);
  if (Number.isFinite(width) && width >= 512 && width <= 1536) body.width = width;

  const res = await fetchWithTimeout(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-cache",
      "Ocp-Apim-Subscription-Key": apiKey,
    },
    body: JSON.stringify(body),
  }, config.timeout_ms);

  if (!res.ok) throw providerErrorFromHttp("pixazo", res.status, await res.text());

  const data = (await res.json()) as PixazoSdxlResponse;
  if (!data.imageUrl || typeof data.imageUrl !== "string") {
    throw new ProviderError(
      `Pixazo SDXL response missing imageUrl: ${safeString(data, 200)}`,
      422, true, "schema_mismatch",
    );
  }
  return imageFromUrl(data.imageUrl, config.timeout_ms);
}
```

### 4. Add new `callPixazo()` dispatcher

```ts
async function callPixazo(
  config: ImageGenerationConfig,
  prompt: string,
  negative: string | null,
): Promise<{ bytes: Uint8Array; contentType: string }> {
  const model = (config.model_name ?? "").toLowerCase();
  if (model.startsWith("sdxl-")) {
    return callPixazoSdxl(config, prompt, negative);
  }
  return callPixazoFlux(config, prompt, negative);
}
```

No changes needed elsewhere:
- `callProvider()` switch-case unchanged (`case "pixazo"`).
- `logAttempt()` and `callImageProviderChain()` unchanged.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Two Pixazo rows at same priority=1 → tie-break depends on `created_at` | Documented; deterministic. To force SDXL first, manually `UPDATE created_at` (acceptable ops tweak). |
| Different base_url conventions per model (Flux uses prefix+`/getData`, SDXL uses full URL) | Each adapter owns its URL pattern. Self-contained, no cross-adapter coupling. |
| Free tier at 60 req/min shared between two Pixazo models | Effective combined limit ~60/min (per Pixazo account, not per model). Failover to paid providers kicks in transparently. |
| `negative_prompt` exceeds SDXL body length limit (model-specific) | Sent as-is from existing `ctx.negativePrompt`. Existing sanitization (`sanitizeNegativePrompt`) trims text-artifact terms when caption present. |
| SDXL returns `imageUrl: ""` (sample response in docs is empty string) | `!data.imageUrl` truthy check throws `422 schema_mismatch` → retryable → failover to OpenRouter. Safe. |
| Adding `pixazo` rows multiplies anti-bot budget drain | Each generation still counts 1 anti-bot event regardless of providers tried. No double counting. |

## Verification Commands (suggested)

```bash
# 1. Apply migration + deploy function
supabase db push
supabase functions deploy generate-sticker

# 2. Patch SDXL API key (manual via SQL editor; same key as Flux typically OK)
# UPDATE public.image_generation_configs
#    SET api_key = '<PIXAZO_KEY>'
#  WHERE provider_name = 'pixazo' AND model_name = 'sdxl-base-1.0';

# 3. Smoke test
supabase functions serve generate-sticker --env-file .env.local
# auth'd POST { presetId: "kawaii", userInput: "happy cat" }
# Expect: HTTP 200, signedUrl, attempt log with provider_name='pixazo',
#         model_name='flux-1-schnell' (Flux first due to created_at)

# Force-SDXL test: temporarily flip created_at
# UPDATE image_generation_configs SET created_at=now()
#   WHERE provider_name='pixazo' AND model_name='sdxl-base-1.0';
# Expect: attempt log with provider_name='pixazo', model_name='sdxl-base-1.0'

# Force-failover test
# UPDATE ... SET api_key='bogus' WHERE provider_name='pixazo';
# Expect: HTTP 200 with provider_name='openrouter' (or 'gemini' if OR down)

# 4. Static checks
flutter analyze
flutter test
```

## Proposed Commit Message

```
feat(providers): add Pixazo SDXL Base 1.0 as secondary free-tier model
```
