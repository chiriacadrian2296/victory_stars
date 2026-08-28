import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../utils/win_stats.dart';
import '../widgets/area_tag.dart';

/// The dashboard's three stat cards (Total Stars, Current Streak, Longest
/// Streak) each open one of these — a closer look, in the same reflective,
/// gradient-background style as [WinReaderScreen] and [EncouragementScreen],
/// but built around one big number and a card of supporting facts rather
/// than a browsable win or a quote.
class TotalStarsDetailScreen extends StatelessWidget {
  const TotalStarsDetailScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final wins = winRepository.getAll();

    if (wins.isEmpty) {
      return _StatDetailScaffold(
        icon: Icons.star,
        value: '0',
        caption: strings.totalStarsLabel,
        body: _EmptyBody(text: strings.archiveEmpty),
      );
    }

    final byDateAscending = [...wins]..sort((a, b) => a.date.compareTo(b.date));
    final combinedIntensity = wins.fold<int>(0, (sum, w) => sum + w.intensity);

    final projectsById = {for (final project in projectRepository.getAll()) project.id: project};
    final countByArea = <LifeArea, int>{};
    for (final win in wins) {
      final area = projectsById[win.projectId]?.area;
      if (area == null) continue;
      countByArea[area] = (countByArea[area] ?? 0) + 1;
    }
    final areasByCount = countByArea.keys.toList()..sort((a, b) => countByArea[b]!.compareTo(countByArea[a]!));

    return _StatDetailScaffold(
      icon: Icons.star,
      value: '${wins.length}',
      caption: strings.totalStarsLabel,
      body: Column(
        children: [
          _DetailCard(
            children: [
              _DetailRow(label: strings.firstStarLabel, value: formatDisplayDate(byDateAscending.first.date, strings)),
              _DetailRow(label: strings.mostRecentStarLabel, value: formatDisplayDate(byDateAscending.last.date, strings)),
              _DetailRow(label: strings.combinedIntensityLabel, value: '$combinedIntensity', isLast: true),
            ],
          ),
          if (areasByCount.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.starsByAreaLabel,
                style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: colors.crisisMuted),
              ),
            ),
            const SizedBox(height: 10),
            _DetailCard(
              divideRows: true,
              children: [
                for (var i = 0; i < areasByCount.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: AreaTag(area: areasByCount[i], iconSize: 16, fontSize: 14, textColor: colors.text)),
                        Text(strings.starsCount(countByArea[areasByCount[i]]!), style: TextStyle(fontSize: 13, color: colors.crisisMuted)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CurrentStreakDetailScreen extends StatelessWidget {
  const CurrentStreakDetailScreen({super.key, required this.winRepository});

  final WinRepository winRepository;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final wins = winRepository.getAll();
    final dayCounts = winCountsByDay(wins);
    final range = currentStreakRange(dayCounts);

    if (dayCounts.isEmpty) {
      return _StatDetailScaffold(
        icon: Icons.local_fire_department,
        value: '0',
        caption: strings.currentStreakLabel,
        body: _EmptyBody(text: strings.archiveEmpty),
      );
    }
    if (range.length == 0) {
      return _StatDetailScaffold(
        icon: Icons.local_fire_department,
        value: '0',
        caption: strings.currentStreakLabel,
        body: _EmptyBody(text: strings.noCurrentStreakBody),
      );
    }

    return _StatDetailScaffold(
      icon: Icons.local_fire_department,
      value: '${range.length}',
      caption: strings.currentStreakLabel,
      body: _DetailCard(
        children: [
          _DetailRow(label: strings.streakFromLabel, value: formatDisplayDate(range.start!, strings)),
          _DetailRow(label: strings.streakToLabel, value: strings.todayLabel),
          _DetailRow(
            label: strings.starsLoggedLabel,
            value: '${_starsWithinRange(wins, range)}',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class LongestStreakDetailScreen extends StatelessWidget {
  const LongestStreakDetailScreen({super.key, required this.winRepository});

  final WinRepository winRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final wins = winRepository.getAll();
    final dayCounts = winCountsByDay(wins);
    final range = longestStreakRange(dayCounts);

    if (range.length == 0) {
      return _StatDetailScaffold(
        icon: Icons.emoji_events,
        value: '0',
        caption: strings.longestStreakLabel,
        body: _EmptyBody(text: strings.archiveEmpty),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stillGoing = range.end == today;

    return _StatDetailScaffold(
      icon: Icons.emoji_events,
      value: '${range.length}',
      caption: strings.longestStreakLabel,
      body: _DetailCard(
        children: [
          _DetailRow(label: strings.streakFromLabel, value: formatDisplayDate(range.start!, strings)),
          _DetailRow(
            label: strings.streakToLabel,
            value: stillGoing ? strings.todayLabel : formatDisplayDate(range.end!, strings),
          ),
          _DetailRow(label: strings.starsLoggedLabel, value: '${_starsWithinRange(wins, range)}', isLast: !stillGoing),
          if (stillGoing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: colors.gold),
                  const SizedBox(width: 8),
                  Text(
                    strings.streakStillGoingLabel,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.gold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// How many wins fall within [range]'s inclusive day span — the streak's
/// length in days, unlike this, can be lower than the win count on days
/// where more than one star was lit.
int _starsWithinRange(List<Win> wins, StreakRange range) {
  final start = range.start!;
  final end = range.end!;
  return wins.where((w) {
    final day = DateTime(w.date.year, w.date.month, w.date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }).length;
}

class _StatDetailScaffold extends StatelessWidget {
  const _StatDetailScaffold({
    required this.icon,
    required this.value,
    required this.caption,
    required this.body,
  });

  final IconData icon;
  final String value;
  final String caption;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back, color: colors.crisisMuted),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.gold.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(color: colors.gold.withValues(alpha: 0.4), blurRadius: 28),
                          ],
                        ),
                        child: Icon(icon, size: 38, color: colors.gold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        value,
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, height: 1, color: colors.text),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        caption.toUpperCase(),
                        style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600, color: colors.goldDim),
                      ),
                      const SizedBox(height: 28),
                      body,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children, this.divideRows = false});

  final List<Widget> children;

  /// Whether to draw a divider between rows — the label/value rows built
  /// from [_DetailRow] draw their own bottom border instead (so the last row
  /// can skip it via [_DetailRow.isLast]), but the by-area list has no such
  /// per-row control, so it opts into dividers here instead.
  final bool divideRows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: colors.crisisMuted.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: divideRows
            ? [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(color: colors.crisisMuted.withValues(alpha: 0.12), height: 1),
                  children[i],
                ],
              ]
            : children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.crisisMuted.withValues(alpha: 0.12))),
            ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: colors.crisisMuted))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.text)),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, height: 1.5, color: context.colors.crisisMuted),
    );
  }
}
