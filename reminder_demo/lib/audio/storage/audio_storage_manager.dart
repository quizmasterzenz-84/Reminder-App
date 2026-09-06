import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the app's dedicated folder for user-recorded voice reminders.
class AudioStorageManager {
  static const MethodChannel _exportChannel = MethodChannel(
    'reminder_demo/audio_export',
  );

  static Future<bool> exportToPublicMusic(String path) async {
    try {
      return await _exportChannel.invokeMethod<bool>('exportToPublicMusic', {
            'path': path,
            'displayName': path.split('/').last,
          }) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('Audio export unavailable: $error');
      return false;
    }
  }

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
