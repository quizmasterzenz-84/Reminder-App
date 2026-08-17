import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  final String _id = "main";   // recorderId required in record 5.x

  Future<bool> _checkPermission() async {
    try {
      return await _recorder.hasPermission(_id);
    } catch (_) {
      return false;
    }
  }

  Future<String?> startRecording() async {
    final hasPerm = await _checkPermission();
    if (!hasPerm) {
      throw Exception("Microphone permission not granted");
    }

    final folder = await AudioStorageManager.getReminderAudioFolder();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(folder.path, fileName);

    try {
      await _recorder.start(path);   // record 5.x API
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      await _recorder.stop(_id);     // record 5.x API
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<Uint8List>? startStream() {
    try {
      return _recorder.startStream(
        _id,
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
      );   // record 5.x API
    } catch (_) {
      return null;
    }
  }

  Future<void> stopStream() async {
    try {
      await _recorder.stop(_id);     // record 5.x API
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
  }
}
