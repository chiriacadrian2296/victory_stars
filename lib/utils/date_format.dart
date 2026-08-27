const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date as e.g. "26 Aug 2026".
String formatDisplayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _months[date.month - 1];
  return '$day $month ${date.year}';
}

/// Formats a time as e.g. "14:32" (24-hour, no AM/PM ambiguity to localize).
String formatDisplayTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Formats a date and time as e.g. "26 Aug 2026 · 14:32".
String formatDisplayDateTime(DateTime date) {
  return '${formatDisplayDate(date)} · ${formatDisplayTime(date)}';
}
