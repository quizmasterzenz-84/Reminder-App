// Pure recurrence-calculation logic. Given "when did it last trigger" and
// "what's the rule", returns "when should it trigger next" — nothing here
// knows what a reminder is, so it's the most reusable piece in the app.
//
// Reusable beyond this app: any scheduling feature (habit tracker, medication
// log, subscription renewal tracker) can import this file unchanged.

import '../core/date_time_helpers.dart';

enum RecurrenceType { none, yearly, monthly, customIntervalDays }

/// Immutable description of how a reminder repeats.
class RecurrenceRule {
  final RecurrenceType type;

  /// Only used when [type] is [RecurrenceType.customIntervalDays].
  final int? intervalDays;

  const RecurrenceRule.none()
      : type = RecurrenceType.none,
        intervalDays = null;

  const RecurrenceRule.yearly()
      : type = RecurrenceType.yearly,
        intervalDays = null;

  const RecurrenceRule.monthly()
      : type = RecurrenceType.monthly,
        intervalDays = null;

  const RecurrenceRule.customDays(int days)
      : type = RecurrenceType.customIntervalDays,
        intervalDays = days,
        assert(days > 0, 'intervalDays must be positive');
}

/// Computes the next trigger time given the [lastTriggerTime] and [rule].
///
/// - [RecurrenceType.none] -> always returns null (one-off reminder, closes
///   after its final trigger — see \u00a78 "on_final_day" in the spec).
/// - [RecurrenceType.yearly] / [monthly] -> clamped so end-of-month / Feb 29
///   dates roll forward sensibly every cycle (birthdays, MOT renewals).
/// - [RecurrenceType.customIntervalDays] -> simple fixed-day interval.
///
/// If [notAfter] is supplied and the computed next trigger would fall after
/// it, this returns null (the series has run out, matches "final_time" as an
/// optional upper bound for a recurring reminder rather than a hard single
/// deadline — see the app's \u00a74.1 recurrence_rule field).
DateTime? computeNextTrigger(
  DateTime lastTriggerTime,
  RecurrenceRule rule, {
  DateTime? notAfter,
}) {
  DateTime? next;
  switch (rule.type) {
    case RecurrenceType.none:
      return null;
    case RecurrenceType.yearly:
      next = addYearsClamped(lastTriggerTime, 1);
      break;
    case RecurrenceType.monthly:
      next = addMonthsClamped(lastTriggerTime, 1);
      break;
    case RecurrenceType.customIntervalDays:
      next = DateTime(
        lastTriggerTime.year,
        lastTriggerTime.month,
        lastTriggerTime.day + rule.intervalDays!,
        lastTriggerTime.hour,
        lastTriggerTime.minute,
        lastTriggerTime.second,
        lastTriggerTime.millisecond,
        lastTriggerTime.microsecond,
      );
      break;
  }

  if (notAfter != null && next.isAfter(notAfter)) {
    return null;
  }
  return next;
}
