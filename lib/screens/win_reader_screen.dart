import 'package:flutter/material.dart';

import '../data/win_repository.dart';
import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import 'add_win_screen.dart';

/// Shows one win at a time, with looping prev/next navigation.
///
/// Used two ways:
/// - From the crisis intro, browsing everything starting at the most
///   recent win ([allowEdit] false — pure reflection, no editing).
/// - From a tap on a specific card in the home list, starting at that win
///   ([allowEdit] true — adds an edit button that reuses [AddWinScreen]).
class WinReaderScreen extends StatefulWidget {
  const WinReaderScreen({
    super.key,
    required this.repository,
    required this.initialWins,
    required this.startIndex,
    this.allowEdit = false,
  });

  final WinRepository repository;
  final List<Win> initialWins;
  final int startIndex;
  final bool allowEdit;

  @override
  State<WinReaderScreen> createState() => _WinReaderScreenState();
}

class _WinReaderScreenState extends State<WinReaderScreen> {
  late List<Win> _wins = widget.initialWins;
  late int _index = widget.startIndex;

  void _showPrevious() {
    setState(() => _index = (_index - 1 + _wins.length) % _wins.length);
  }

  void _showNext() {
    setState(() => _index = (_index + 1) % _wins.length);
  }

  Future<void> _editCurrent() async {
    final current = _wins[_index];
    final result = await Navigator.of(context).push<AddWinResult>(
      MaterialPageRoute(builder: (_) => AddWinScreen(existingWin: current)),
    );
    if (result == null) return;

    final updated = await widget.repository.update(
      id: current.id,
      title: result.title,
      description: result.description,
    );
    setState(() {
      _wins = widget.repository.getAll();
      _index = _wins.indexWhere((w) => w.id == updated.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final win = _wins[_index];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.crisisGradient),
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
                      icon: const Icon(Icons.close, color: AppColors.crisisMuted),
                    ),
                    Text(
                      '${_index + 1} of ${_wins.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.crisisMuted),
                    ),
                    if (widget.allowEdit)
                      IconButton(
                        onPressed: _editCurrent,
                        icon: const Icon(Icons.edit_outlined, color: AppColors.crisisMuted),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 30, color: AppColors.gold),
                          const SizedBox(height: 20),
                          Text(
                            formatDisplayDate(win.date),
                            style: const TextStyle(fontSize: 12, color: AppColors.crisisMuted),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            win.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: AppColors.text,
                            ),
                          ),
                          if (win.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              win.description!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.crisisMuted,
                              ),
                            ),
                          ],
                        ],
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
          child: Icon(icon, color: AppColors.text),
        ),
      ),
    );
  }
}
