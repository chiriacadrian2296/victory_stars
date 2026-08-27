import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import 'win_reader_screen.dart';

/// Entry point for reflecting on saved wins one at a time. Shows how many
/// stars are already lit and, if there's at least one, a way into
/// [WinReaderScreen] — editable, same as tapping into a star from Sky, so a
/// win can be corrected or re-scoped mid-reflection too. If there are none
/// yet, just asks the user to come back later — there's nothing to reflect
/// on yet.
class CrisisIntroScreen extends StatelessWidget {
  const CrisisIntroScreen({
    super.key,
    required this.wins,
    required this.repository,
    required this.projectsById,
    required this.projectRepository,
  });

  final List<Win> wins;
  final WinRepository repository;
  final Map<int, Project> projectsById;
  final ProjectRepository projectRepository;

  void _openReader(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: repository,
          initialWins: wins,
          startIndex: 0,
          projectsById: projectsById,
          allowEdit: true,
          projectRepository: projectRepository,
          refreshWins: repository.getAll,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWins = wins.isNotEmpty;
    final colors = context.colors;
    final strings = context.strings;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.crisisMuted),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.crisisTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        hasWins ? strings.crisisSubtitleWithWins(wins.length) : strings.crisisSubtitleNoWins,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: colors.crisisMuted,
                        ),
                      ),
                      if (hasWins) ...[
                        const SizedBox(height: 36),
                        ElevatedButton.icon(
                          onPressed: () => _openReader(context),
                          icon: const Icon(Icons.auto_awesome, size: 17),
                          label: Text(strings.viewYourStars),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.gold,
                            foregroundColor: colors.onGold,
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
