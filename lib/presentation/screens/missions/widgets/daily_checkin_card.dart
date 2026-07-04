import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/daily_checkin_streak.dart';
import '../../../../data/models/mission.dart';

const _dayMarkers = [
  (themed: '\u{1F305}', numeric: '\u{1F51F}'), // Day 1: sunrise + 1
  (themed: '\u{2600}\u{FE0F}', numeric: '\u{1F51F}'), // Day 2: sun + 2
  (themed: '\u{1F3A8}', numeric: '\u{1F51F}'), // Day 3: art + 3
  (themed: '\u{2B50}', numeric: '\u{1F51F}'), // Day 4: star + 4
  (themed: '\u{1F48E}', numeric: '\u{1F51F}'), // Day 5: diamond + 5
  (themed: '\u{1F381}', numeric: '\u{1F51F}'), // Day 6: gift + 6
  (themed: '\u{1F3C6}', numeric: '\u{1F51F}'), // Day 7: trophy + 7
];

class DailyCheckinCard extends StatelessWidget {
  final Mission mission;
  final DailyCheckinStreak? streak;
  final int? justClaimedDay;
  final VoidCallback? onClaim;

  const DailyCheckinCard({
    super.key,
    required this.mission,
    this.streak,
    this.justClaimedDay,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final s = streak ?? DailyCheckinStreak.empty();
    final canClaim = s.canClaim;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mission.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (s.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔥 ${s.currentStreak}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              mission.description,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            // Day boxes row
            Row(
              children: List.generate(7, (i) {
                final day = i + 1;
                return _DayBox(
                  dayNumber: day,
                  currentCycleDay: s.currentCycleDay,
                  cycleCompleted: s.cycleCompleted,
                  checkedInToday: s.checkedInToday,
                  highlightBounce: justClaimedDay == day,
                );
              }),
            ),
            const SizedBox(height: 12),
            // Claim button
            Row(
              children: [
                Icon(Icons.bolt, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '+${mission.rewardCredits} credit${mission.rewardCredits == 1 ? '' : 's'}/day',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (s.cycleCompleted)
                  const Text(
                    'Cycle complete!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (!canClaim)
                  const Text(
                    'Checked in',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  FilledButton(
                    onPressed: onClaim,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'Check-in',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBox extends StatefulWidget {
  final int dayNumber;
  final int currentCycleDay;
  final bool cycleCompleted;
  final bool checkedInToday;
  final bool highlightBounce;

  const _DayBox({
    required this.dayNumber,
    required this.currentCycleDay,
    required this.cycleCompleted,
    required this.checkedInToday,
    required this.highlightBounce,
  });

  @override
  State<_DayBox> createState() => _DayBoxState();
}

class _DayBoxState extends State<_DayBox> {
  Timer? _timer;
  bool _scaled = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlightBounce) _triggerBounce();
  }

  @override
  void didUpdateWidget(covariant _DayBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.highlightBounce && widget.highlightBounce) {
      _triggerBounce();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _triggerBounce() {
    _timer?.cancel();
    setState(() => _scaled = true);
    _timer = Timer(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _scaled = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        !widget.cycleCompleted && widget.dayNumber < widget.currentCycleDay;
    final isToday =
        !widget.cycleCompleted &&
        widget.dayNumber == widget.currentCycleDay &&
        !widget.checkedInToday;
    final wasCheckedToday =
        !widget.cycleCompleted &&
        widget.dayNumber == widget.currentCycleDay &&
        widget.checkedInToday;
    final locked =
        widget.cycleCompleted ||
        (widget.dayNumber > widget.currentCycleDay && !wasCheckedToday);

    final marker = _dayMarkers[widget.dayNumber - 1];

    return Expanded(
      child: AnimatedScale(
        scale: _scaled ? 1.18 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: completed
                ? AppColors.success.withValues(alpha: 0.18)
                : (isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface),
            border: Border.all(
              color: isToday
                  ? AppColors.primary
                  : (completed ? AppColors.success : AppColors.outline),
              width: isToday ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(marker.themed, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                '${widget.dayNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: locked
                      ? AppColors.outline
                      : (completed ? AppColors.success : AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
