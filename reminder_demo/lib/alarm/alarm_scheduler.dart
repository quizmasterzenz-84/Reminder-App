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

      // Audio file (user‑recorded or default)
      assetAudioPath: audioPath ?? "",

      // Play the selected recording/file once, then let the alarm finish.
      loopAudio: false,
      vibrate: true,
      volume: 0.8,

      // Required in alarm v3.x
      notificationTitle: "Reminder",
      notificationBody: "Your reminder is ringing",

      // Android: full-screen intent (wakes device from sleep)
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelReminder(int id) async {
    await Alarm.stop(id);
  }
}
