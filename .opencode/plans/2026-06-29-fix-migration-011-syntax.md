# Migration 011 Syntax Fix Plan

Created: 2026-06-29

## Objective

Fix `supabase/migrations/20260629000011_subscription_and_expiration.sql` so `supabase db push` succeeds, harden the migration against Postgres transaction rules, and remove dead-code that misleads future readers. Provide exact `pg_cron` scheduling SQL as a follow-up operational step.

## Scope

- Fix three `PRIMARY KEY KEY` syntax errors in migration 011 (push blocker).
- Move four `ALTER TYPE ... ADD VALUE` statements into a separate migration so they run outside a transaction (push blocker on Supabase CLI default behavior).
- Drop the dead `EXCEPTION WHEN unique_violation` block from `complete_mission()` because the matching UNIQUE constraint is intentionally not present (single-completion is already enforced via `max_completions_per_user` count check for the two plus missions).
- Document the `pg_cron` enable + schedule SQL for `grant-monthly`, `expire-credits`, and `check-expired-plus`.
- No client-side (Flutter) code changes. No edge function changes. No RLS policy changes.

## Findings

| # | Line | Severity | Issue |
|---|---|---|---|
| F1 | 9 | Push blocker | `PRIMARY KEY KEY` typo on `user_subscriptions` |
| F2 | 73 | Push blocker | Same typo on `missions` |
| F3 | 102 | Push blocker | Same typo on `user_mission_progress` |
| F4 | 54-57 | Push blocker (env-dependent) | `ALTER TYPE ... ADD VALUE` cannot run inside a transaction block |
| F5 | 303-309 | Latent logic | `EXCEPTION WHEN unique_violation` references non-existent UNIQUE constraint; dead code |
| F7 | n/a | Operational | `pg_cron` schedule SQL documented below |

## Milestones

1. Phase 1 - Patch migration 011 in place (F1, F2, F3, F5).
2. Phase 2 - Create migration 012 for `transaction_type` enum extension (F4).
3. Phase 3 - Produce `pg_cron` schedule SQL doc block (F7).
4. Phase 4 - Verification commands.

## Tasks

- [x] F1-F3: In migration 011, replace `PRIMARY KEY KEY DEFAULT gen_random_uuid()` with `PRIMARY KEY DEFAULT gen_random_uuid()` on lines 9, 73, 102.
- [x] F5: Remove the `BEGIN ... EXCEPTION WHEN unique_violation ... END;` block from `complete_mission()`.
- [x] F5 (companion): Add comment explaining single-completion is enforced via count check.
- [x] F4: Create `supabase/migrations/20260629000012_transaction_type_mission_values.sql` with the four `ALTER TYPE` statements.
- [x] F4 (companion): Remove the four `ALTER TYPE` statements from migration 011.
- [x] F7: Provide schedule SQL (see below).

## pg_cron Schedule SQL

```sql
-- Enable pg_cron (run once in Supabase Dashboard -> Database -> Extensions)
-- Then run these in SQL editor:

SELECT cron.schedule(
    'grant-monthly-credits',
    '0 2 * * *',
    $$SELECT public.grant_monthly_credits();$$
);

SELECT cron.schedule(
    'expire-old-credits',
    '0 3 * * *',
    $$SELECT public.expire_old_credits();$$
);

SELECT cron.schedule(
    'check-expired-plus',
    '0 3 * * *',
    $$SELECT public.check_and_lock_expired_plus();$$
);
```

## Verification

```bash
# Sanity check no other migrations have the same typo
grep -nE "PRIMARY KEY KEY" supabase/migrations/

# Apply
supabase db push
# or clean reset locally
supabase db reset

# Post-deploy checks
psql "$DATABASE_URL" -c "\d+ user_subscriptions"
psql "$DATABASE_URL" -c "SELECT enumlabel FROM pg_enum WHERE enumtypid = 'transaction_type'::regtype ORDER BY enumsortorder;"
```

## Risks

- **R1**: Partial apply of old migration 011 on a live project. Mitigation: `supabase migration list` to confirm clean state.
- **R2**: If `supabase/config.toml` groups migrations into one transaction, the split is ineffective. Fallback: run the four `ALTER TYPE` statements manually via SQL editor.
- **R3**: Dropping `EXCEPTION WHEN unique_violation` removes a defensive layer. Mitigation: inline comment + `max_completions_per_user` is the canonical gate.

## Notes

- Migration 012 follows `YYYYMMDDHHMMSS_*.sql` pattern, day prefix `20260629`, suffix `00012`.
- `gen_random_uuid()` does not need `pgcrypto` on modern Supabase.
- `pg_cron` must be enabled via Dashboard (cannot be installed via migration).
- After execution, update `PROJECT_MEMORY.md` to add migration 012 entry.

## Proposed Commit Message

```
fix(db): correct PRIMARY KEY syntax and split transaction_type migration
```
