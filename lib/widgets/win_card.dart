import 'package:flutter/material.dart';

import '../models/win.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';

class WinCard extends StatelessWidget {
  const WinCard({super.key, required this.win});

  final Win win;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.nightPanel,
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
    );
  }
}
