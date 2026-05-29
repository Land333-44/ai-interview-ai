import 'package:flutter/foundation.dart';

import '../core/appwrite_constants.dart';
import '../models/analysis_result.dart';
import '../models/session_type.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'function_service.dart';
import 'storage_service.dart';

class ApiService {
  ApiService({
    FunctionService? functions,
    AuthService? auth,
    DatabaseService? database,
    StorageService? storage,
  })  : _functions = functions ?? FunctionService(),
        _auth = auth ?? AuthService(),
        _db = database ?? DatabaseService(),
        _storage = storage ?? StorageService();

  final FunctionService _functions;
  final AuthService _auth;
  final DatabaseService _db;
  final StorageService _storage;
  String? _lastUploadedFileId;

  /// Used when saving an analysis row (your DB requires `fileId`).
  String? get lastUploadedFileId => _lastUploadedFileId;

  // ─── CHAT — répond au sujet de l'utilisateur ─────────────────────────────

  Future<String> chatWithCoach(
    String message, {
    List<Map<String, String>>? history,
    String? sessionId,
  }) async {
    if (message.trim().isEmpty) return '';

    var result = await _invoke(
      type: 'chat',
      text: message.trim(),
      history: history,
      sessionId: sessionId,
    );

    var reply = result.success ? result.chatReply.trim() : '';

    // GitHub deployment may ignore type:chat — fallback to text coaching prompt.
    if (reply.isEmpty) {
      result = await _invoke(
        type: 'text',
        text:
            'You are Smart Coach AI in a live chat. Reply in 2-4 sentences, same language as the user. '
            'User message: ${message.trim()}',
        sessionId: sessionId,
      );
      reply = result.success ? result.chatReply.trim() : '';
    }

    if (!result.success) {
      return _friendlyError(result.error);
    }
    if (reply.isEmpty) {
      return 'AI coach unavailable. Redeploy ai-interview-ai with src/main.js and set GROQ_API_KEY.';
    }
    return reply;
  }

  // ─── TEXT ────────────────────────────────────────────────────────────────

  Future<AnalysisResult> analyzeText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const AnalysisResult(success: false, error: 'Text cannot be empty');
    }
    _lastUploadedFileId = 'text';
    return _invoke(type: 'text', text: trimmed);
  }

  // ─── AUDIO / IMAGE / VIDEO ─────────────────────────────────────────────────

  Future<AnalysisResult> analyzeSession({
    required SessionType type,
    String? text,
    String? filePath,
    String? fileName,
    List<int>? fileBytes,
  }) async {
    if (type == SessionType.text) {
      if (text == null || text.trim().isEmpty) {
        return const AnalysisResult(
          success: false,
          error: 'Missing text for analysis',
        );
      }
      return analyzeText(text);
    }

    final user = await _auth.getCurrentUser();
    if (user == null) {
      return const AnalysisResult(success: false, error: 'Please log in first');
    }

    if (fileBytes != null && fileBytes.isNotEmpty && fileName != null) {
      final upload = await _storage.uploadBytes(
        bytes: fileBytes,
        fileName: fileName,
      );
      if (!upload.success) {
        return AnalysisResult(
          success: false,
          error: upload.error ?? 'Upload failed',
        );
      }
      _lastUploadedFileId = upload.fileId;
      return _invoke(
        type: type.name,
        fileId: upload.fileId!,
        userId: user.$id,
        fileName: fileName,
      );
    }

    if (!kIsWeb && filePath != null && filePath.isNotEmpty) {
      final name = fileName ?? filePath.split(RegExp(r'[/\\]')).last;
      final upload = await _storage.uploadFile(
        filePath: filePath,
        fileName: name,
      );
      if (!upload.success) {
        return AnalysisResult(
          success: false,
          error: upload.error ?? 'Upload failed',
        );
      }
      _lastUploadedFileId = upload.fileId;
      return _invoke(
        type: type.name,
        fileId: upload.fileId!,
        userId: user.$id,
        fileName: name,
      );
    }

    return AnalysisResult(
      success: false,
      error: 'Select or record a ${type.name} file first',
    );
  }

  Future<AnalysisResult> _invoke({
    required String type,
    String? text,
    String? fileId,
    String? userId,
    String? fileName,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    if (!_isFunctionConfigured(AppwriteConstants.aiInterviewFunctionId)) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AnalysisResult.demo;
    }

    final loginUser = await _auth.getCurrentUser();
    if (loginUser == null) {
      return const AnalysisResult(
        success: false,
        error: 'Please log in first, then try again',
      );
    }

    try {
      final execution = await _functions.invokeAi(
        type: type,
        text: text,
        fileId: fileId,
        userId: userId ?? loginUser.$id,
        fileName: fileName,
        sessionId: sessionId,
        history: history,
      );

      final parsed = FunctionService.parseExecution(execution);
      if (parsed != null) {
        final result = AnalysisResult.fromJson(parsed);
        if (result.success) return result;
        if (result.error != null) return result;
      }

      debugPrint(
        'Invoke debug type=$type status=${execution.status} '
        'http=${execution.responseStatusCode} len=${execution.responseBody.length}',
      );

      return AnalysisResult(
        success: false,
        error: FunctionService.executionErrorMessage(execution),
      );
    } catch (e) {
      return AnalysisResult(success: false, error: _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Could not reach AI. Redeploy main.js on Appwrite with API keys.';
    }
    if (raw.contains('empty response') || raw.contains('Réponse vide')) {
      return 'Redéployez la function avec appwrite_functions/main.js '
          '(pas seulement le GitHub ESM). Ajoutez GROQ + HUME keys.';
    }
    return raw;
  }

  Future<String?> saveAnalysisToDatabase({
    required AnalysisResult result,
    required String title,
    String analysisType = 'text',
    String? fileId,
  }) async {
    if (!result.success) return null;
    final user = await _auth.getCurrentUser();
    if (user == null) return null;

    final scorePart =
        result.score > 0 ? 'Score: ${result.score} — ' : '';
    final note = '$scorePart${result.summary}'.trim();

    final effectiveFileId = (fileId != null && fileId.trim().isNotEmpty)
        ? fileId.trim()
        : (_lastUploadedFileId?.trim().isNotEmpty == true
            ? _lastUploadedFileId!.trim()
            : 'text');

    final doc = await _db.createAnalysis(
      userId: user.$id,
      title: title,
      analysisType: analysisType,
      fileId: effectiveFileId,
      status: 'completed',
      note: note,
    );

    return doc?['\$id']?.toString();
  }

  bool _isFunctionConfigured(String id) =>
      id.isNotEmpty && !id.startsWith('YOUR_');
}
