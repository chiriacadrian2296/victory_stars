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
