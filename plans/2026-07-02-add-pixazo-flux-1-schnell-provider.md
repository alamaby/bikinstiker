# Add Pixazo Flux-1-Schnell Provider — Implementation Plan

Created: 2026-07-02 12:00:00

## Objective

Add Pixazo's free Flux-1-Schnell as a new image generation provider in the failover chain at primary priority (cost-saving — paid OpenRouter/Gemini become fallbacks). Provider is consumed from the Edge Function via the existing DB-driven `image_generation_configs` mechanism. No client-side changes required.

## Scope

- **In scope**: DB schema constraint extension + seed row, edge function call adapter `callPixazo()`, switch-case in `callProvider()`, priority bump for existing providers.
- **Out of scope**: Flutter client changes (provider selection is server-only), negative-prompt support (Pixazo lacks it — silently dropped), async/webhook mode (`getDataBatch` + `checkStatus` not used).

## Decisions (locked)

| # | Decision | Note |
|---|---|---|
| 1 | Sync mode via `/flux-1-schnell/v1/getData` | URL the user shared; simpler than async polling |
| 2 | Primary position in failover (priority=1) | Free tier → save paid credits |
| 3 | `fallback_policy = 'always'` for Pixazo | 60 req/min means frequent failover; `always` skips internal retries |
| 4 | API key stored via `api_key` column | Matches existing pattern (OpenRouter/Gemini/Pollinations) |

## Architecture

```
User → generate-sticker Edge Function
  → loadConfigsForRequest(uid)
     → order by priority ASC
     → [NEW] pixazo        (priority=1, fallback_policy=always)
     → openrouter          (priority=2, was 1)
     → gemini              (priority=3, was 2)
     → pollinations        (priority=4, was 3)
  → callImageProviderChain(ctx)
     → try pixazo callPixazo() — POST /getData
        → on 429/5xx/422 → continue (fallback_policy=always)
     → fall through to OpenRouter/Gemini/Pollinations as before
```

Failover safety: 429 from Pixazo is retryable (`isRetryableStatus` already covers it) → 60 req/min limit transparently fails over to paid providers.

## Files Changed

| File | Type |
|---|---|
| `supabase/migrations/20260702000010_add_pixazo_provider.sql` | NEW |
| `supabase/functions/generate-sticker/index.ts` | MODIFY |
| `PROJECT_MEMORY.md` | UPDATE |

No Flutter app changes — provider routing is opaque to the client.

## API Reference (Pixazo Flux-1-Schnell, verified from `https://www.pixazo.ai/models/flux`)

- **Submit URL**: `POST https://gateway.pixazo.ai/flux-1-schnell/v1/getData`
- **Auth header**: `Ocp-Apim-Subscription-Key: <API_KEY>` (exact spelling — note uppercase `Ocp-Apim`).
- **Other headers**: `Content-Type: application/json`, `Cache-Control: no-cache`.
- **Body**:
  ```json
  {
    "prompt": "<string, required>",
    "num_steps": 4,
    "seed": <integer, optional>,
    "height": 1024,
    "width": 1024
  }
  ```
- **Sync response**: `{ "output": "https://pub-...r2.dev/flux-schnell-cf/....png" }`
- **Rate limit**: 60 req/min (free preview fair use).
- **Not supported**: negative_prompt, output_format, safety_tolerance — silently ignored if passed.
- **Recommended dimensions**: 512, 768, 1024, 1280, 1536, 1920.

## DB Migration

`supabase/migrations/20260702000010_add_pixazo_provider.sql`:

```sql
-- 1. Extend provider_name CHECK constraint to include 'pixazo'.
ALTER TABLE public.image_generation_configs
    DROP CONSTRAINT IF EXISTS image_generation_configs_provider_check;

ALTER TABLE public.image_generation_configs
    ADD CONSTRAINT image_generation_configs_provider_check
    CHECK (provider_name IN ('openrouter', 'gemini', 'pollinations', 'pixazo'));

-- 2. Bump priorities of existing providers by 1 to make room for Pixazo at 1.
UPDATE public.image_generation_configs
   SET priority = priority + 1,
       updated_at = timezone('utc'::text, now())
 WHERE provider_name IN ('openrouter', 'gemini', 'pollinations');

-- 3. Seed Pixazo row at priority=1.
INSERT INTO public.image_generation_configs (
    provider_name, model_name, base_url, api_key,
    priority, is_active, route_scope, fallback_policy,
    timeout_ms, request_options, label, notes
) VALUES (
    'pixazo',
    'flux-1-schnell',
    'https://gateway.pixazo.ai/flux-1-schnell/v1',
    NULL,
    1,
    TRUE,
    'default',
    'always',
    90000,
    '{"num_steps": 4, "height": 1024, "width": 1024}'::jsonb,
    'Pixazo Flux-1 Schnell (FREE)',
    'Free tier, 60 req/min rate limit. Patch api_key after deploy.'
)
ON CONFLICT DO NOTHING;
```

Post-deploy one-off (manual via Supabase SQL editor, NOT in repo):
```sql
UPDATE public.image_generation_configs
   SET api_key = '<PIXAZO_SUBSCRIPTION_KEY>'
 WHERE provider_name = 'pixazo'
   AND model_name    = 'flux-1-schnell';
```

