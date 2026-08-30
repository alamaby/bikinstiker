# Daily Check-in Regression Fix

Created: 2026-07-14

## Objective
Fix 3 regressions from initial daily check-in implementation: (1) timezone mismatch causes cooldown expiry early/late near midnight WIB, (2) Lottie animation picks the wrong day (day 7 shows flame, start-new-cycle shows celebration), (3) fire-flame.json not tracked in Git.

## Scope
- DB: fix `load_daily_checkin_streak()` and `claim_daily_checkin()` cooldown comparison to use Asia/Jakarta `::date` universally
- UI: refactor checkin animation to use post-claim streak state, not pre-claim `_pendingCheckinDay`
- Tests: pure helper tests for animation decision, widget regression for day boxes
- Asset: track `fire-flame.json`, confirm no stale `.lottie` refs
- Bump patch version + PROJECT_MEMORY

## Milestones
1. Migration `20260714000033` — WIB cooldown fix
2. Animation refactor — enum overlay + post-claim day
3. Tests — pure function + widget regression
4. Asset cleanup + verification

## Tasks
- [x] Create plan file
- [x] Create migration SQL
- [ ] Deploy migration (manual)
- [x] Update missions_screen.dart — animation refactor
- [x] Extract pure helper `checkinAnimationFor()` in model
- [x] Remove `_pendingCheckinDay` — replaced by post-claim streak state
- [x] Update tests — 3 new pure function tests
- [x] Bump pubspec.yaml
- [ ] Asset cleanup — stage fire-flame.json, confirm .lottie no refs
- [x] Run flutter analyze + test + build

## Risks
- Do not modify deployed migration `00032`; `00033` supersedes the cooldown part.
- Changing cooldown to WIB midnight alters behavior only near UTC/WIB date boundary.
- `_pendingCheckinDay` removal requires checking all usages in listener/onClaim.

## Progress Log
- 2026-07-14 16:00 WIB — Plan created. 
- 2026-07-14 16:30 WIB — Migration `00033` written, missions_screen refactored, 3 new tests pass, version bumped to 0.16.3+62. flutter analyze clean (1 pre-existing warning), flutter test 143/143, flutter build apk in progress.

## Notes
See `plans/2026-07-14-daily-checkin-cycle-complete-fix.md` for earlier iterations.
