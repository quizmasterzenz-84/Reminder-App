import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

/// Listens for firing alarms and plays the linked audio (recording/tone/picked file).
class AlarmHandler {
  static Future<void> Function(int id)? onAlarmFired;

  static void initialize() {
    Alarm.ringStream.stream.listen((alarm) {
      debugPrint('AlarmHandler: native playback started for id=${alarm.id}');
      final callback = onAlarmFired;
      if (callback != null) unawaited(callback(alarm.id));
    });
  }

}
