import 'package:flutter/material.dart';

import '../widgets/nebula_background.dart';

/// A dedicated tab for `NebulaBackground` — full-bleed, drag to pan and
/// pinch to zoom. Still exploratory (no other content yet, nothing else in
/// the app links here besides the tab itself) — a place to look at and
/// react to before deciding whether it grows into something more.
class NebulaScreen extends StatelessWidget {
  const NebulaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: NebulaBackground(interactive: true));
  }
}
