# Daily Check-in Streak + Recurring Mission Fix

Created: 2026-07-02 15:00:00

## Objective
Implement a 7-day daily check-in streak system with credit rewards, fix the recurring mission `OR TRUE` bug, and reorganize the Missions screen into logical sections.

## Scope
- DB: `daily_checkin_streaks` table + `claim_daily_checkin` + `load_daily_checkin_streak` RPCs
- DB: Fix `OR TRUE` bug in `complete_mission` RPC, add `share_app_daily` cooldown
- Flutter: Streak model, repository methods, BLoC event/handler/state
- Flutter: DailyCheckinCard widget with 7-day box display
- Flutter: MissionsScreen section grouping (Daily → Quick → Achievements)
- Snackbar feedback for check-in success

## Milestones
1. Database migrations (recurring fix + streak schema)
2. Flutter model + repository layer
3. BLoC integration (streak event, state, handler)
4. UI widgets (DailyCheckinCard, MissionSectionHeader)
5. MissionsScreen section reorganization

## Tasks
- [x] Create `20260702000013_fix_recurring_mission_limit.sql`
- [x] Create `20260702000014_daily_checkin_streak.sql`
- [x] Create `lib/data/models/daily_checkin_streak.dart`
- [x] Update `lib/data/repositories/mission_repository.dart`
- [x] Update `lib/presentation/blocs/mission/mission_bloc.dart`
- [x] Create `lib/presentation/screens/missions/widgets/daily_checkin_card.dart`
- [x] Create `lib/presentation/screens/missions/widgets/mission_section_header.dart`
- [x] Rewrite `lib/presentation/screens/missions/missions_screen.dart`
- [x] Update `PROJECT_MEMORY.md` and `TODO.md`
- [x] Format all changed files

## Design Decisions

### Streak Rules
- **7-day cycle**: days 1-6 = 1 credit each; day 7 = 4 credits (total 10/week)
- **Consecutive day**: last_checked_on = yesterday → continue streak
- **Gap > 1 day**: reset to day 1
- **Cycle completion**: `cycle_completed_at` set on day 7
- **New cycle start**: 24h after `cycle_completed_at` (date arithmetic, not timestamp)
- **Already checked in**: blocked with "Already checked in today"
- **Cycle cooldown**: "Wait one day before starting new cycle"

### Section Grouping
- **Daily Rewards**: `daily_login` mission with streak card
- **Quick Rewards**: recurring missions with cooldown/daily limit (watch_video_ad, share_app_daily)
- **Achievements**: one-time missions (first_sticker, try_all_presets, etc.)

### UI Design
- 7 day boxes per row, each with themed emoji + numeric day number
- Animated border/color transitions for completed, today, locked states
- Cycle completion indicator replaces claim button
- Snackbar: themed with emoji, +credits badge, 5s duration

## Verification

### SQL smoke test
```sql
-- After migration 013: recurring missions allow unlimited completions
-- watch_video_ad (max_completions_per_user = NULL) should pass the check
SELECT * FROM missions WHERE code = 'watch_video_ad';
-- cooldown_seconds should be 3600

-- After migration 014: streak system
SELECT * FROM daily_checkin_streaks WHERE user_id = '2b9783ab-...';
-- Should return empty or existing streak row

-- Load streak
SELECT * FROM load_daily_checkin_streak();
-- Returns: current_streak, current_cycle_day, last_checked_on, cycle_completed_at, checked_in_today

-- Claim check-in
SELECT * FROM claim_daily_checkin(1, 4);
-- Returns: credits_awarded=1, new_streak=1, new_cycle_day=1, cycle_completed=false, total_weekly=7

-- Second claim same day → ERROR 'Already checked in today'
-- Claim next day → continues streak
-- Day 7 → credits_awarded=4, cycle_completed=true
-- Day after day 7 → ERROR 'Wait one day before starting new cycle'
```

### Flutter
```bash
flutter analyze
flutter test
```

## Proposed Commit Message
`feat(missions): add 7-day daily check-in streak and fix recurring mission limit`
