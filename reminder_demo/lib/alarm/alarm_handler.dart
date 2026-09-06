import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

/// Listens for firing alarms and plays the linked audio (recording/tone/picked file).
class AlarmHandler {
  static void registerAudioPath(int id, String? audioPath) {
    // AlarmSettings persists the path and the Android alarm service owns
    // playback. This method remains for the scheduler's lifecycle API.
  }

  static void initialize() {
    Alarm.ringStream.stream.listen((alarm) {
      debugPrint('AlarmHandler: native playback started for id=${alarm.id}');
    });
  }

  /// Stops any preview/alarm audio currently playing through this handler.
  static Future<void> stopActiveAudio() async {
    // Playback is owned by AlarmService and stopped by Alarm.stop(id).
  }
}
