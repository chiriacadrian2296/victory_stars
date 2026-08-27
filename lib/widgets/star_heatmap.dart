import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A GitHub-contribution-graph-style calendar, using the app's own "lit
/// star" language instead of colored squares: one star per day, brighter
/// the more wins were logged that day. Weeks run in columns (Monday first),
/// oldest on the left, today on the right — scrolls horizontally, starting
/// scrolled to the most recent week.
class StarHeatmap extends StatelessWidget {
  const StarHeatmap({super.key, required this.countsByDay, this.weeks = 26, this.onDayTap});

  final Map<DateTime, int> countsByDay;
  final int weeks;
  final void Function(DateTime day)? onDayTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final daysSinceMonday = todayDate.weekday - DateTime.monday;
    final currentWeekStart = todayDate.subtract(Duration(days: daysSinceMonday));
    final gridStart = currentWeekStart.subtract(Duration(days: 7 * (weeks - 1)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = 0; w < weeks; w++)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    _DayCell(
                      day: gridStart.add(Duration(days: 7 * w + d)),
                      today: todayDate,
                      countsByDay: countsByDay,
                      onTap: onDayTap,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.today, required this.countsByDay, this.onTap});

  final DateTime day;
  final DateTime today;
  final Map<DateTime, int> countsByDay;
  final void Function(DateTime day)? onTap;

  @override
  Widget build(BuildContext context) {
    const cellSize = 16.0;
    if (day.isAfter(today)) {
      return const SizedBox(width: cellSize, height: cellSize + 5);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: GestureDetector(
        onTap: onTap == null ? null : () => onTap!(day),
        child: Icon(
          count == 0 ? Icons.star_border : Icons.star,
          size: cellSize,
          color: colors.gold.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
