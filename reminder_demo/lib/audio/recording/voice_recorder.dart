import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

/// Records a short voice message into the app's Music/ReminderApp folder.
class VoiceRecorder {
  final Record _record = Record();
  final String recorderId = "main_recorder";

  /// Check microphone permission
  Future<bool> _checkPermission() async {
    return await _record.hasPermission(recorderId, request: true);
  }

  /// Start recording to a file
  Future<String?> startRecording() async {
    final hasPerm = await _checkPermission();
    if (!hasPerm) {
      throw Exception("Microphone permission not granted");
    }

    final folder = await AudioStorageManager.getReminderAudioFolder();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(folder.path, fileName);

    final config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
    );

    await _record.start(
      recorderId: recorderId,
      path: path,
      config: config,
    );

    return path;
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    return await _record.stop(recorderId);
  }

  /// Optional: start audio stream (waveform)
  Stream<Uint8List>? startStream() {
    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 44100,
      bitRate: 128000,
    );

    return _record.startStream(
      recorderId,
      config,
    );
  }

  /// Stop streaming
  Future<void> stopStream() async {
    await _record.stop(recorderId);
  }

  Future<void> dispose() async {
    await _record.dispose();
  }
}
