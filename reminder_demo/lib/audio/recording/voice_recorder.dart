import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> _checkPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String?> startRecording() async {
    final hasPerm = await _checkPermission();
    if (!hasPerm) {
      throw Exception("Microphone permission not granted");
    }

    final folder = await AudioStorageManager.getReminderAudioFolder();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(folder.path, fileName);

    // record v3.x only accepts ONE positional argument: the file path
    await _recorder.start(path);

    return path;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<Stream<Uint8List>?> startStream() async {
    // record v3.x: startStream() has NO parameters
    return await _recorder.startStream();
  }

  Future<void> stopStream() async {
    await _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
