import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// Result of picking a user-selected audio file (Downloads, Music, etc.).
///
/// The original file is referenced in place; it is never copied or deleted.
typedef PickedAudio = ({String path, String id});

class AudioPicker {
  /// Opens the system file picker restricted to audio files.
  /// Returns `null` if the user cancels the picker.
  static Future<PickedAudio?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.single.path;
    if (path == null) return null;

    return (path: path, id: p.basenameWithoutExtension(path));
  }
}
