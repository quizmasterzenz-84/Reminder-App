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

    final nativeAudioPath = resolvedAudioPath ?? 'assets/not_blank.mp3';
    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,

      // alarm 3.1.7's Android service supports both bundled assets and
      // absolute device paths. Native playback keeps working if Flutter is
      // backgrounded or the app process is not running.
      assetAudioPath: nativeAudioPath,

      // Play the selected recording/file once, then let the alarm finish.
      loopAudio: false,
      // With loopAudio=false the plugin stops vibration when playback ends.
      vibrate: true,
      volume: 0.8,

      // Required in alarm v3.x
      notificationTitle: "Reminder",
      notificationBody: "Your reminder is ringing",

      // Android: full-screen intent (wakes device from sleep)
      androidFullScreenIntent: true,
    );

    AlarmHandler.registerAudioPath(id, nativeAudioPath);
    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelReminder(int id) async {
    AlarmHandler.registerAudioPath(id, null);
    await AlarmHandler.stopActiveAudio();
    await Alarm.stop(id);
  }
}
