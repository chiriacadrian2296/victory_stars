import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';

/// A calendar for the current month — one star per day (the app's own take
/// on a GitHub-style contribution graph). Weekday headers on top, up to 6
/// week rows below; days outside the current month are blank. The star
/// itself is always the same solid gold once lit — what actually varies
/// between days is a gold glow around it, scaled in both opacity and size
/// between the month's dimmest and brightest day by that day's total win
/// intensity (see [intensityByDay]), not by how many wins it has.
class StarHeatmap extends StatelessWidget {
  const StarHeatmap({
    super.key,
    required this.countsByDay,
    required this.intensityByDay,
    this.onDayTap,
  });

  final Map<DateTime, int> countsByDay;

  /// Each day's total win intensity (sum of that day's wins' 1-5 intensity
  /// values) — see [winIntensityByDay]. Drives the glow, independently of
  /// [countsByDay], which only drives the star's fill opacity.
  final Map<DateTime, int> intensityByDay;

  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstOfMonth = DateTime(todayDate.year, todayDate.month, 1);
    final daysInMonth = DateTime(todayDate.year, todayDate.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // The min/max that calibrate glow intensity, taken only from days that
    // actually have a star lit — an all-zero day never glows, so it
    // shouldn't pull the low end of the scale down further.
    final litIntensities = intensityByDay.values.where((v) => v > 0);
    final minIntensity = litIntensities.isEmpty ? 0 : litIntensities.reduce((a, b) => a < b ? a : b);
    final maxIntensity = litIntensities.isEmpty ? 0 : litIntensities.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.monthTitle(todayDate),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.text),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final label in strings.weekdayAbbreviations)
              Expanded(
                child: Center(
                  child: Text(label, style: TextStyle(fontSize: 11, color: colors.muted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Center(
                      child: _DayCell(
                        dayNumber: row * 7 + col - leadingBlanks + 1,
                        daysInMonth: daysInMonth,
                        month: todayDate,
                        today: todayDate,
                        countsByDay: countsByDay,
                        intensityByDay: intensityByDay,
                        minIntensity: minIntensity,
                        maxIntensity: maxIntensity,
                        onTap: onDayTap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.daysInMonth,
    required this.month,
    required this.today,
    required this.countsByDay,
    required this.intensityByDay,
    required this.minIntensity,
    required this.maxIntensity,
    this.onTap,
  });

  final int dayNumber;
  final int daysInMonth;
  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> countsByDay;
  final Map<DateTime, int> intensityByDay;
  final int minIntensity;
  final int maxIntensity;
  final void Function(DateTime day)? onTap;

  @override
  Widget build(BuildContext context) {
    const cellSize = 22.0;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(width: cellSize, height: cellSize);
    }

    final day = DateTime(month.year, month.month, dayNumber);
    if (day.isAfter(today)) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: Center(
          child: Text('$dayNumber', style: TextStyle(fontSize: 10, color: context.colors.muted.withValues(alpha: 0.4))),
        ),
      );
    }

    final count = countsByDay[day] ?? 0;
    final colors = context.colors;
    final isLit = count > 0;

    final dayIntensity = intensityByDay[day] ?? 0;
    var glowStrength = 0.0;
    if (dayIntensity > 0) {
      // Even the month's dimmest lit day still gets a faint trace of glow
      // instead of fading to nothing — only an unlit day (no stars at all)
      // gets none. Kept close to 0 (rather than a more noticeable floor) so
      // there's more visible range between the dimmest and brightest days.
      const glowFloor = 0.03;
      final normalized = maxIntensity == minIntensity
          ? 1.0
          : (dayIntensity - minIntensity) / (maxIntensity - minIntensity);
      glowStrength = glowFloor + (1 - glowFloor) * normalized;
    }

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(day),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: dayIntensity <= 0
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.gold.withValues(alpha: 0.1 + 0.65 * glowStrength),
                    blurRadius: 1 + 25 * glowStrength,
                    spreadRadius: 4 * glowStrength,
                  ),
                ],
              ),
        // The star itself is always the same solid gold, lit or not —
        // only the glow (above) carries how many/how intense that day's
        // wins were. It used to also fade the star's own opacity down for
        // low counts, which just made a light day look like a rendering
        // glitch rather than a deliberate "less glow" day.
        child: Icon(
          isLit ? Icons.star : Icons.star_border,
          size: cellSize,
          color: isLit ? colors.gold : colors.gold.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}
