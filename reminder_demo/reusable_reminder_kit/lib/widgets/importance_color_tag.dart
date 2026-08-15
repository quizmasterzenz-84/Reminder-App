import 'package:flutter/material.dart';
import '../core/importance.dart';

/// Small colour-coded pill, e.g. "High" in red, "Medium" in blue,
/// "Low" in green. Used in list tiles, the creation form, and the
/// category screen — anywhere an importance/priority needs to be shown.
///
/// Reusable beyond this app: works for any priority/severity/status tag.
class ImportanceColorTag extends StatelessWidget {
  final Importance importance;

  /// Override the text shown (defaults to importance.label, e.g. "High").
  final String? label;

  const ImportanceColorTag({
    super.key,
    required this.importance,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Colour alone should never be the only signal (accessibility, \u00a711).
      label: '${importance.label} importance',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: importance.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label ?? importance.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
