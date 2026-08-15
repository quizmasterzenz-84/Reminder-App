import 'package:flutter/material.dart';
import '../core/importance.dart';
import '../core/date_time_helpers.dart';
import 'importance_color_tag.dart';

/// Two-line list row: "[Category • Importance] Title" then
/// "Next: date • Final: date • Snooze: option" — used identically on the
/// Home, See All, and Archive screens (\u00a77, \u00a711), so it's built once here.
///
/// Reusable beyond this app: generalises to any tagged, dated list row
/// (tasks, invoices, appointments) by swapping the field names.
class ReminderListTile extends StatelessWidget {
  final String category;
  final Importance importance;
  final String title;
  final DateTime? nextTriggerTime;
  final DateTime? finalTime;
  final String? snoozeLabel;
  final VoidCallback? onTap;

  /// True once [nextTriggerTime] has passed. Callers decide "now" (e.g. via
  /// a periodic timer) so this widget stays a pure function of its inputs.
  final bool isDue;

  const ReminderListTile({
    super.key,
    required this.category,
    required this.importance,
    required this.title,
    this.nextTriggerTime,
    this.finalTime,
    this.snoozeLabel,
    this.onTap,
    this.isDue = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (nextTriggerTime != null)
        'Next: ${formatShortDateTime(nextTriggerTime!)}',
      if (finalTime != null) 'Final: ${formatShortDate(finalTime!)}',
      if (snoozeLabel != null) 'Snooze: $snoozeLabel',
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          ImportanceColorTag(importance: importance),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$category \u2022 $title',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Due now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: parts.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                parts.join(' \u2022 '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
    );
  }
}
