import 'package:flutter/material.dart';

import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';

class WinCard extends StatelessWidget {
  const WinCard({super.key, required this.win, this.onTap, this.projectLabel});

  final Win win;
  final VoidCallback? onTap;

  /// The win's project name, shown as light context now that Home's list
  /// spans every project. Null when the project can't be resolved (e.g.
  /// stale data) — the card still renders fine without it.
  final String? projectLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nightPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.nightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(
                    formatDisplayDate(win.date),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (projectLabel != null) ...[
                    const Text(' · ', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Expanded(
                      child: Text(
                        projectLabel!,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                win.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  color: AppColors.text,
                ),
              ),
              if (win.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  win.description!,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
