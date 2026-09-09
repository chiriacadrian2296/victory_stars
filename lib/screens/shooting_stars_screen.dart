import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import 'placeholder_screen.dart';

/// A wish, timed. The concept: spot a shooting star crossing the sky,
/// make a wish, then chase it — a small effort against a real deadline
/// (today, five hours, whatever the user sets), rewarded if caught in
/// time. None of that exists yet — this is the menu entry for it, wired
/// to [PlaceholderScreen] until the underlying system (and the button's
/// own shimmer/countdown, once a shooting star is actually live) is built.
class ShootingStarsScreen extends StatelessWidget {
  const ShootingStarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return PlaceholderScreen(
      icon: Icons.auto_fix_high,
      title: strings.menuShootingStars,
      body: strings.shootingStarsBody,
    );
  }
}
