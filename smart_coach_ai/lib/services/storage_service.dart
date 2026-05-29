import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'appwrite_service.dart';
import '../core/appwrite_constants.dart';

class UploadResult {
  final String? fileId;
  final String? error;

  UploadResult({this.fileId, this.error});

  bool get success => fileId != null;
}

class StorageService {
  final Storage _storage = AppwriteService.instance.storage;

  /// Upload any file (video, audio, image, document) to the bucket.
  Future<UploadResult> uploadFile({
    required String filePath,
    required String fileName,
    void Function(UploadProgress)? onProgress,
  }) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppwriteConstants.uploadsBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
        onProgress: onProgress,
      );
      return UploadResult(fileId: file.$id);
    } on AppwriteException catch (e) {
      debugPrint('Storage uploadFile Error: ${e.message}');
      return UploadResult(error: e.message ?? 'Unknown upload error');
    }
  }

  /// Upload file from raw bytes (useful for web/Flutter web).
  Future<UploadResult> uploadBytes({
    required List<int> bytes,
    required String fileName,
    void Function(UploadProgress)? onProgress,
  }) async {
    try {
      final file = await _storage.createFile(
        bucketId: AppwriteConstants.uploadsBucket,
        fileId: ID.unique(),
        file: InputFile.fromBytes(bytes: bytes, filename: fileName),
        onProgress: onProgress,
      );
      return UploadResult(fileId: file.$id);
    } on AppwriteException catch (e) {
      debugPrint('Storage uploadBytes Error: ${e.message}');
      return UploadResult(error: e.message ?? 'Unknown upload error');
    }
  }

  /// Get a public download URL for a file
  String getFileDownloadUrl(String fileId) {
    return '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.uploadsBucket}/files/$fileId/download?project=${AppwriteConstants.projectId}';
  }

  /// Get a preview/thumbnail URL for an image file
  String getFilePreviewUrl(String fileId, {int width = 400, int height = 400}) {
    return '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.uploadsBucket}/files/$fileId/preview?width=$width&height=$height&project=${AppwriteConstants.projectId}';
  }

  /// Delete a file from the bucket
  Future<void> deleteFile(String fileId) async {
    try {
      await _storage.deleteFile(
        bucketId: AppwriteConstants.uploadsBucket,
        fileId: fileId,
      );
    } on AppwriteException catch (e) {
      debugPrint('Storage deleteFile Error: ${e.message}');
    }
  }
}
