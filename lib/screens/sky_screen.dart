import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
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
  int _starsInArea(LifeArea area) {
    var total = 0;
    for (final project in widget.projectRepository.getProjectsForArea(area)) {
      total += widget.winRepository.getAllForProject(project.id).length;
    }
    return total;
  }

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
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                ),
                const Text(
                  'Your sky',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.text),
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: LifeArea.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final area = LifeArea.values[index];
                  final starCount = _starsInArea(area);
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

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.starCount, required this.onTap});

  final LifeArea area;
  final int starCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: AreaTag(area: area, iconSize: 20, fontSize: 16),
              ),
              Text(
                '$starCount star${starCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
