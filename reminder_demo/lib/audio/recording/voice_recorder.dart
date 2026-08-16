import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

/// Records a short voice message into the app's Music/ReminderApp folder.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  final String recorderId = "main_recorder";

  /// Check microphone permission
  Future<bool> _checkPermission() async {
    return await _recorder.hasPermission(recorderId, request: true);
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

    await _recorder.start(
      recorderId,
      path,
      config,
    );

    return path;
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    return await _recorder.stop(recorderId);
  }

  /// Optional: start audio stream (waveform)
  Stream<Uint8List>? startStream() {
    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 44100,
      bitRate: 128000,
    );

    return _recorder.startStream(
      recorderId,
      config,
    );
  }

  /// Stop streaming
  Future<void> stopStream() async {
    await _recorder.stop(recorderId);
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
