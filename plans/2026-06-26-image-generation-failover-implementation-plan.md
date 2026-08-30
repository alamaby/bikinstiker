# Image Generation Failover Implementation Plan

Created: 2026-06-26 16:46:23

## Objective
Implement DB-driven image generation failover for the `generate-sticker` Supabase Edge Function so provider/model routing and API key rotation can be patched in Supabase without releasing a new mobile app version.

## Scope
- Add Supabase tables for image generation provider configs, user overrides, and attempt logs.
- Store provider API keys in Supabase internal tables with RLS enabled and no client policies.
- Support initial providers: OpenRouter, Gemini Image, and Pollinations.ai.
- Keep the Flutter client API contract unchanged.
- Preserve current credit deduction/refund behavior.
- Update backend docs and project memory.

## Milestones
1. Phase 1 - Add database control plane and telemetry migration.
2. Phase 2 - Refactor Edge Function to load provider chain and fail over across adapters.
3. Phase 3 - Add provider adapters for OpenRouter, Gemini Image, and Pollinations.ai.
4. Phase 4 - Update documentation and verification checklist.

## Tasks
- [ ] Create `image_generation_configs`, `image_generation_user_overrides`, and `image_generation_attempt_logs` tables.
- [ ] Add provider metadata columns to `sticker_generations`.
- [ ] Enable RLS on internal failover tables without exposing client policies.
- [ ] Seed default OpenRouter, Gemini, and Pollinations configs.
- [ ] Refactor `generate-sticker` to call provider chain instead of hard-coded OpenRouter.
- [ ] Implement retryable error detection and fallback policy handling.
- [ ] Log every provider attempt with safe metadata only.
- [ ] Update README and `PROJECT_MEMORY.md`.
- [ ] Provide manual verification commands.

## Risks
- Gemini and Pollinations response schemas may change and need adapter tweaks.
- Pollinations may be unauthenticated/rate-limited, so it should be lowest priority by default.
- Storing API keys in Postgres requires strict RLS and service-role-only access.
- Longer failover chains increase Edge Function runtime.
- Existing preset contract test depends on the Supabase submodule being present.

## Notes
Client request and response shape remain unchanged. The Edge Function deducts credits once, attempts provider failover, and refunds only if all post-deduction generation attempts fail.
