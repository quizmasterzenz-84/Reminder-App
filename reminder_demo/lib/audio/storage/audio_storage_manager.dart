import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the app's dedicated folder for user-recorded voice reminders.
class AudioStorageManager {
  /// Returns (creating if necessary) `/storage/emulated/0/Music/ReminderApp/`.
  static Future<Directory> getReminderAudioFolder() async {
    try {
      // Android public Music directory (universal across all devices)
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.music,
      );

      if (dirs != null && dirs.isNotEmpty) {
        final reminderDir = Directory('${dirs.first.path}/ReminderApp');

        if (!reminderDir.existsSync()) {
          await reminderDir.create(recursive: true);
        }

        return reminderDir;
      }
    } catch (e) {
      // Fall through to private storage if external storage is unavailable
      debugPrint('External Music directory unavailable: $e');
    }

    // Fallback: app-private storage (emulators, desktop, restricted devices)
    final appDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${appDir.path}/ReminderApp');

    if (!fallbackDir.existsSync()) {
      await fallbackDir.create(recursive: true);
    }

    return fallbackDir;
  }
}
