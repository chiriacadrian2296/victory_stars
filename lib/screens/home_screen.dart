import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../debug/seed_data.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/win_card.dart';
import 'add_win_screen.dart';
import 'crisis_intro_screen.dart';
import 'win_reader_screen.dart';

/// The flat, cross-project archive of every win — one tab of [RootScreen].
/// Receives its repositories from the root rather than loading its own, so
/// both tabs (this and Sky) always see the same in-memory data.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Win> _wins = const [];

  @override
  void initState() {
    super.initState();
    _wins = widget.winRepository.getAll();
  }

  Future<void> _openAddWinScreen() async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

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
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

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

  Map<int, Project> _projectsById(ProjectRepository projectRepository) {
    return {for (final project in projectRepository.getAll()) project.id: project};
  }

  Future<void> _openWinReader(int index) async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;

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
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;
    final strings = context.strings;

    await seedSampleData(winRepository: winRepository, projectRepository: projectRepository);
    setState(() => _wins = winRepository.getAll());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.seedSampleDataResult(winsPerSeedTap))),
      );
    }
  }

  Future<void> _resetAllData() async {
    final winRepository = widget.winRepository;
    final projectRepository = widget.projectRepository;
    final colors = context.colors;
    final strings = context.strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        title: Text(strings.resetAllDataConfirmTitle, style: TextStyle(color: colors.text)),
        content: Text(
          strings.resetAllDataConfirmBody,
          style: TextStyle(color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteEverything, style: TextStyle(color: colors.danger)),
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
        SnackBar(content: Text(strings.allDataCleared)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsById = _projectsById(widget.projectRepository);
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _SecondaryButton(
                icon: Icons.auto_awesome,
                label: strings.admireYourStars,
                onPressed: _openCrisisIntro,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _seedSampleData,
                    icon: Icon(Icons.science_outlined, size: 16, color: colors.muted),
                    label: Text(
                      strings.seedSampleData,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetAllData,
                    icon: Icon(Icons.delete_outline, size: 16, color: colors.danger),
                    label: Text(
                      strings.resetAllData,
                      style: TextStyle(color: colors.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_wins.isEmpty)
              _EmptyState(strings.archiveEmpty)
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.gold.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddWinScreen,
          backgroundColor: colors.gold,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: colors.onGold),
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
    final colors = context.colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: colors.gold),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.gold.withValues(alpha: 0.1),
        foregroundColor: colors.gold,
        side: BorderSide(color: colors.goldDim),
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
    final colors = context.colors;
    final strings = context.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.homeEyebrow,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: colors.goldDim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.homeTitle,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.homeSubtitle,
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: colors.nightBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colors.muted),
        ),
      ),
    );
  }
}