## Edge Function Changes (`generate-sticker/index.ts`)

### 1. Extend `ProviderName` union

```ts
type ProviderName = "openrouter" | "gemini" | "pollinations" | "pixazo";
```

### 2. Add Pixazo response type

```ts
interface PixazoSyncResponse {
  output?: string;          // CDN URL to generated PNG
  error?: string;
  message?: string;
}
```

### 3. Add adapter `callPixazo(config, prompt, negative)`

```ts
async function callPixazo(
  config: ImageGenerationConfig,
  prompt: string,
  negative: string | null,    // accepted but ignored — Pixazo lacks support
): Promise<{ bytes: Uint8Array; contentType: string }> {
  const apiKey = requireApiKey(config);
  const baseUrl = (config.base_url ?? "https://gateway.pixazo.ai/flux-1-schnell/v1")
      .replace(/\/$/, "");
  const opts = config.request_options ?? {};

  const body: Record<string, unknown> = { prompt };
  const numSteps = Number(opts.num_steps ?? 4);
  if (Number.isFinite(numSteps) && numSteps >= 1 && numSteps <= 4) body.num_steps = numSteps;
  const seed = Number(opts.seed);
  if (Number.isFinite(seed)) body.seed = seed;
  const height = Number(opts.height ?? 1024);
  if (Number.isFinite(height) && height >= 64 && height <= 2048) body.height = height;
  const width = Number(opts.width ?? 1024);
  if (Number.isFinite(width) && width >= 64 && width <= 2048) body.width = width;

  const res = await fetchWithTimeout(`${baseUrl}/getData`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-cache",
      "Ocp-Apim-Subscription-Key": apiKey,
    },
    body: JSON.stringify(body),
  }, config.timeout_ms);

  if (!res.ok) throw providerErrorFromHttp("pixazo", res.status, await res.text());

  const data = (await res.json()) as PixazoSyncResponse;
  if (!data.output || typeof data.output !== "string") {
    throw new ProviderError(
      `Pixazo response missing output URL: ${safeString(data, 200)}`,
      422, true, "schema_mismatch",
    );
  }
  return imageFromUrl(data.output, config.timeout_ms);
}
```

Notes:
- `negative` param is accepted but ignored.
- Image bytes fetched via existing `imageFromUrl()` — handles content-type, magic-byte fallback, retryable status.
- `422 schema_mismatch` already retryable → auto-failover if Pixazo contract drifts.

### 4. Wire into switch

```ts
async function callProvider(...): Promise<...> {
  switch (config.provider_name) {
    case "openrouter":   return callOpenRouter(config, prompt, negative);
    case "gemini":       return callGemini(config, prompt, negative);
    case "pollinations": return callPollinations(config, prompt, negative);
    case "pixazo":       return callPixazo(config, prompt, negative);
  }
}
```

No other code paths need changes:
- `logAttempt()` reads `provider_name` from config row, not hardcoded.
- `callImageProviderChain()` iterates `configs` in priority order.
- `image_generation_attempt_logs.provider_name` is unconstrained TEXT — accepts `'pixazo'` without migration.
- `sticker_generations.provider_name` is unconstrained TEXT — same.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Pixazo 60 req/min rate-limit triggers frequent failover → user-visible latency | Acceptable; chain already designed for failover. `fallback_policy=always` skips Pixazo retries. |
| Pixazo contract drift (`output` field renames, new auth scheme) | `422 schema_mismatch` is retryable → auto-failover. Versioned path `/v1/` is in `base_url`, easy to patch. |
| Wrong API key for `Ocp-Apim-Subscription-Key` (case-sensitive header) | Header name hardcoded exactly. `requireApiKey()` throws clear `missing_api_key`. |
| Free model quality lower than paid OpenRouter | Acceptable tradeoff for cost savings. Future tuning via DB-only edit (`num_steps`, dimensions). |
| Pixazo blocks at 60s eats GenWindow anti-bot budget | Each generation = 1 anti-bot event regardless of providers tried. No double counting. |

## Verification Commands (suggested)

```bash
# 1. Apply migration + deploy function
supabase db push
supabase functions deploy generate-sticker

# 2. Patch Pixazo API key (manual via SQL editor — NOT in repo)
# UPDATE public.image_generation_configs
#    SET api_key = '<PIXAZO_KEY>'
#  WHERE provider_name = 'pixazo' AND model_name = 'flux-1-schnell';

# 3. Smoke test
supabase functions serve generate-sticker --env-file .env.local
# auth'd POST { presetId: "kawaii", userInput: "happy cat" }
# Expect: HTTP 200, signedUrl, attempt log row with provider_name='pixazo'

# Force-failover test
# UPDATE image_generation_configs SET api_key='bogus' WHERE provider_name='pixazo';
# Expect: HTTP 200 with provider_name='openrouter' (or 'gemini' if OR down)

# 4. Static checks
flutter analyze
flutter test
```

## Proposed Commit Message

```
feat(providers): add Pixazo Flux-1-Schnell as primary free-tier image provider
```
