import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Manages the app's dedicated folder for user-recorded voice reminders.
class AudioStorageManager {
  /// Returns internal app storage for reliable background alarm playback.
  /// A separate MediaStore export makes a user-visible copy in Music/ReminderApp.
  static Future<Directory> getReminderAudioFolder() async {
    final appDir = await getApplicationDocumentsDirectory();
    final reminderDir = Directory('${appDir.path}/ReminderApp');

    if (!reminderDir.existsSync()) {
      await reminderDir.create(recursive: true);
    }

    return reminderDir;
  }
}
