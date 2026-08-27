import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';

/// A quiet, one-at-a-time browse through a fixed set of short uplifting
/// phrases (see [AppStrings.upliftingQuotes]) — an alternative to browsing
/// actual wins from [AdmireStarsScreen], for moments when there's nothing
/// to look back on yet, or the wins themselves aren't what's needed right
/// now. Shuffled once per visit, not editable — there's nothing to edit.
class EncouragementScreen extends StatefulWidget {
  const EncouragementScreen({super.key});

  @override
  State<EncouragementScreen> createState() => _EncouragementScreenState();
}

class _EncouragementScreenState extends State<EncouragementScreen> {
  List<String>? _quotes;
  int _index = 0;

  void _showPrevious() {
    final quotes = _quotes!;
    setState(() => _index = (_index - 1 + quotes.length) % quotes.length);
  }

  void _showNext() {
    final quotes = _quotes!;
    setState(() => _index = (_index + 1) % quotes.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Shuffled once, the first time build() runs with strings available —
    // not in initState, since AppStrings needs an InheritedWidget lookup.
    final quotes = _quotes ??= [...context.strings.upliftingQuotes]..shuffle();
    final quote = quotes[_index];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.crisisGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colors.crisisMuted),
                    ),
                    Text(
                      context.strings.indexOfCount(_index + 1, quotes.length),
                      style: TextStyle(fontSize: 12, color: colors.crisisMuted),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        quote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavCircleButton(icon: Icons.chevron_left, onTap: _showPrevious),
                    _NavCircleButton(icon: Icons.chevron_right, onTap: _showNext),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: context.colors.text),
        ),
      ),
    );
  }
}
