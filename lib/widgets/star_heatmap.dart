import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';

/// A calendar for the current month — one star per day, brighter the more
/// wins were logged that day (the app's own take on a GitHub-style
/// contribution graph). Weekday headers on top, up to 6 week rows below;
/// days outside the current month are blank.
class StarHeatmap extends StatelessWidget {
  const StarHeatmap({super.key, required this.countsByDay, this.onDayTap});

  final Map<DateTime, int> countsByDay;
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
    this.onTap,
  });

  final int dayNumber;
  final int daysInMonth;
  final DateTime month;
  final DateTime today;
  final Map<DateTime, int> countsByDay;
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
    final alpha = switch (count) {
      0 => 0.16,
      1 => 0.4,
      2 || 3 => 0.65,
      4 || 5 || 6 => 0.85,
      _ => 1.0,
    };

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(day),
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: Icon(
          count == 0 ? Icons.star_border : Icons.star,
          size: cellSize,
          color: colors.gold.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
