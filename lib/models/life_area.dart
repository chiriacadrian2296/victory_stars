import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// The 8 fixed areas of life a [Project] (and, through it, every [Win]) can
/// belong to. Fixed and closed — not user-extensible.
enum LifeArea {
  physical,
  psychological,
  professional,
  financial,
  personal,
  social,
  spiritual,
  philanthropic,
}

extension LifeAreaX on LifeArea {
  /// Localized name for this area. Takes [AppStrings] rather than reading
  /// it off a [BuildContext] itself, since an enum extension has no context
  /// of its own — call sites already have one via `context.strings`.
  String displayName(AppStrings s) {
    switch (this) {
      case LifeArea.physical:
        return s.areaPhysical;
      case LifeArea.psychological:
        return s.areaPsychological;
      case LifeArea.professional:
        return s.areaProfessional;
      case LifeArea.financial:
        return s.areaFinancial;
      case LifeArea.personal:
        return s.areaPersonal;
      case LifeArea.social:
        return s.areaSocial;
      case LifeArea.spiritual:
        return s.areaSpiritual;
      case LifeArea.philanthropic:
        return s.areaPhilanthropic;
    }
  }

  /// A generic icon representing the area itself — distinct from a
  /// project's own [Project.iconSlug]-based constellation icon, and
  /// deliberately never offered as a project icon choice (see [iconSlug])
  /// so the two never get visually confused. Used wherever an area is
  /// shown as a single UI element (the Sky hub cards, the area picker when
  /// creating a project) rather than browsed into.
  IconData get icon {
    switch (this) {
      case LifeArea.physical:
        return Icons.fitness_center;
      case LifeArea.psychological:
        return Icons.psychology;
      case LifeArea.professional:
        return Icons.work;
      case LifeArea.financial:
        return Icons.savings;
      case LifeArea.personal:
        return Icons.self_improvement;
      case LifeArea.social:
        return Icons.groups;
      case LifeArea.spiritual:
        return Icons.all_inclusive;
      case LifeArea.philanthropic:
        return Icons.volunteer_activism;
    }
  }

  /// The slug equivalent of [icon]. Most of these also happen to be keys in
  /// `constellation_shapes_v2.dart` (same icon, same name) — this getter is
  /// what lets the project icon picker filter them out, reserving them for
  /// areas only. `self_improvement` isn't in that shape library at all, so
  /// it was never selectable as a project icon regardless.
  String get iconSlug {
    switch (this) {
      case LifeArea.physical:
        return 'fitness_center';
      case LifeArea.psychological:
        return 'psychology';
      case LifeArea.professional:
        return 'work';
      case LifeArea.financial:
        return 'savings';
      case LifeArea.personal:
        return 'self_improvement';
      case LifeArea.social:
        return 'groups';
      case LifeArea.spiritual:
        return 'all_inclusive';
      case LifeArea.philanthropic:
        return 'volunteer_activism';
    }
  }

  /// Key into `suggestedIconsByArea` (constellation_shapes_v2.dart). Kept
  /// separate from [name] because that map spells this area
  /// "philanthropical", not "philanthropic".
  String get suggestedIconsKey {
    switch (this) {
      case LifeArea.philanthropic:
        return 'philanthropical';
      default:
        return name;
    }
  }
}
