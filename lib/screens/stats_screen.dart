import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_style.dart';
import '../utils/star_stats.dart';
import '../widgets/responsive_content.dart';
import 'stat_detail_screen.dart';

/// The Statistics tab: total stars and the current/longest streak, each
/// opening its own closer-look detail screen. Split out of Home (which used
/// to end with these cards) so the dashboard stays focused on "today" and
/// the activity calendar, with the cumulative numbers living in their own
/// place instead of competing for space on the same screen.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.starRepository,
    required this.projectRepository,
  });

  final StarRepository starRepository;
  final ProjectRepository projectRepository;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  void _openTotalStarsDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TotalStarsDetailScreen(
          starRepository: widget.starRepository,
          projectRepository: widget.projectRepository,
        ),
      ),
    );
  }

  void _openCurrentStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CurrentStreakDetailScreen(starRepository: widget.starRepository),
      ),
    );
  }

  void _openLongestStreakDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LongestStreakDetailScreen(starRepository: widget.starRepository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final achievedStars = widget.starRepository
        .getAll()
        .where((s) => s.isLit)
        .toList();
    final dayCounts = starCountsByDay(achievedStars);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          // The scrollable itself spans the full window width (so its
          // auto-attached Scrollbar sits at the true page edge on wide
          // viewports); only its content is capped/centered.
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.statsEyebrow,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: colors.goldDim,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.statsTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.totalStarsLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TotalStarsBanner(
                    value: achievedStars.length,
                    onTap: _openTotalStarsDetail,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.streaksSectionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: strings.currentStreakLabel,
                          value: '${currentStreak(dayCounts)}',
                          onTap: _openCurrentStreakDetail,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: strings.longestStreakLabel,
                          value: '${longestStreak(dayCounts)}',
                          onTap: _openLongestStreakDetail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(kRadiusCard);
    return Material(
      color: colors.nightPanel,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: borderRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ],
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.info_outline, size: 14, color: colors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wider, more eye-catching presentation for the total-star count — its
/// own row above the streak cards, rather than squeezed into an equal-width
/// slot alongside them, since it's the headline number on this tab.
class _TotalStarsBanner extends StatelessWidget {
  const _TotalStarsBanner({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(kRadiusCard);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.gold.withValues(alpha: 0.22),
                colors.gold.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: colors.gold.withValues(alpha: 0.45)),
            borderRadius: borderRadius,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 24, color: colors.gold),
                    const SizedBox(height: 6),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.info_outline, size: 16, color: colors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
