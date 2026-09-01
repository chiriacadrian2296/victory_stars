import 'package:flutter/material.dart';

import '../data/constellation_shapes_v2.dart';
import '../data/custom_constellation_repository.dart';
import '../data/project_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../models/custom_constellation.dart';
import '../models/life_area.dart';
import '../theme/app_colors.dart';
import '../utils/icon_for_slug.dart';
import '../widgets/constellation_editor_painter.dart';
import '../widgets/responsive_content.dart';
import 'constellation_editor_screen.dart';

/// Creates a project: a name, a [LifeArea], a hand-drawn constellation
/// (draw a new one or pick from [_selectedCustomConstellation] — see
/// [ConstellationEditorScreen] — required, since every project needs an
/// actual shape for its wins to light up stars in), and an icon slug for
/// the small badge glyph shown in project lists — a separate, purely
/// cosmetic choice, unrelated to the constellation shape.
///
/// [presetArea] locks the area (e.g. opened from that area's project list);
/// when omitted (e.g. opened inline while adding a win), the user picks an
/// area here first.
class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({
    super.key,
    required this.projectRepository,
    required this.customConstellationRepository,
    this.presetArea,
  });

  final ProjectRepository projectRepository;
  final CustomConstellationRepository customConstellationRepository;
  final LifeArea? presetArea;

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late LifeArea? _selectedArea = widget.presetArea;
  String? _selectedIconSlug;
  CustomConstellation? _selectedCustomConstellation;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Everything on this form starts blank/unset, so unlike
  /// `AddStarScreen`'s own version of this getter (which has to compare
  /// against a possibly-pre-filled edit), "has anything changed" here just
  /// means "has anything been entered at all" — [_selectedArea] is the one
  /// exception, seeded from [NewProjectScreen.presetArea] rather than null.
  bool get _hasUnsavedChanges {
    return _nameController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedArea != widget.presetArea ||
        _selectedIconSlug != null ||
        _selectedCustomConstellation != null;
  }

  /// Shared by the back button and the system back gesture: leaving with
  /// unsaved changes needs confirmation first, everything else pops right
  /// away — mirrors `AddStarScreen._handleBack`.
  Future<void> _handleBack() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final strings = context.strings;
    final colors = context.colors;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        title: Text(
          strings.discardChangesConfirmTitle,
          style: TextStyle(color: colors.text),
        ),
        content: Text(
          strings.discardChangesConfirmBody,
          style: TextStyle(color: colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel, style: TextStyle(color: colors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.discardChangesAction,
              style: TextStyle(color: colors.danger),
            ),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  /// Same visual language as `AddStarScreen`'s date/time picker fields
  /// (label above, bordered row with a leading icon + the current
  /// value/hint) — see [_PickerField]. 1:3 width split (icon:area) instead
  /// of date/time's 1:1, in an [Expanded] pair.
  Widget _buildIconField(AppColors colors, AppStrings strings) {
    return _PickerField(
      label: strings.iconLabel,
      hint: strings.iconLabel,
      // A fixed representative glyph while unselected — like the calendar/
      // clock icons on the date/time fields — not a "+", which only made
      // sense back when this field's whole look changed on selection.
      icon: _selectedIconSlug == null
          ? Icons.apps_outlined
          : iconForSlug(_selectedIconSlug!),
      text: _selectedIconSlug,
      onTap: _openIconPicker,
      iconOnlyWhenSelected: true,
    );
  }

  Widget _buildAreaField(AppColors colors, AppStrings strings) {
    return _PickerField(
      label: strings.areaLabel,
      hint: strings.areaLabel,
      icon: _selectedArea?.icon ?? Icons.explore_outlined,
      text: _selectedArea?.displayName(strings),
      onTap: _openAreaPicker,
    );
  }

  /// Area icons (see [LifeAreaX.iconSlug]) are reserved for areas — a
  /// project can never pick one, so an area and a project never render with
  /// the same icon and get visually confused.
  static final _areaOnlySlugs = LifeArea.values.map((a) => a.iconSlug).toSet();

  List<String> _orderedIconSlugs(LifeArea? area) {
    final all =
        availableIconSlugs
            .where((slug) => !_areaOnlySlugs.contains(slug))
            .toList()
          ..sort();
    if (area == null) return all;
    final suggested =
        (suggestedIconsByArea[area.suggestedIconsKey] ?? const <String>[])
            .where((slug) => !_areaOnlySlugs.contains(slug));
    final rest = all.where((slug) => !suggested.contains(slug)).toList();
    return [...suggested, ...rest];
  }

  /// Opens the editor to draw a brand new shape, or — when [existing] is
  /// given (tapping a saved tile's edit pencil) — to revise one already
  /// saved. Either way, whatever comes back becomes the current selection:
  /// after drawing a new one there's nothing else it could sensibly select,
  /// and after editing an existing one the user almost certainly wants
  /// their just-revised version applied to this project rather than having
  /// to tap it again.
  Future<void> _openConstellationEditor({CustomConstellation? existing}) async {
    final saved = await Navigator.of(context).push<CustomConstellation>(
      MaterialPageRoute(
        builder: (_) => ConstellationEditorScreen(
          customConstellationRepository: widget.customConstellationRepository,
          existing: existing,
        ),
      ),
    );
    if (saved != null && mounted) {
      setState(() => _selectedCustomConstellation = saved);
    }
  }

  Future<void> _openAreaPicker() async {
    final strings = context.strings;
    final picked = await _showSearchablePicker<LifeArea>(
      context: context,
      title: strings.areaLabel,
      items: LifeArea.values,
      matches: (area, query) =>
          area.displayName(strings).toLowerCase().contains(query),
      // Only 8, fixed areas — a search field would just be clutter.
      showSearch: false,
      initialSelection: _selectedArea,
      bodyBuilder: (context, filtered, selected, onSelect) {
        // 2 columns x 4 rows — all 8 areas visible at once, no scrolling
        // needed or possible. Same square-tile idea as the icon grid,
        // just with room for the area's name inside too.
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            for (final area in filtered)
              _AreaOption(
                area: area,
                selected: selected == area,
                onTap: () => onSelect(area),
              ),
          ],
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedArea = picked);
    }
  }

  Future<void> _openIconPicker() async {
    final picked = await _showSearchablePicker<String>(
      context: context,
      title: context.strings.chooseIconTitle,
      items: _orderedIconSlugs(_selectedArea),
      matches: (slug, query) => slug.toLowerCase().contains(query),
      initialSelection: _selectedIconSlug,
      bodyBuilder: (context, filtered, selected, onSelect) {
        return GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final slug in filtered)
              _IconOption(
                slug: slug,
                selected: selected == slug,
                onTap: () => onSelect(slug),
              ),
          ],
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedIconSlug = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final area = _selectedArea;
    final iconSlug = _selectedIconSlug;
    final constellation = _selectedCustomConstellation;
    if (name.isEmpty ||
        area == null ||
        iconSlug == null ||
        constellation == null) {
      return;
    }
    assert(
      !_areaOnlySlugs.contains(iconSlug),
      'Area icons are reserved and should never reach a project.',
    );

    final project = await widget.projectRepository.add(
      name: name,
      area: area,
      iconSlug: iconSlug,
      customConstellationId: constellation.id,
      description: _descriptionController.text,
    );
    if (mounted) Navigator.of(context).pop(project);
  }

  void _showCannotSaveMessage() {
    final colors = context.colors;
    final strings = context.strings;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.nightPanel,
        content: Text(
          strings.cannotSaveMissingInfo,
          style: TextStyle(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.gotIt, style: TextStyle(color: colors.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final scaffold = Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: Icon(Icons.arrow_back, color: colors.muted),
                    ),
                    Text(
                      strings.newProjectEyebrow,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: colors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  strings.newProjectQuestion,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.presetArea == null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildAreaField(colors, strings),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildIconField(colors, strings),
                      ),
                    ],
                  )
                else
                  _buildIconField(colors, strings),
                const SizedBox(height: 20),
                Text(
                  strings.nameLabel,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  autofocus: widget.presetArea != null,
                  style: TextStyle(color: colors.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: strings.newProjectNameHint,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.projectDescriptionLabel,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: colors.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: strings.projectDescriptionHint,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.yourConstellationsLabel,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _openConstellationEditor,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.gold,
                      side: BorderSide(color: colors.gold),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gesture, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          strings.drawYourOwnShort,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.customConstellationRepository
                    .getAll()
                    .isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.nightBorder, height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final custom
                          in widget.customConstellationRepository.getAll())
                        _CustomConstellationOption(
                          constellation: custom,
                          selected:
                              _selectedCustomConstellation?.id == custom.id,
                          onTap: () => setState(
                            () => _selectedCustomConstellation = custom,
                          ),
                          onEdit: () =>
                              _openConstellationEditor(existing: custom),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                Center(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _nameController,
                    builder: (context, value, child) {
                      final canSave =
                          value.text.trim().isNotEmpty &&
                          _selectedArea != null &&
                          _selectedIconSlug != null &&
                          _selectedCustomConstellation != null;
                      // Same "lit disc" treatment as AddStarScreen's own save
                      // FAB — on (gold, glowing) once everything required is
                      // filled in, off (muted, flat) otherwise.
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: canSave
                              ? [
                                  BoxShadow(
                                    color: colors.gold.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: FloatingActionButton(
                          heroTag: 'createProjectFab',
                          onPressed: canSave ? _save : _showCannotSaveMessage,
                          backgroundColor: canSave ? colors.gold : colors.muted,
                          elevation: 0,
                          shape: const CircleBorder(),
                          tooltip: strings.createProject,
                          child: Icon(Icons.check, color: colors.night),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: scaffold,
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.slug,
    required this.selected,
    required this.onTap,
  });

  final String slug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? colors.gold.withValues(alpha: 0.15)
              : colors.nightPanel,
          border: Border.all(
            color: selected ? colors.gold : colors.nightBorder,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          iconForSlug(slug),
          color: selected ? colors.gold : colors.muted,
          size: 20,
        ),
      ),
    );
  }
}

/// One square tile in the area picker's 2x4 grid — icon on top, name
/// below, same selected/unselected treatment as [_IconOption].
class _AreaOption extends StatelessWidget {
  const _AreaOption({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  final LifeArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? colors.gold.withValues(alpha: 0.15)
              : colors.nightPanel,
          border: Border.all(
            color: selected ? colors.gold : colors.nightBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              area.icon,
              size: 34,
              color: selected ? colors.gold : colors.muted,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                area.displayName(strings),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: selected ? colors.gold : colors.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footprint of every saved-shape preview tile. Big enough that a shape's
/// own stars/lines (drawn at their normal, fixed-pixel radius — see
/// [ConstellationEditorPainter]) read clearly instead of nearly
/// overlapping, which is what happened at the previous, much smaller size.
const double _constellationPreviewSide = 108.0;

/// A live preview (via [ConstellationEditorPainter]) of one of the user's
/// own previously-saved shapes, so a returning user can reuse or pick among
/// prior hand-drawn constellations instead of only ever drawing fresh ones.
///
/// Points are mapped into an inset drawable area, not the full tile —
/// `ConstellationEditorPainter` draws each star as a fixed-radius circle
/// (see its `_pointRadius`/`_ringRadius`), so a point sitting exactly at the
/// shape's own 0..1 edge would otherwise have its circle clipped by the
/// tile's border at small sizes. [_inset] reserves enough margin for that,
/// and `clipBehavior: Clip.antiAlias` on the [Container] is a second,
/// belt-and-suspenders guard against any point spilling past the tile.
class _CustomConstellationOption extends StatelessWidget {
  const _CustomConstellationOption({
    required this.constellation,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  final CustomConstellation constellation;
  final bool selected;
  final VoidCallback onTap;

  /// Opens this shape back up in the editor to revise it — a small pencil
  /// button in the tile's corner, distinct from [onTap] (which just selects
  /// it for the project being created).
  final VoidCallback onEdit;

  static const _side = _constellationPreviewSide;
  static const _inset = 14.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final drawableSide = _side - _inset * 2;
    final points = constellation.shape.points
        .map(
          (p) => Offset(
            _inset + p.dx * drawableSide,
            _inset + p.dy * drawableSide,
          ),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTile(colors, points),
        const SizedBox(height: 4),
        SizedBox(
          width: _side,
          child: Text(
            constellation.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: selected ? colors.gold : colors.muted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(AppColors colors, List<Offset> points) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: _side,
            height: _side,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.nightPanel,
              border: Border.all(
                color: selected ? colors.gold : colors.nightBorder,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              size: const Size(_side, _side),
              painter: ConstellationEditorPainter(
                points: points,
                edges: constellation.shape.edges,
                highlightedIndex: null,
                // Selection is shown by the tile's own gold border only —
                // the drawn shape itself (points/lines) stays the same
                // white/muted look whether selected or not.
                pointColor: colors.text,
                highlightColor: colors.gold,
                lineColor: colors.muted.withValues(alpha: 0.6),
                pointRadius: 2.5,
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: Material(
            color: colors.night.withValues(alpha: 0.75),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onEdit,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.edit, size: 18, color: colors.gold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The area/icon selector field — a mix of two earlier designs. Unselected,
/// it's the same shape as `AddStarScreen._DateField` (label above, a
/// bordered full-width row with a fixed representative [icon] and [hint]),
/// so a project's area and badge icon read as siblings of its date/time
/// while nothing's picked yet. Once something *is* picked, it switches to
/// the bolder look the very first version of this field had — a gold
/// border and a bigger, fully-lit icon — since that read better than
/// staying muted just because the row itself is compact.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconOnlyWhenSelected = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? text;
  final VoidCallback onTap;
  // The icon field has no meaningful text to show once picked (the slug
  // isn't user-facing) — just the icon itself, centered, reads better than
  // a Row with an empty label slot next to it.
  final bool iconOnlyWhenSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = text != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: colors.muted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.nightPanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.gold : colors.nightBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: iconOnlyWhenSelected && selected
                ? Center(child: Icon(icon, size: 22, color: colors.gold))
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: selected ? 22 : 16,
                        color: selected ? colors.gold : colors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text ?? hint,
                          style: TextStyle(
                            color: selected ? colors.text : colors.muted,
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Opens a fixed-height bottom sheet — a search field ([showSearch], on by
/// default; skip it for a short fixed list like the areas) above a
/// scrollable body of [items] (rendered by [bodyBuilder], so callers can
/// lay them out as a grid or a list) — plus an OK button that confirms
/// whatever's currently tapped and a close icon that dismisses without
/// changing anything. Shared by the area and icon pickers.
Future<T?> _showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required bool Function(T item, String query) matches,
  required Widget Function(
    BuildContext context,
    List<T> filtered,
    T? selected,
    ValueChanged<T> onSelect,
  )
  bodyBuilder,
  T? initialSelection,
  bool showSearch = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.nightPanel,
    builder: (sheetContext) => _SearchablePickerSheet<T>(
      title: title,
      items: items,
      matches: matches,
      bodyBuilder: bodyBuilder,
      initialSelection: initialSelection,
      showSearch: showSearch,
    ),
  );
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.matches,
    required this.bodyBuilder,
    required this.initialSelection,
    required this.showSearch,
  });

  final String title;
  final List<T> items;
  final bool Function(T item, String query) matches;
  final Widget Function(
    BuildContext context,
    List<T> filtered,
    T? selected,
    ValueChanged<T> onSelect,
  )
  bodyBuilder;
  final T? initialSelection;
  final bool showSearch;

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  String _query = '';
  late T? _selected = widget.initialSelection;

  List<T> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) => widget.matches(item, query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final filtered = _filtered;
    // Fixed, not just capped — a min==max height means the sheet doesn't
    // visibly shrink as typing a search query narrows the results down to
    // just a couple of items; the body area below just has more empty
    // space instead of the whole sheet resizing under the user's thumb.
    //
    // The keyboard is subtracted from that target height (not just capped
    // by it): showModalBottomSheet already wraps this content in its own
    // AnimatedPadding that grows by the keyboard's height as it opens, so
    // without this the sheet's *total* footprint (our fixed height + that
    // padding) would grow past the original 85%, pushing the whole sheet's
    // top edge upward — which is exactly the "shifts slightly" the search
    // field inside the icon picker causes. Shrinking our own height by the
    // same amount the padding is about to add cancels that out, so the top
    // edge stays put and only the scrollable body gets shorter.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight =
        (MediaQuery.sizeOf(context).height * 0.85 - keyboardInset).clamp(
          0.0,
          MediaQuery.sizeOf(context).height * 0.85,
        );

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.muted),
                    tooltip: strings.closeAction,
                  ),
                ],
              ),
              if (widget.showSearch) ...[
                const SizedBox(height: 4),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  style: TextStyle(color: colors.text, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: strings.searchHint,
                    prefixIcon: Icon(
                      Icons.search,
                      color: colors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            strings.noSearchResults,
                            style: TextStyle(color: colors.muted, fontSize: 14),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: widget.bodyBuilder(
                          context,
                          filtered,
                          _selected,
                          (item) => setState(() => _selected = item),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.gold,
                    foregroundColor: colors.onGold,
                    disabledBackgroundColor: colors.nightBorder,
                    disabledForegroundColor: colors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    strings.pickerConfirmAction,
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
    );
  }
}
