import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../debug/seed_data.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/win_card.dart';
import 'add_win_screen.dart';
import 'crisis_intro_screen.dart';
import 'sky_screen.dart';
import 'win_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WinRepository? _winRepository;
  ProjectRepository? _projectRepository;
  List<Win> _wins = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final winRepository = await WinRepository.create();
    final projectRepository = await ProjectRepository.create();
    setState(() {
      _winRepository = winRepository;
      _projectRepository = projectRepository;
      _wins = winRepository.getAll();
    });
  }

  Future<void> _openAddWinScreen() async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(projectRepository: projectRepository)),
    );
    if (result == null) return;

    await winRepository.add(
      title: result.title,
      description: result.description,
      projectId: result.projectId,
      intensity: result.intensity,
    );
    setState(() => _wins = winRepository.getAll());
  }

  Future<void> _openCrisisIntro() async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrisisIntroScreen(
          wins: _wins,
          repository: winRepository,
          projectsById: _projectsById(projectRepository),
          projectRepository: projectRepository,
        ),
      ),
    );
    setState(() => _wins = winRepository.getAll());
  }

  void _openSky() {
    final projectRepository = _projectRepository;
    final winRepository = _winRepository;
    if (projectRepository == null || winRepository == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkyScreen(projectRepository: projectRepository, winRepository: winRepository),
      ),
    );
  }

  Map<int, Project> _projectsById(ProjectRepository projectRepository) {
    return {for (final project in projectRepository.getAll()) project.id: project};
  }

  Future<void> _openWinReader(int index) async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: winRepository,
          initialWins: _wins,
          startIndex: index,
          allowEdit: true,
          projectsById: _projectsById(projectRepository),
          projectRepository: projectRepository,
          refreshWins: winRepository.getAll,
        ),
      ),
    );
    setState(() => _wins = winRepository.getAll());
  }

  Future<void> _seedSampleData() async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    await seedSampleData(winRepository: winRepository, projectRepository: projectRepository);
    setState(() => _wins = winRepository.getAll());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $winsPerSeedTap wins to each seed project.')),
      );
    }
  }

  Future<void> _resetAllData() async {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    if (winRepository == null || projectRepository == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.nightPanel,
        title: const Text('Reset all data?', style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This permanently deletes every win and project. This cannot be undone.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await winRepository.clear();
    await projectRepository.clear();
    setState(() => _wins = winRepository.getAll());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final winRepository = _winRepository;
    final projectRepository = _projectRepository;
    final ready = winRepository != null && projectRepository != null;

    final projectsById = projectRepository == null ? const <int, Project>{} : _projectsById(projectRepository);

    return Scaffold(
      body: !ready
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SafeArea(
              child: Column(
                children: [
                  const _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.auto_awesome,
                            label: 'Admire Your Stars',
                            onPressed: _openCrisisIntro,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.explore,
                            label: 'Sky',
                            onPressed: _openSky,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _seedSampleData,
                          icon: const Icon(Icons.science_outlined, size: 16, color: AppColors.muted),
                          label: const Text(
                            'Seed sample data',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _resetAllData,
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                          label: const Text(
                            'Reset all data',
                            style: TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_wins.isEmpty)
                    const _EmptyState()
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: _wins.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final win = _wins[index];
                          return WinCard(
                            win: win,
                            project: projectsById[win.projectId],
                            onTap: () => _openWinReader(index),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: !ready
          ? null
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _openAddWinScreen,
                backgroundColor: AppColors.gold,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: AppColors.onGold),
              ),
            ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: AppColors.gold),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.gold.withValues(alpha: 0.1),
        foregroundColor: AppColors.gold,
        side: const BorderSide(color: AppColors.goldDim),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR ARCHIVE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: AppColors.goldDim,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your wins',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Every win is a star, lit when you needed the light.',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.nightBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Your archive is still empty. Light your first star, even a small one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ),
    );
  }
}
