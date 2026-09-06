import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads the read-only system alarm tones bundled with the OS (same as the Clock app).
class SystemAlarmLoader {
  static const MethodChannel _channel = MethodChannel(
    'reminder_demo/system_alarms',
  );

  static const List<String> _systemDirs = [
    '/system/media/audio/alarms',
    '/product/media/audio/alarms',
    '/system/media/audio/ringtones',
    '/product/media/audio/ringtones',
  ];

  static const List<String> _allowedExtensions = [
    '.mp3',
    '.ogg',
    '.wav',
    '.m4a',
    '.aac',
  ];

  static Future<List<FileSystemEntity>> loadSystemAlarmTones() async {
    if (Platform.isAndroid) {
      try {
        final nativePaths = await _channel.invokeMethod<List<dynamic>>(
          'getSystemAlarmTones',
        );
        final tones = nativePaths
                ?.whereType<String>()
                .map<FileSystemEntity>(File.new)
                .toList() ??
            <FileSystemEntity>[];
        if (tones.isNotEmpty) return tones;
      } on PlatformException catch (error) {
        debugPrint('SystemAlarmLoader: Android provider unavailable: $error');
      } on MissingPluginException {
        // Keep the filesystem fallback for non-Android test environments.
      }
    }

    final tones = <FileSystemEntity>[];

    for (final dir in _systemDirs) {
      try {
        final directory = Directory(dir);

        if (!directory.existsSync()) {
          continue;
        }

        final files = directory.listSync();

        for (final file in files) {
          if (file is File) {
            final ext = file.path.toLowerCase();
            if (_allowedExtensions.any((e) => ext.endsWith(e))) {
              tones.add(file);
            }
          }
        }
      } catch (e) {
        // Ignore inaccessible or unsupported system folders.
        debugPrint('SystemAlarmLoader: Cannot read $dir → $e');
      }
    }

    return tones;
  }
}
