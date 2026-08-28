import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../utils/win_stats.dart';
import '../widgets/area_tag.dart';
import 'area_projects_screen.dart';

/// The Sky hub: the 8 fixed life areas, each showing how many stars are lit
/// across all of its projects combined. Tapping an area opens its project
/// list ([AreaProjectsScreen]) — an area itself has no single constellation
/// once it can hold more than one project.
class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key, required this.projectRepository, required this.winRepository});

  final ProjectRepository projectRepository;
  final WinRepository winRepository;

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
          winRepository: widget.winRepository,
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
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: LifeArea.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final area = LifeArea.values[index];
                  final starCount = starsInArea(area, widget.projectRepository, widget.winRepository);
                  return _AreaCard(
                    area: area,
                    starCount: starCount,
                    onTap: () => _openArea(area),
                  );
                },
              ),
            ),
          ],
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
      // Without this, the Column below shrinks to the width of its longest
      // line of text and then gets centered by the outer Column's default
      // crossAxisAlignment — the text inside reads as left-aligned relative
      // to its own (too-narrow) box, but that box itself sits centered on
      // the page instead of pinned to the left edge.
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
  const _AreaCard({required this.area, required this.starCount, required this.onTap});

  final LifeArea area;
  final int starCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: colors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: AreaTag(area: area, iconSize: 20, fontSize: 16),
              ),
              Text(
                context.strings.starsCount(starCount),
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
