import 'dart:io';

/// Loads the read-only system alarm tones bundled with the OS (same as the Clock app).
class SystemAlarmLoader {
  static const List<String> _systemDirs = [
    '/system/media/audio/alarms',
    '/product/media/audio/alarms',
  ];

  static Future<List<FileSystemEntity>> loadSystemAlarmTones() async {
    final tones = <FileSystemEntity>[];

    for (final dir in _systemDirs) {
      final directory = Directory(dir);
      if (directory.existsSync()) {
        tones.addAll(directory.listSync());
      }
    }

    return tones;
  }
}
