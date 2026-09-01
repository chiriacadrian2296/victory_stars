import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';

/// When this card's underlying star/habit was created — the one date every
/// kind actually has (achieved/target/death dates are each kind-specific,
/// but creation isn't), shown at the bottom of every card. Time sits on
/// its own line below the date rather than beside it, each with its own
/// icon.
class StarCreatedAt extends StatelessWidget {
  const StarCreatedAt({super.key, required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 12, color: colors.muted),
              const SizedBox(width: 5),
              Text(
                '${strings.createdLabel} ${formatDisplayDate(createdAt, strings)}',
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 12, color: colors.muted),
              const SizedBox(width: 5),
              Text(
                formatDisplayTime(createdAt),
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
