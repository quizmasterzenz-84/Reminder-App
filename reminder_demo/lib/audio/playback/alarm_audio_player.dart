import 'package:just_audio/just_audio.dart';

/// Plays a local audio file (used for previewing tones/recordings/picks).
class AlarmAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
