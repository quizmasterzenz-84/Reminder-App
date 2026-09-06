import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

import '../audio/playback/alarm_audio_player.dart';

/// Listens for firing alarms and plays the linked audio (recording/tone/picked file).
class AlarmHandler {
  static AlarmAudioPlayer? _activePlayer;
  static final Map<int, String> _audioPaths = {};

  static void registerAudioPath(int id, String? audioPath) {
    if (audioPath == null || audioPath.isEmpty) {
      _audioPaths.remove(id);
    } else {
      _audioPaths[id] = audioPath;
    }
  }

  static void initialize() {
    Alarm.ringStream.stream.listen((alarm) async {
      final audioPath = _audioPaths[alarm.id];
      _audioPaths.remove(alarm.id);

      // The alarm plugin expects a bundled asset, not an arbitrary device
      // path. Play the selected file ourselves and stop the native service
      // in parallel so file loading does not add extra ringing delay.
      if (audioPath == null || audioPath.isEmpty) {
        await Alarm.stop(alarm.id);
        return;
      }

      await stopActiveAudio();
      final player = AlarmAudioPlayer();
      _activePlayer = player;
      try {
        await Future.wait([
          player.play(audioPath),
          Alarm.stop(alarm.id),
        ]);
      } catch (error) {
        // The notification still informs the user if the file is unavailable.
        debugPrint('AlarmHandler: unable to play $audioPath: $error');
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
