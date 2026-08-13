import 'package:flutter/material.dart';

/// Generic priority/severity level — not reminder-specific. Any app that
/// needs a red/blue/green (or similar) tiering can reuse this enum and
/// its colour mapping instead of re-inventing it per feature.
enum Importance { high, medium, low }

extension ImportanceX on Importance {
  /// Colour used across list tiles, tags, and creation forms.
  /// Centralised here so changing the palette is a one-line edit.
  Color get color {
    switch (this) {
      case Importance.high:
        return const Color(0xFFC62828); // red
      case Importance.medium:
        return const Color(0xFF1565C0); // blue
      case Importance.low:
        return const Color(0xFF2E7D32); // green
    }
  }

  String get label {
    switch (this) {
      case Importance.high:
        return 'High';
      case Importance.medium:
        return 'Medium';
      case Importance.low:
        return 'Low';
    }
  }
}
