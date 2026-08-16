import 'package:alarm/alarm.dart';

/// Schedules a native alarm (survives app kill, shows full-screen intent) for a reminder.
class AlarmScheduler {
  static Future<void> scheduleReminder({
    required int id,
    required DateTime dateTime,
    String? audioPath,
  }) async {
    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath, // null falls back to the plugin's default tone
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelReminder(int id) async {
    await Alarm.stop(id);
  }
}
