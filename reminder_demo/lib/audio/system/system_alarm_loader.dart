import 'dart:io';

/// Loads the read-only system alarm tones bundled with the OS (same as the Clock app).
class SystemAlarmLoader {
  static const List<String> _systemDirs = [
    '/system/media/audio/alarms',
    '/product/media/audio/alarms',
    '/system/media/audio/ringtones',
    '/product/media/audio/ringtones',
  ];

  static Future<List<FileSystemEntity>> loadSystemAlarmTones() async {
    final tones = <FileSystemEntity>[];

    for (final dir in _systemDirs) {
      try {
        final directory = Directory(dir);
        if (directory.existsSync()) {
          tones.addAll(directory.listSync());
        }
      } catch (_) {
        // Ignore inaccessible or unsupported system folders.
      }
    }

    return tones;
  }
}
