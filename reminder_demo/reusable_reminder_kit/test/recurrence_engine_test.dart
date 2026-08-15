// Run with: flutter test test/recurrence_engine_test.dart
// (No network/pub packages beyond flutter_test are needed — fully offline.)

import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_reminder_kit/core/date_time_helpers.dart';
import 'package:reusable_reminder_kit/recurrence/recurrence_engine.dart';

void main() {
  group('addYearsClamped', () {
    test('rolls Feb 29 (leap) forward to Feb 28 on a non-leap target year', () {
      final result = addYearsClamped(DateTime(2028, 2, 29, 9, 0), 1);
      expect(result, DateTime(2029, 2, 28, 9, 0));
    });

    test('keeps Feb 29 on another leap year 4 years later', () {
      final result = addYearsClamped(DateTime(2028, 2, 29, 9, 0), 4);
      expect(result, DateTime(2032, 2, 29, 9, 0));
    });

    test('normal date just adds the year', () {
      final result = addYearsClamped(DateTime(2025, 8, 13, 10, 30), 1);
      expect(result, DateTime(2026, 8, 13, 10, 30));
    });
  });

  group('addMonthsClamped', () {
    test('Jan 31 + 1 month clamps to Feb 28 in a non-leap year', () {
      final result = addMonthsClamped(DateTime(2027, 1, 31, 8, 0), 1);
      expect(result, DateTime(2027, 2, 28, 8, 0));
    });

    test('Jan 31 + 1 month clamps to Feb 29 in a leap year', () {
      final result = addMonthsClamped(DateTime(2028, 1, 31, 8, 0), 1);
      expect(result, DateTime(2028, 2, 29, 8, 0));
    });

    test('rolls over into the next year', () {
      final result = addMonthsClamped(DateTime(2026, 12, 15, 8, 0), 1);
      expect(result, DateTime(2027, 1, 15, 8, 0));
    });
  });

  group('computeNextTrigger', () {
    test('RecurrenceType.none always returns null', () {
      final result = computeNextTrigger(DateTime(2026, 8, 13), const RecurrenceRule.none());
      expect(result, isNull);
    });

    test('yearly reschedules the reminder one year later', () {
      final result = computeNextTrigger(DateTime(2026, 8, 13), const RecurrenceRule.yearly());
      expect(result, DateTime(2027, 8, 13));
    });

    test('monthly reschedules one month later', () {
      final result = computeNextTrigger(DateTime(2026, 8, 13), const RecurrenceRule.monthly());
      expect(result, DateTime(2026, 9, 13));
    });

    test('customIntervalDays reschedules by the given number of days', () {
      final result = computeNextTrigger(
        DateTime(2026, 8, 13),
        const RecurrenceRule.customDays(90),
      );
      expect(result, DateTime(2026, 11, 11));
    });

    test('returns null once the next occurrence would pass notAfter', () {
      final result = computeNextTrigger(
        DateTime(2030, 8, 13),
        const RecurrenceRule.yearly(),
        notAfter: DateTime(2031, 1, 1),
      );
      expect(result, isNull);
    });

    test('still returns a date when it falls before notAfter', () {
      final result = computeNextTrigger(
        DateTime(2026, 8, 13),
        const RecurrenceRule.yearly(),
        notAfter: DateTime(2030, 1, 1),
      );
      expect(result, DateTime(2027, 8, 13));
    });
  });

  group('formatShortDate / formatShortDateTime', () {
    test('formats a date without needing the intl package', () {
      expect(formatShortDate(DateTime(2026, 8, 13)), '13 Aug 2026');
    });

    test('formats a date+time and pads single-digit minutes/hours', () {
      expect(formatShortDateTime(DateTime(2026, 8, 13, 9, 5)), '13 Aug 2026, 09:05');
    });
  });
}
