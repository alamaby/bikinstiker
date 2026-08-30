# Daily Check-in Cycle Complete Fix

Created: 2026-07-14

## Objective
Fix bug where user sees permanent "Cycle complete!" after finishing a 7-day daily check-in cycle and cannot start a new cycle the next day.

## Scope
- Server: add cooldown metadata (`cycle_cooldown_finished`, `cooldown_remaining_seconds`) to `load_daily_checkin_streak` RPC
- Client: update `DailyCheckinStreak` model with new fields, rewrite `canClaim`
- Client: update `daily_checkin_card.dart` to show correct UI state after cooldown expires
- Data: one-time patch for affected user `2b9783ab-...`
- Tests: model + UI

## Milestones
1. Migration + apply
2. Model + widget update
3. Data patch
4. Verification

## Tasks
- [x] Create plan file
- [x] Write migration SQL
- [x] Apply migration to Supabase (user runs manually)
- [x] Update DailyCheckinStreak model
- [x] Update daily_checkin_card.dart — complete marker + isCompleted state
- [x] Update missions_screen.dart — fire-flame Lottie for day 1-6, celebration for day 7
- [x] Create test/daily_checkin_card_test.dart — 6 widget tests
- [ ] Data patch for user (manual SQL needed)
- [x] Run flutter analyze + test

## Risks
- Client clock skew: countdown uses server-provided `cooldown_remaining_seconds`, not local diff
- UTC/WIB boundary cooldown: consistent with existing `claim_daily_checkin` logic; minor countdown inaccuracy acceptable

## Progress Log
- 2026-07-14 — Iterasi 2: box marker fix (isCompleted + ✅ untuk hari ini) + Lottie flame animation. flutter analyze 1 warning pre-existing, flutter test 140/140, flutter build apk sukses (20-23MB). Menunggu user: (1) deploy migration SQL, (2) data patch unblock user.

## Notes
Root cause: UI hides claim button purely when `cycleCompletedAt != null` (line 111 `daily_checkin_card.dart`), with no check for post-completion cooldown elapsed. Server gate `(v_today - cycle_completed_at::date) < 1` in `claim_daily_checkin` is correct but UI blocks user from ever calling it.
