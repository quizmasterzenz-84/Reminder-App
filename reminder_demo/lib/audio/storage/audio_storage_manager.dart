import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Manages the app's dedicated folder for user-recorded voice reminders.
class AudioStorageManager {
  /// Returns (creating if necessary) `/storage/emulated/0/Music/ReminderApp/`.
  static Future<Directory> getReminderAudioFolder() async {
    final dirs = await getExternalStorageDirectories(
      type: StorageDirectory.music,
    );

    if (dirs == null || dirs.isEmpty) {
      // Fallback for platforms/emulators without a Music directory (e.g. desktop/test).
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory('${appDir.path}/ReminderApp');
      if (!fallbackDir.existsSync()) {
        fallbackDir.createSync(recursive: true);
      }
      return fallbackDir;
    }

    final musicDir = dirs.first;
    final reminderDir = Directory('${musicDir.path}/ReminderApp');

    if (!reminderDir.existsSync()) {
      reminderDir.createSync(recursive: true);
    }

    return reminderDir;
  }
}
