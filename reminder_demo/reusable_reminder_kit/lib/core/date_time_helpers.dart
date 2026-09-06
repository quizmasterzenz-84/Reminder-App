// Pure date/time helpers with no reminder-specific knowledge and no
// external packages (deliberately not using `intl`, so this works fully
// offline with zero `pub get` network dependency).
//
// Reusable beyond this app: copy into any Dart or Flutter project.

/// True if [a] and [b] fall on the same calendar day (ignores time-of-day).
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Midnight at the start of the day containing [dateTime].
DateTime startOfDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

/// The last moment of the day containing [dateTime] (23:59:59.999).
DateTime endOfDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
}

/// Adds [months] calendar months to [date], clamping the day so an
/// end-of-month date (e.g. Jan 31) doesn't overflow into the wrong month
/// (e.g. it becomes Feb 28/29, not Mar 3).
DateTime addMonthsClamped(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final daysInTargetMonth = _daysInMonth(year, month);
  final day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;
  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  );
}

/// Adds [years] calendar years to [date], clamping Feb 29 -> Feb 28 on
/// non-leap target years (so a Feb 29 birthday still fires every year).
DateTime addYearsClamped(DateTime date, int years) {
  final targetYear = date.year + years;
  final daysInTargetMonth = _daysInMonth(targetYear, date.month);
  final day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;
  return DateTime(
    targetYear,
    date.month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  );
}

int _daysInMonth(int year, int month) {
  // Day 0 of next month = last day of this month.
  final firstOfNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

/// Minimal, dependency-free "13 Aug 2026" style formatter, so callers
/// don't need the `intl` package just to show a date in a list tile.
String formatShortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Minimal "13 Aug 2026, 14:05" formatter for notification bodies.
String formatShortDateTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${formatShortDate(date)}, $hh:$mm';
}
