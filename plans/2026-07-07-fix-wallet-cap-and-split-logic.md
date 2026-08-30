# Fix Wallet Balance Cap and Split Row Accounting

Created: 2026-07-07 10:00:00

## Objective
Fix two issues:
1. Ensure `user_wallets.balance` never exceeds `tier_cap` by adding a constraint/trigger.
2. Ensure `split_row` (partial consumption) transactions are correctly excluded from balance accumulation calculations or properly capped.

## Scope
- Create migration to enforce `balance <= tier_cap`.
- Audit RPC functions to ensure they respect the cap during updates.

## Milestones
1. Migration for `user_wallets` constraint.
2. Fix `deduct_credit_for_sticker` and other credit-granting RPCs.

## Tasks
- [ ] Create migration `20260707000015_enforce_wallet_cap.sql`
- [ ] Add `CHECK (balance <= tier_cap)` or trigger
- [ ] Update `deduct_credit_for_sticker` to prevent `split_row` from inflating balance.

## Risks
- Existing users with balance > cap (need cleanup migration).

## Notes
- Need to check if `credit_transactions` needs a discriminator for "actual grants" vs "ledger movements".
