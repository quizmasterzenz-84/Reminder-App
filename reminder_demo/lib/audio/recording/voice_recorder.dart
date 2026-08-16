import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

/// Records a short voice message into the app's Music/ReminderApp folder.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String?> startRecording() async {
    if (await _recorder.hasPermission()) {
      final folder = await AudioStorageManager.getReminderAudioFolder();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = p.join(folder.path, fileName);

      await _recorder.start(const RecordConfig(), path: path);
      return path;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
