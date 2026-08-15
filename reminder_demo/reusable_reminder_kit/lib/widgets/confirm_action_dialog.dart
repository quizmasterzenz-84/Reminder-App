import 'package:flutter/material.dart';

/// Shows a confirm/cancel dialog and resolves `true` only if the user taps
/// the confirm button. Used for deleting a reminder, deleting a category,
/// clearing the archive, and wiping app data (\u00a712.5) — one place to keep
/// the wording and styling of every destructive action consistent.
///
/// Reusable beyond this app: any app needing a destructive-action
/// confirmation can call this unchanged.
Future<bool> showConfirmActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red.shade700 : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
