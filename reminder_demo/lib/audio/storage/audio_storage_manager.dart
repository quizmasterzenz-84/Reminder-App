import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Manages the app's dedicated folder for user-recorded voice reminders.
class AudioStorageManager {
  /// Returns (creating if necessary) `/storage/emulated/0/Music/ReminderApp/`.
  static Future<Directory> getReminderAudioFolder() async {
    try {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.music,
      );

      if (dirs != null && dirs.isNotEmpty) {
        final reminderDir = Directory('${dirs.first.path}/ReminderApp');
        await reminderDir.create(recursive: true);
        return reminderDir;
      }
    } catch (_) {
      // Fall through to app-private storage when external storage is unavailable.
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory('${appDir.path}/ReminderApp');
    await fallbackDir.create(recursive: true);
    return fallbackDir;
  }
}
