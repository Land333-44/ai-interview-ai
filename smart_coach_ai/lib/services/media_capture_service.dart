import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Phase 2–4 media capture. Text analysis does not use this service.
class MediaCaptureService {
  MediaCaptureService({AudioRecorder? recorder, ImagePicker? picker})
      : _recorder = recorder ?? AudioRecorder(),
        _picker = picker ?? ImagePicker();

  final AudioRecorder _recorder;
  final ImagePicker _picker;
  String? _recordingPath;

  // ─── AUDIO (Phase 2) ─────────────────────────────────────────────────────

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;

    if (kIsWeb) {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '',
      );
      return 'web_audio'; // placeholder, stop() will return blob url
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/session_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    return _recordingPath;
  }

  Future<List<int>?> getFileBytes(String path) async {
    try {
      final file = XFile(path);
      final bytes = await file.readAsBytes();
      return bytes.toList();
    } catch (e) {
      return null;
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path ?? _recordingPath;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Pick audio file (works on Web + mobile when mic record fails).
  Future<({String? path, List<int>? bytes, String name})?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'webm'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    return (
      path: f.path,
      bytes: f.bytes,
      name: f.name,
    );
  }

  // ─── IMAGE (Phase 3) ───────────────────────────────────────────────────

  Future<XFile?> pickImageFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery);

  Future<XFile?> pickImageFromCamera() =>
      _picker.pickImage(source: ImageSource.camera);

  // ─── VIDEO (Phase 4) ───────────────────────────────────────────────────

  Future<XFile?> pickVideoFromGallery() =>
      _picker.pickVideo(source: ImageSource.gallery);

  /// On Web, ImagePicker camera source opens a file picker anyway.
  /// We use FilePicker directly on Web for a consistent UX with video types.
  Future<XFile?> pickVideoFromCamera() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.first;
      // Return an XFile-like wrapper using path (web uses bytes internally)
      if (f.bytes != null) {
        return XFile.fromData(f.bytes!, name: f.name, mimeType: 'video/mp4');
      }
      return null;
    }
    return _picker.pickVideo(source: ImageSource.camera);
  }

  // ─── DOCUMENTS (.txt for text tab) ───────────────────────────────────────

  Future<String?> pickTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.bytes != null) {
      return String.fromCharCodes(file.bytes!);
    }
    return null;
  }
}
