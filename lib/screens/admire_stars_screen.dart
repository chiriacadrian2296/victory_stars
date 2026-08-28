import 'dart:async';

import 'package:flutter/material.dart';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../l10n/strings_scope.dart';
import '../models/life_area.dart';
import '../models/project.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import 'win_reader_screen.dart';

/// Entry point for reflecting on saved wins — reachable from every tab
/// (see [RootScreen]'s persistent floating button), not tied to a "crisis"
/// moment specifically. Asks which life areas to draw from every time
/// (defaulting to all), then shows a shuffled, editable browse of every win
/// in that selection via [WinReaderScreen].
class AdmireStarsScreen extends StatefulWidget {
  const AdmireStarsScreen({super.key, required this.winRepository, required this.projectRepository});

  final WinRepository winRepository;
  final ProjectRepository projectRepository;

  @override
  State<AdmireStarsScreen> createState() => _AdmireStarsScreenState();
}

class _AdmireStarsScreenState extends State<AdmireStarsScreen> {
  Set<LifeArea> _selected = {...LifeArea.values};

  bool get _allSelected => _selected.length == LifeArea.values.length;

  void _toggleAll() {
    setState(() => _selected = _allSelected ? {} : {...LifeArea.values});
  }

  void _toggleArea(LifeArea area) {
    setState(() {
      if (!_selected.remove(area)) _selected.add(area);
    });
  }

  Widget _areaChip(BuildContext context, LifeArea area) {
    final strings = context.strings;
    return _AreaChip(
      label: area.displayName(strings),
      icon: area.icon,
      selected: _selected.contains(area),
      onTap: () => _toggleArea(area),
    );
  }

  Map<int, Project> _projectsById() {
    return {for (final project in widget.projectRepository.getAll()) project.id: project};
  }

  List<Win> _poolForSelection() {
    final projectsById = _projectsById();
    return widget.winRepository.getAll().where((w) {
      final project = projectsById[w.projectId];
      return project != null && _selected.contains(project.area);
    }).toList();
  }

  Future<void> _start() async {
    final pool = _poolForSelection();
    if (pool.isEmpty) return;

    final shuffled = [...pool]..shuffle();
    final shuffledIds = shuffled.map((w) => w.id).toList();
    final selectionSnapshot = Set<LifeArea>.from(_selected);

    List<Win> currentInShuffledOrder() {
      final projectsById = _projectsById();
      final byId = {for (final w in widget.winRepository.getAll()) w.id: w};
      return shuffledIds.map((id) => byId[id]).whereType<Win>().where((w) {
        final project = projectsById[w.projectId];
        return project != null && selectionSnapshot.contains(project.area);
      }).toList();
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WinReaderScreen(
          repository: widget.winRepository,
          initialWins: shuffled,
          startIndex: 0,
          allowEdit: true,
          projectsById: _projectsById(),
          projectRepository: widget.projectRepository,
          refreshWins: currentInShuffledOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final poolSize = _poolForSelection().length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.crisisMuted),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      // minHeight + IntrinsicHeight lets the quote carousel
                      // below sit in an Expanded slot — centered in whatever
                      // room is actually left under the chips — while still
                      // allowing the whole column to scroll normally if the
                      // content above ever needs more room than the screen has.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  strings.admireYourStars,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  strings.admireTagline,
                                  style: TextStyle(fontSize: 15, height: 1.5, color: colors.crisisMuted),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _AllAreasSwitch(
                                label: strings.allAreasLabel,
                                value: _allSelected,
                                onChanged: (_) => _toggleAll(),
                              ),
                              const SizedBox(height: 28),
                              // Two equal-width columns rather than a Wrap, so
                              // every chip claims the same amount of space
                              // regardless of how long its label is, instead
                              // of packing tighter around short labels.
                              Column(
                                children: [
                                  for (var row = 0; row * 2 < LifeArea.values.length; row++) ...[
                                    if (row > 0) const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        for (var col = 0; col < 2; col++) ...[
                                          if (col > 0) const SizedBox(width: 12),
                                          Expanded(child: _areaChip(context, LifeArea.values[row * 2 + col])),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              Expanded(child: Center(child: _UpliftingQuoteCarousel())),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: Column(
                  children: [
                    Text(
                      poolSize == 0 ? strings.pickAtLeastOneArea : strings.starsCount(poolSize),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: colors.crisisMuted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: poolSize == 0 ? null : _start,
                        icon: const Icon(Icons.auto_awesome, size: 17),
                        label: Text(strings.viewYourStars),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.gold,
                          foregroundColor: colors.onGold,
                          disabledBackgroundColor: colors.crisisMuted.withValues(alpha: 0.15),
                          disabledForegroundColor: colors.crisisMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
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
  const _AreaChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Selection reads only through the icon and border going gold — the
    // background and text stay the same cool/muted colors as the
    // unselected state, so the chip row doesn't turn into a wall of yellow.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: selected ? colors.gold : colors.crisisMuted.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : (icon ?? Icons.circle_outlined),
              size: 16,
              color: selected ? colors.gold : colors.crisisMuted,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.crisisMuted,
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

/// A visually distinct stand-in for "select every area at once" — a compact,
/// centered switch rather than a full-width chip, even though toggling it
/// does exactly what tapping every area chip at once would
/// ([_AdmireStarsScreenState._toggleAll]). Hand-rolled instead of Flutter's
/// own [Switch]/[SwitchListTile] because both insist on expanding to fill
/// their row — there's no supported way to make them shrink to their content.
class _AllAreasSwitch extends StatelessWidget {
  const _AllAreasSwitch({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: value ? colors.gold : colors.crisisMuted.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colors.crisisMuted,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? colors.gold.withValues(alpha: 0.3) : colors.crisisMuted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: value ? colors.gold.withValues(alpha: 0.6) : colors.crisisMuted.withValues(alpha: 0.4),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: value ? colors.gold : colors.crisisMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cycles through [AppStrings.upliftingQuotes] on its own, one every 5
/// seconds — replaces what used to be a button pushing [EncouragementScreen]
/// with the quotes shown inline instead, right in the space below the area
/// chips.
class _UpliftingQuoteCarousel extends StatefulWidget {
  const _UpliftingQuoteCarousel();

  @override
  State<_UpliftingQuoteCarousel> createState() => _UpliftingQuoteCarouselState();
}

class _UpliftingQuoteCarouselState extends State<_UpliftingQuoteCarousel> {
  List<String>? _quotes;
  int _index = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Shuffled once, the first time build() runs with strings available —
    // not in initState, since AppStrings needs an InheritedWidget lookup.
    final quotes = _quotes ??= [...context.strings.upliftingQuotes]..shuffle();
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % quotes.length);
    });

    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // A soft scale-up alongside the fade — reads more clearly as
          // motion than a plain crossfade, while staying just as understated.
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(begin: 0.92, end: 1.0).animate(animation);
            return FadeTransition(opacity: animation, child: ScaleTransition(scale: scale, child: child));
          },
          child: Text(
            quotes[_index],
            key: ValueKey(_index),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: colors.crisisMuted,
            ),
          ),
        ),
      ),
    );
  }
}
