import 'package:flutter/material.dart';

import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../utils/area_stats.dart';
import '../utils/star_stats.dart';
import '../widgets/area_tag.dart';
import '../widgets/responsive_content.dart';
import 'area_projects_screen.dart';

/// The Sky hub: the 8 fixed life areas, each showing how many victories are
/// lit across all of its projects combined, plus how many open goals and
/// active habits sit alongside them. Tapping an area opens its project list
/// ([AreaProjectsScreen]).
class SkyScreen extends StatefulWidget {
  const SkyScreen({
    super.key,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
  });

  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen> {
  Future<void> _openArea(LifeArea area) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AreaProjectsScreen(
          area: area,
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.night,
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < LifeArea.values.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        Expanded(
                          child: _AreaCard(
                            area: LifeArea.values[i],
                            starCount: starsInArea(
                              LifeArea.values[i],
                              widget.projectRepository,
                              widget.starRepository,
                            ),
                            openGoals: openGoalsInArea(
                              LifeArea.values[i],
                              widget.projectRepository,
                              widget.starRepository,
                            ),
                            activeHabits: litHabitsInArea(
                              LifeArea.values[i],
                              widget.projectRepository,
                              widget.habitRepository,
                              widget.habitCompletionRepository,
                            ),
                            onTap: () => _openArea(LifeArea.values[i]),
                          ),
                        ),
                      ],
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.skyEyebrow,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: colors.goldDim,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.skyTitle,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.skySubtitle,
              style: TextStyle(fontSize: 14, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.starCount,
    required this.openGoals,
    required this.activeHabits,
    required this.onTap,
  });

  final LifeArea area;
  final int starCount;
  final int openGoals;
  final int activeHabits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final extras = <String>[
      if (openGoals > 0) strings.openGoalsBadge(openGoals),
      if (activeHabits > 0) strings.activeHabitsBadge(activeHabits),
    ];

    return Material(
      color: colors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AreaTag(area: area, iconSize: 20, fontSize: 16),
                    if (extras.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        extras.join(' · '),
                        style: TextStyle(fontSize: 12, color: colors.goldDim),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                strings.starsCount(starCount),
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
