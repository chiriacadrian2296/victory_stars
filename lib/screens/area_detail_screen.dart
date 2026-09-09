import 'package:flutter/material.dart';

import '../data/area_vision_repository.dart';
import '../data/project_repository.dart';
import '../data/star_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_style.dart';
import '../utils/star_stats.dart';
import '../widgets/area_tag.dart';
import '../widgets/responsive_content.dart';

/// One Supernova's own page — reached by tapping it in the Sky's
/// search popup (`SkyExplorerView`'s Supernovas view). Shows the area's
/// icon, name, and description, three big numbers (constellations/stars/
/// intensity), and that area's "vision" — their own words for what they
/// want out of it — editable via the Edit button. Nothing to navigate
/// onward to from here, only back; constellations and stars live in that
/// same popup's own Constellations/Stars views instead.
class AreaDetailScreen extends StatefulWidget {
  const AreaDetailScreen({
    super.key,
    required this.area,
    required this.areaVisionRepository,
    required this.projectRepository,
    required this.starRepository,
  });

  final LifeArea area;
  final AreaVisionRepository areaVisionRepository;
  final ProjectRepository projectRepository;
  final StarRepository starRepository;

  @override
  State<AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends State<AreaDetailScreen> {
  late final _visionController = TextEditingController(
    text: widget.areaVisionRepository.getVision(widget.area),
  );
  late final _visionFocusNode = FocusNode()..addListener(_handleFocusChange);
  bool _editingVision = false;

  void _handleFocusChange() {
    if (!_visionFocusNode.hasFocus) {
      _saveVision();
      setState(() => _editingVision = false);
    }
  }

  Future<void> _saveVision() {
    return widget.areaVisionRepository.setVision(
      widget.area,
      _visionController.text,
    );
  }

  void _startEditingVision() {
    setState(() => _editingVision = true);
    _visionFocusNode.requestFocus();
  }

  Future<void> _confirmVision() async {
    await _saveVision();
    if (!mounted) return;
    setState(() => _editingVision = false);
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
    final area = widget.area;

    final constellationCount = widget.projectRepository
        .getProjectsForArea(area)
        .length;
    final starCount = starsInArea(
      area,
      widget.projectRepository,
      widget.starRepository,
    );
    final totalIntensity = totalIntensityInArea(
      area,
      widget.projectRepository,
      widget.starRepository,
    );

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
                        child: AreaTag(area: area, iconSize: 22, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      area.description(strings),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: colors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          value: '$constellationCount',
                          label: strings.areaConstellationsStatLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBlock(
                          value: '$starCount',
                          label: strings.areaStarsStatLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBlock(
                          value: '$totalIntensity',
                          label: strings.areaIntensityStatLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    strings.areaVisionLabel,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
                  const SizedBox(height: 6),
                  if (_editingVision)
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
                    )
                  else
                    Text(
                      _visionController.text.trim().isEmpty
                          ? strings.areaVisionHint
                          : _visionController.text,
                      style: TextStyle(
                        color: _visionController.text.trim().isEmpty
                            ? colors.muted
                            : colors.text,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _editingVision
                          ? _confirmVision
                          : _startEditingVision,
                      icon: Icon(_editingVision ? Icons.check : Icons.edit),
                      label: Text(
                        _editingVision
                            ? strings.saveChanges
                            : strings.editVisionAction,
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

/// One of the three big numbers on a Supernova's detail page — value up top
/// in gold, a small muted label underneath. Styled after `stats_screen.dart`'s
/// `_StatCard`, minus its tap target — nothing to drill into here.
class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: panelDecoration(colors),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: kFontMono,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
        ],
      ),
    );
  }
}
