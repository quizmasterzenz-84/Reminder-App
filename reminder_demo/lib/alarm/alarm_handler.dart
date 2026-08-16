import 'package:alarm/alarm.dart';

import '../audio/playback/alarm_audio_player.dart';

/// Listens for firing alarms and plays the linked audio (recording/tone/picked file).
class AlarmHandler {
  static AlarmAudioPlayer? _activePlayer;

  static void initialize() {
    Alarm.onAlarm.listen((alarm) {
      final audioPath = alarm.settings.assetAudioPath;
      if (audioPath != null) {
        _activePlayer?.dispose();
        _activePlayer = AlarmAudioPlayer();
        _activePlayer!.play(audioPath);
      }
    });
  }

  /// Stops any preview/alarm audio currently playing through this handler.
  static Future<void> stopActiveAudio() async {
    await _activePlayer?.stop();
    _activePlayer?.dispose();
    _activePlayer = null;
  }
}
