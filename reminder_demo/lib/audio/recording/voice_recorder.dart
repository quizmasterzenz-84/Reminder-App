import 'dart:typed_data';
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
    final hasPerm = await _checkPermission();
    if (!hasPerm) {
      throw Exception("Microphone permission not granted");
    }

    // Prevent double-start crash
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    final folder = await AudioStorageManager.getReminderAudioFolder();
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Try AAC first (supported in your version)
    try {
      final path = p.join(folder.path, 'voice_$timestamp.m4a');
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      return path;
    } catch (e) {
      debugPrint('AAC record failed: $e');
    }

    // Fallback to WAV (your version supports WAV encoder)
    try {
      final path = p.join(folder.path, 'voice_$timestamp.wav');
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
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

  Future<Stream<Uint8List>?> startStream() async {
    try {
      return await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        ),
      );
    } catch (e) {
      debugPrint('Stream start failed: $e');
      return null;
    }
  }

  Future<void> stopStream() async {
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('Stream stop failed: $e');
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
