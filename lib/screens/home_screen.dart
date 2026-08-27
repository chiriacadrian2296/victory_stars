import 'package:flutter/material.dart';

import '../data/win_repository.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../widgets/win_card.dart';
import 'add_win_screen.dart';
import 'crisis_intro_screen.dart';
import 'win_reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WinRepository? _repository;
  List<Win> _wins = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = await WinRepository.create();
    setState(() {
      _repository = repository;
      _wins = repository.getAll();
    });
  }

  Future<void> _openAddWinScreen() async {
    final repository = _repository;
    if (repository == null) return;

    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => const AddWinScreen()),
    );
    if (result == null) return;

    await repository.add(title: result.title, description: result.description);
    setState(() => _wins = repository.getAll());
  }

  void _openCrisisIntro() {
    final repository = _repository;
    if (repository == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrisisIntroScreen(wins: _wins, repository: repository),
      ),
    );
  }

  Future<void> _openWinReader(int index) async {
    final repository = _repository;
    if (repository == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: repository,
          initialWins: _wins,
          startIndex: index,
          allowEdit: true,
        ),
      ),
    );
    setState(() => _wins = repository.getAll());
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;

    return Scaffold(
      body: repository == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SafeArea(
              child: Column(
                children: [
                  const _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _AdmireStarsButton(onPressed: _openCrisisIntro),
                  ),
                  if (_wins.isEmpty)
                    const _EmptyState()
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: _wins.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => WinCard(
                          win: _wins[index],
                          onTap: () => _openWinReader(index),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: repository == null
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

class _AdmireStarsButton extends StatelessWidget {
  const _AdmireStarsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.auto_awesome, size: 17, color: AppColors.gold),
        label: const Text('Admire Your Stars'),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.gold.withValues(alpha: 0.1),
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.goldDim),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
            'YOUR SKY',
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
          'Your sky is still empty. Light your first star, even a small one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ),
    );
  }
}
