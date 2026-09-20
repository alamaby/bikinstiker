# Surprise-Me Wide-Eyed Dominance Fix — Implementation

Date: 2026-09-20
Status: Implementation complete, deploy pending review

## Task
Implement `plans/2026-09-20-surprise-me-wide-eyed-fix-plan.md` to reduce `wide-eyed` dominance in surprise-me LLM output from ~90% to <30%.

## Files Changed
- `supabase/functions/surprise-me/index.ts` (+89/-8) — 5-milestone fix applied
- `supabase/functions/surprise-me/index_test.ts` (+108) — 9 new tests added

## What Was Done
1. **EXPRESSIONS bank** (20 items, ≤40 chars, no banned phrases) + `pickExpression()` exported helper.
2. **Guidance hardening** — `GuidanceOptions.expression` field; `buildSurpriseGuidance` injects explicit expression requirement + wide-eyed prohibition when provided.
3. **Per-attempt re-pick** — `buildAttemptGuidance()` rebuilt each attempt so retry uses a different expression.
4. **Overuse guard** — `isWideEyedOverused(candidate, avoidList)` exported; throws `ProviderError(422, "expression_overused")` when candidate contains wide-eyed AND history already has ≥2 wide-eyed hits. Safe: `shouldAlertProviderIssue` only alerts on 5xx/timeout, so 422 silent-retry only.
5. **Temperature clone override** — `cfgForSurprise = { ...cfg, request_options: { ...(cfg.request_options ?? {}), temperature: 0.9 } }` passed to `callReasoningProvider`. Original `cfg` unmutated. `generate-sticker/index.ts` untouched.
6. **Unit tests** (9 new): expression injection, expression null-safety, overuse guard truth table, EXPRESSIONS pool integrity, temperature-clone contract, per-attempt rebuild contract, export check.

## Test Results
- `deno test --allow-read --allow-net --allow-env index_test.ts`: **24/24 passed** (was 15)
- `deno test` in `generate-sticker`: **134/134 passed** (no regression)

## Verification Pending (read-only, requires deploy)
- MCP query `SELECT prompt_text FROM surprise_me_history ORDER BY created_at DESC LIMIT 20` to measure post-deploy wide-eyed ratio. Target: ≤6/20 (<30%).

## Rollback
Delete blocks: `EXPRESSIONS`, `pickExpression`, `WIDE_EYED_RE`+`isWideEyedOverused`, `cfgForSurprise`, per-attempt `buildAttemptGuidance`. Restore single `guidance` variable. One revert commit.

## Commit Proposal
`fix(surprise-me): diversify expressions and guard wide-eyed overuse`
