import 'package:flutter/material.dart';

import '../data/area_vision_repository.dart';
import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/sky_explorer_view.dart';

/// A full-screen popup opened from the Sky's sky-search overlay
/// button — search/filter/3-level browsing ([SkyExplorerView]) over the
/// same close-button-only header every other popup page in the app uses,
/// with the selected level's name (Supernovas/Constellations/Stars) as this
/// header's own title — see [_modeLabel] — rather than drawn inline in the
/// body, freeing space below for the list itself. Every card's "take me
/// there" button pops this page with a `SkyNavigationTarget` for
/// `NebulaScreen` to fly its camera to.
class SkySearchScreen extends StatefulWidget {
  const SkySearchScreen({
    super.key,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
    required this.areaVisionRepository,
  });

  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;
  final AreaVisionRepository areaVisionRepository;

  @override
  State<SkySearchScreen> createState() => _SkySearchScreenState();
}

class _SkySearchScreenState extends State<SkySearchScreen> {
  /// Null only for the first frame or two, before [SkyExplorerView] reports
  /// its own starting mode via `onModeLabelChanged` — [build] falls back to
  /// the same "Supernovas" label it starts on regardless, so there's no
  /// visible flash of an empty title.
  String? _modeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Row(
                children: [
                  Material(
                    color: colors.nightPanel.withValues(alpha: 0.75),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.close, color: colors.gold, size: 22),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _modeLabel ?? strings.skyModeSupernovas,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.gold,
                        ),
                      ),
                    ),
                  ),
                  // Balances the close button's own width so the title
                  // above stays visually centered instead of skewed right.
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: SkyExplorerView(
                projectRepository: widget.projectRepository,
                starRepository: widget.starRepository,
                habitRepository: widget.habitRepository,
                habitCompletionRepository: widget.habitCompletionRepository,
                customConstellationRepository: widget.customConstellationRepository,
                areaVisionRepository: widget.areaVisionRepository,
                onNavigateTo: (target) => Navigator.of(context).pop(target),
                onModeLabelChanged: (label) =>
                    setState(() => _modeLabel = label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
