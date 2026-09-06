import 'package:alarm/alarm.dart';

import 'alarm_handler.dart';
import '../audio/system/system_alarm_loader.dart';

/// Schedules a native alarm (survives app kill, shows full-screen intent) for a reminder.
class AlarmScheduler {
  static Future<void> scheduleReminder({
    required int id,
    required DateTime dateTime,
    String? audioPath,
  }) async {
    var resolvedAudioPath = audioPath;
    if (resolvedAudioPath == null || resolvedAudioPath.isEmpty) {
      try {
        final tones = await SystemAlarmLoader.loadSystemAlarmTones();
        if (tones.isNotEmpty) resolvedAudioPath = tones.first.path;
      } catch (_) {
        // The reminder can still be scheduled as a notification.
      }
    }

    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,

      // The alarm plugin accepts bundled assets only. Flutter plays the
      // selected device file after ringStream fires.
      assetAudioPath: "",

      // Play the selected recording/file once, then let the alarm finish.
      loopAudio: false,
      // Avoid a repeating native vibration while Flutter plays device audio.
      vibrate: false,
      volume: 0.8,

      // Required in alarm v3.x
      notificationTitle: "Reminder",
      notificationBody: "Your reminder is ringing",

      // Android: full-screen intent (wakes device from sleep)
      androidFullScreenIntent: true,
    );

    AlarmHandler.registerAudioPath(id, resolvedAudioPath);
    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelReminder(int id) async {
    AlarmHandler.registerAudioPath(id, null);
    await AlarmHandler.stopActiveAudio();
    await Alarm.stop(id);
  }
}
