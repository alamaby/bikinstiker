# Daily Check-in Streak: Phase 6 — Lottie Animations

Created: 2026-07-07 09:00:00

## Objective
Replace static emoji fallbacks in the 7-day streak boxes with animated Lottie assets, and add a small Lottie flame animation for the streak counter badge.

## Scope
- Download 8 Lottie JSON files (7 day themes + 1 flame) from LottieFiles free tier
- Register all new assets in `pubspec.yaml`
- Rewrite `_DayBox` widget in `daily_checkin_card.dart` to use `Lottie.asset` instead of `Text(marker.themed)`
- Add flame Lottie to streak badge
- Clean up the now-unused `_dayMarkers` themed emoji tuples

## Prerequisites
- `lottie: ^3.1.2` already in `pubspec.yaml` (line 30) — no new dependency needed
- Celebration overlay Lottie (`assets/animations/celebration.json`) already in use — patterns established

## Tasks

### 1. Download Lottie Assets
Download free Lottie JSON animations from LottieFiles (or similar) and save to `assets/animations/`:

| File | Theme | Suggested LottieFiles Search |
|------|-------|------------------------------|
| `day1_sunrise.json` | Sunrise | "sunrise animation" |
| `day2_sun.json` | Sun | "sun spinning" |
| `day3_art.json` | Art palette | "art palette" or "painting" |
| `day4_star.json` | Star | "star twinkle" |
| `day5_diamond.json` | Diamond | "diamond sparkle" |
| `day6_gift.json` | Gift box | "gift box bounce" |
| `day7_trophy.json` | Trophy | "trophy celebration" |
| `streak_fire.json` | Fire/flame | "fire flame" |

**Criteria per file:**
- Max size: ~15 KB (small for 36×36px rendering)
- Loopable (seamless or near-seamless)
- Licence: Free for commercial use (Lottiefiles free / MIT / CC-BY)
- Aspect ratio: 1:1 square preferred

### 2. Register Assets in `pubspec.yaml`
Add to the existing `assets:` block under `assets/animations/`:
```yaml
  - assets/animations/day1_sunrise.json
  - assets/animations/day2_sun.json
  - assets/animations/day3_art.json
  - assets/animations/day4_star.json
  - assets/animations/day5_diamond.json
  - assets/animations/day6_gift.json
  - assets/animations/day7_trophy.json
  - assets/animations/streak_fire.json
```

### 3. Create Asset Constants File
Create `lib/core/constants/streak_animations.dart`:

```dart
/// Paths to Lottie animations used in daily check-in streak.
class StreakAnimations {
  StreakAnimations._();

  static const String sunrise = 'assets/animations/day1_sunrise.json';
  static const String sun = 'assets/animations/day2_sun.json';
  static const String art = 'assets/animations/day3_art.json';
  static const String star = 'assets/animations/day4_star.json';
  static const String diamond = 'assets/animations/day5_diamond.json';
  static const String gift = 'assets/animations/day6_gift.json';
  static const String trophy = 'assets/animations/day7_trophy.json';
  static const String streakFire = 'assets/animations/streak_fire.json';

  /// Returns animation path for the given day (1-indexed).
  static String forDay(int day) {
    return [
      sunrise, sun, art, star,
      diamond, gift, trophy,
    ][day - 1];
  }

  /// All day animation paths.
  static List<String> get allDays => [
    sunrise, sun, art, star,
    diamond, gift, trophy,
  ];
}
```

### 4. Update `_DayBox` Widget in `daily_checkin_card.dart`

**Changes in `_DayBox.build`:**
- Import `package:lottie/lottie.dart`
- Replace `Text(marker.themed, style: ...)` with:
  ```dart
  Lottie.asset(
    StreakAnimations.forDay(widget.dayNumber),
    width: 28,
    height: 28,
    fit: BoxFit.contain,
    repeat: true,
    animate: !locked, // locked days: static (frame 0)
  )
  ```
