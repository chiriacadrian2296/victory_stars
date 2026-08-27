import 'package:flutter/material.dart';

import '../data/constellation_shapes.dart';
import '../data/project_repository.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../theme/app_colors.dart';
import '../utils/icon_for_slug.dart';

/// Creates a project: a name, a [LifeArea], and an icon whose slug must be
/// one of the keys in `constellation_shapes.dart` — that's a hard
/// requirement, not a style choice, since [Project.iconSlug] is looked up
/// there to render the project's constellation.
///
/// [presetArea] locks the area (e.g. opened from that area's project list);
/// when omitted (e.g. opened inline while adding a win), the user picks an
/// area here first.
class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key, required this.projectRepository, this.presetArea});

  final ProjectRepository projectRepository;
  final LifeArea? presetArea;

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameController = TextEditingController();
  late LifeArea? _selectedArea = widget.presetArea;
  String? _selectedIconSlug;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> _orderedIconSlugs(LifeArea? area) {
    final all = constellationShapes.keys.toList()..sort();
    if (area == null) return all;
    final suggested = suggestedIconsByArea[area.suggestedIconsKey] ?? const <String>[];
    final rest = all.where((slug) => !suggested.contains(slug)).toList();
    return [...suggested, ...rest];
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final area = _selectedArea;
    final iconSlug = _selectedIconSlug;
    if (name.isEmpty || area == null || iconSlug == null) return;

    final project = await widget.projectRepository.add(name: name, area: area, iconSlug: iconSlug);
    if (mounted) Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                  ),
                  const Text(
                    'NEW PROJECT',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'What project is this?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: AppColors.text),
              ),
              const SizedBox(height: 24),
              if (widget.presetArea == null) ...[
                const Text('Area', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in LifeArea.values)
                      _AreaChip(
                        area: area,
                        selected: _selectedArea == area,
                        onTap: () => setState(() => _selectedArea = area),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const Text('Name', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: widget.presetArea != null,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(hintText: 'E.g. Build this app'),
              ),
              const SizedBox(height: 20),
              const Text('Icon', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final slug in _orderedIconSlugs(_selectedArea))
                    _IconOption(
                      slug: slug,
                      selected: _selectedIconSlug == slug,
                      onTap: () => setState(() => _selectedIconSlug = slug),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, child) {
                    final canSave =
                        value.text.trim().isNotEmpty && _selectedArea != null && _selectedIconSlug != null;
                    return ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.onGold,
                        disabledBackgroundColor: AppColors.nightBorder,
                        disabledForegroundColor: AppColors.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Create project',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.area, required this.selected, required this.onTap});

  final LifeArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.nightPanel,
          border: Border.all(color: selected ? AppColors.gold : AppColors.nightBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(area.icon, size: 15, color: selected ? AppColors.gold : AppColors.muted),
            const SizedBox(width: 6),
            Text(
              area.displayName,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.gold : AppColors.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.slug, required this.selected, required this.onTap});

  final String slug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.nightPanel,
          border: Border.all(color: selected ? AppColors.gold : AppColors.nightBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          iconForSlug(slug),
          color: selected ? AppColors.gold : AppColors.muted,
          size: 20,
        ),
      ),
    );
  }
}
