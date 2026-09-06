import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../storage/audio_storage_manager.dart';

class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> _checkPermission() async {
    try {
      return await _recorder.hasPermission(request: true);
    } catch (_) {
      return false;
    }
  }

  Future<String?> startRecording() async {
    final stopwatch = Stopwatch()..start();
    final hasPerm = await _checkPermission();
    if (!hasPerm) {
      throw Exception("Microphone permission not granted");
    }

    // Prevent double-start crash
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    final folder = await AudioStorageManager.getReminderAudioFolder();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // WAV starts reliably across Android devices and avoids an AAC encoder
    // negotiation timeout before recording begins.
    try {
      final path = p.join(folder.path, 'voice_$timestamp.wav');
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
        ),
        path: path,
      );
      debugPrint(
        'VoiceRecorder: WAV recording started in '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      return path;
    } catch (e) {
      debugPrint('WAV record failed: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (e) {
      debugPrint('Stop failed: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint('Dispose failed: $e');
    }
  }
}
