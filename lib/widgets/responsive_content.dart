import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// The shared column width every screen caps at on wide viewports — one
/// constant (not per-screen tuning) so the app reads as one coherent web
/// app rather than each page picking its own width.
const double kResponsiveContentMaxWidth = 720;

/// No-op on narrow viewports (renders [child] unchanged — zero risk to the
/// phone layout). On wide viewports, centers [child] in a column capped at
/// [maxWidth] so text/forms/lists don't stretch edge-to-edge in a browser
/// or desktop window.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = kResponsiveContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!isWideLayout(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
