import 'package:flutter/material.dart';

import '../data/area_vision_repository.dart';
import '../data/custom_constellation_repository.dart';
import '../data/habit_completion_repository.dart';
import '../data/habit_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../widgets/area_tag.dart';
import '../widgets/responsive_content.dart';
import 'area_projects_screen.dart';

/// One life area's own page — reached by tapping it in [SkyScreen]. Shows
/// (and lets the user edit) that area's "vision" — their own words for what
/// they want out of it, something to work toward with goals and habits —
/// and a way onward into its constellations/stars ([AreaProjectsScreen]).
class AreaDetailScreen extends StatefulWidget {
  const AreaDetailScreen({
    super.key,
    required this.area,
    required this.areaVisionRepository,
    required this.projectRepository,
    required this.starRepository,
    required this.habitRepository,
    required this.habitCompletionRepository,
    required this.customConstellationRepository,
  });

  final LifeArea area;
  final AreaVisionRepository areaVisionRepository;
  final ProjectRepository projectRepository;
  final StarRepository starRepository;
  final HabitRepository habitRepository;
  final HabitCompletionRepository habitCompletionRepository;
  final CustomConstellationRepository customConstellationRepository;

  @override
  State<AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends State<AreaDetailScreen> {
  late final _visionController = TextEditingController(
    text: widget.areaVisionRepository.getVision(widget.area),
  );
  late final _visionFocusNode = FocusNode()..addListener(_handleFocusChange);

  void _handleFocusChange() {
    if (!_visionFocusNode.hasFocus) _saveVision();
  }

  Future<void> _saveVision() {
    return widget.areaVisionRepository.setVision(
      widget.area,
      _visionController.text,
    );
  }

  void _openProjects() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AreaProjectsScreen(
          area: widget.area,
          projectRepository: widget.projectRepository,
          starRepository: widget.starRepository,
          habitRepository: widget.habitRepository,
          habitCompletionRepository: widget.habitCompletionRepository,
          customConstellationRepository: widget.customConstellationRepository,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _visionFocusNode.removeListener(_handleFocusChange);
    _visionFocusNode.dispose();
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return PopScope(
      canPop: true,
      // Autosave, not a "discard changes?" guard — there's nothing to
      // discard, the field just saves whenever it loses focus or the
      // screen closes.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveVision();
      },
      child: Scaffold(
        backgroundColor: colors.night,
        body: SafeArea(
          child: ResponsiveContent(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: colors.muted),
                      ),
                      Expanded(
                        child: AreaTag(
                          area: widget.area,
                          iconSize: 22,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.areaVisionLabel,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _visionController,
                    focusNode: _visionFocusNode,
                    minLines: 6,
                    maxLines: null,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.areaVisionHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openProjects,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.gold,
                        side: BorderSide(color: colors.gold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        strings.areaViewProjectsAction,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
