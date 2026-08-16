import 'dart:io';

/// Deletes user-recorded audio that is no longer referenced by any reminder.
///
/// Only files stored under the app's own `Music/ReminderApp/` folder are ever
/// deleted. System alarm tones and user-picked files (Downloads, Music, etc.)
/// are never touched, per the app's audio-source design.
class AudioCleanupService {
  /// [deletedId]/[audioPath]/[audioId] describe the reminder being removed.
  /// [others] lists the `(id, audioId)` of every remaining reminder, used to
  /// check whether the same audio is still referenced elsewhere.
  static Future<void> deleteAudioIfUnused({
    required int deletedId,
    required String? audioPath,
    required String? audioId,
    required List<({int id, String? audioId})> others,
  }) async {
    if (audioPath == null || audioId == null) return;

    final usedElsewhere = others.any(
      (r) => r.id != deletedId && r.audioId == audioId,
    );

    if (!usedElsewhere && audioPath.contains('/ReminderApp/')) {
      final file = File(audioPath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
