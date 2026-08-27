import 'package:flutter/material.dart';

import '../data/win_repository.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import 'win_reader_screen.dart';

/// Entry point for reflecting on saved wins one at a time. Shows how many
/// stars are already lit and, if there's at least one, a way into the
/// read-only [WinReaderScreen]. If there are none yet, just asks the user
/// to come back later — there's nothing to reflect on yet.
class CrisisIntroScreen extends StatelessWidget {
  const CrisisIntroScreen({super.key, required this.wins, required this.repository});

  final List<Win> wins;
  final WinRepository repository;

  void _openReader(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: repository,
          initialWins: wins,
          startIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWins = wins.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.crisisGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.crisisMuted),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'It looks dark right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        hasWins
                            ? "You've already lit ${wins.length} star${wins.length == 1 ? '' : 's'} "
                                'before now. Let\'s look at them one at a time.'
                            : "You haven't lit any stars yet. Come back here once you have one.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.crisisMuted,
                        ),
                      ),
                      if (hasWins) ...[
                        const SizedBox(height: 36),
                        ElevatedButton.icon(
                          onPressed: () => _openReader(context),
                          icon: const Icon(Icons.auto_awesome, size: 17),
                          label: const Text('View your stars'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.onGold,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
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