- Locked state: use `animate: false` so it renders as a static thumbnail (no CPU waste)
- Completed/today: loop idle animation
- On `highlightBounce` (just claimed): trigger a one-shot play with `repeat: false` via a controller, then transition to `repeat: true` after the bounce animation completes

**Detailed `_DayBox` Lottie controller logic:**
```dart
class _DayBoxState extends State<_DayBox> with SingleTickerProviderStateMixin {
  late final LottieController _controller;
  bool _scaled = false;
  bool _claimedOnce = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlightBounce) {
      _triggerBounce();
      _claimedOnce = true;
    }
  }

  // ... didUpdateWidget for highlightBounce changes ...

  @override
  Widget build(BuildContext context) {
    // ... existing completed/isToday/wasCheckedToday/locked logic ...

    return Expanded(
      child: AnimatedScale(
        scale: _scaled ? 1.18 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          // ... existing container decoration ...
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                StreakAnimations.forDay(widget.dayNumber),
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                repeat: !locked && !_claimedOnce ? false : !locked,
                animate: !locked,
                controller: _controller,
                onLoaded: (composition) {
                  if (_claimedOnce) {
                    _controller..forward(from: 0);
                  }
                },
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.dayNumber}',
                // ... existing style ...
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 5. Update Streak Badge
Replace `Text('🔥 ${s.currentStreak}')` with a small `Lottie.asset` + text combo:
```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    SizedBox(
      width: 18,
      height: 18,
      child: Lottie.asset(
        StreakAnimations.streakFire,
        width: 18,
        height: 18,
        repeat: true,
      ),
    ),
    const SizedBox(width: 4),
    Text(
      '${s.currentStreak}',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
    ),
  ],
)
```

### 6. Remove Unused `_dayMarkers` Constant
After verification, delete the `_dayMarkers` tuple list (lines 9-17 of `daily_checkin_card.dart`) since emoji are no longer needed.

### 7. Format & Verify
```bash
dart format lib/core/constants/streak_animations.dart lib/presentation/screens/missions/widgets/daily_checkin_card.dart
flutter analyze
```

## Design Decisions

- **Small size (28×28px)** — keeps the animation subtle; day boxes are ~40dp wide
- **Locked = static thumbnail** — `animate: false` renders frame 0 to avoid wasted GPU cycles for future days
- **One-shot on claim** — when a box is just claimed, play the Lottie once (`repeat: false`, `forward(from: 0)`) concurrently with the existing `AnimatedScale` bounce, then transition to looping
- **No state management change** — the `justClaimedDay` prop already exists and triggers `highlightBounce`; the Lottie one-shot piggybacks on the same mechanism
- **No loading skeleton** — Lottie JSON < 15 KB, synchronous load from local asset bundle; negligible latency

## Risks

| Risk | Mitigation |
|------|------------|
| LottieFiles asset removed/changed licence | Download & vendor into repo; check licence before commit |
| 7 extra Lottie instances on screen (14 frames) render jank | Use `repeat: true` + `animate: false` for locked; Flutter Impeller handles small Lotties efficiently; test on low-end Android |
| Bounce animation timing conflicts with Lottie one-shot | Bounce (220ms easeOutBack) completes before Lottie one-shot (~600ms); stack naturally |
| Streak badge (🔥) replaced: visual mismatch with existing design | Keep original 🔥 as `errorBuilder` / `placeholder` fallback if Lottie fails to load |

## Verification
- **Visual**: Daily check-in card shows animated day icons (idle loop for completed/today, static for locked, one-shot burst on claim)
- **Streak badge**: Animated fire icon next to streak count
- **Regression**: Check-in flow still works (tap → Lottie overlay + bounce + day animation)
- **Performance**: No dropped frames on 60fps profile; inspect with Flutter DevTools
- **Lint**: `flutter analyze` passes

## Proposed Commit Message
`feat(missions): replace streak day emoji with Lottie animations`
