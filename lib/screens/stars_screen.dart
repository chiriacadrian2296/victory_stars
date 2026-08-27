import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../utils/win_stats.dart';
import '../widgets/area_tag.dart';
import 'area_wins_screen.dart';

/// The Stars tab: pick a life area, then browse/search every win in it
/// (across all of that area's projects) as a flat, searchable list —
/// distinct from Sky's constellation-first browsing. Reuses the same area
/// cards as Sky for a consistent "pick an area" step.
class StarsScreen extends StatefulWidget {
  const StarsScreen({super.key, required this.projectRepository, required this.winRepository});

  final ProjectRepository projectRepository;
  final WinRepository winRepository;

  @override
  State<StarsScreen> createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen> {
  Future<void> _openArea(LifeArea area) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AreaWinsScreen(
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
                  return _AreaCard(area: area, starCount: starCount, onTap: () => _openArea(area));
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.starsEyebrow,
            style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600, color: colors.goldDim),
          ),
          const SizedBox(height: 6),
          Text(
            strings.starsTitle,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colors.text),
          ),
          const SizedBox(height: 6),
          Text(strings.starsSubtitle, style: TextStyle(fontSize: 14, color: colors.muted)),
        ],
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
              Expanded(child: AreaTag(area: area, iconSize: 20, fontSize: 16)),
              Text(context.strings.starsCount(starCount), style: TextStyle(fontSize: 13, color: colors.muted)),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
