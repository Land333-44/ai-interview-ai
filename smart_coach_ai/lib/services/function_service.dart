import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../core/appwrite_constants.dart';
import 'appwrite_service.dart';

class FunctionService {
  final Functions _functions = AppwriteService.instance.functions;

  Future<Execution> invokeAi({
    required String type,
    String? text,
    String? fileId,
    String? userId,
    String? fileName,
    String? sessionId,
    List<Map<String, String>>? history,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      if (text != null) 'text': text,
      if (fileId != null) 'fileId': fileId,
      if (userId != null) 'userId': userId,
      if (fileName != null) 'fileName': fileName,
      if (sessionId != null) 'sessionId': sessionId,
      if (history != null) 'history': history,
    };
    return _executeFunction(AppwriteConstants.aiInterviewFunctionId, payload);
  }

  Future<Execution> _executeFunction(
    String functionId,
    Map<String, dynamic> payload,
  ) async {
    // Sync first — often returns full responseBody on Web
    try {
      final sync = await _functions.createExecution(
        functionId: functionId,
        body: jsonEncode(payload),
        xasync: false,
      );
      if (sync.responseBody.isNotEmpty || sync.status == 'failed') {
        return sync;
      }
    } catch (e) {
      debugPrint('Sync execution error: $e');
    }

    final execution = await _functions.createExecution(
      functionId: functionId,
      body: jsonEncode(payload),
      xasync: true,
    );
    return _waitForCompletion(functionId, execution);
  }

  Future<Execution> _waitForCompletion(
    String functionId,
    Execution execution,
  ) async {
    const pollingDelay = Duration(milliseconds: 500);
    const maxAttempts = 120;

    var current = execution;
    var emptyBodyRetries = 0;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final done =
          current.status != 'waiting' && current.status != 'processing';

      if (done) {
        if (current.responseBody.isNotEmpty ||
            current.status == 'failed' ||
            emptyBodyRetries >= 10) {
          return current;
        }
        emptyBodyRetries++;
        await Future.delayed(const Duration(milliseconds: 500));
        current = await _functions.getExecution(
          functionId: functionId,
          executionId: current.$id,
        );
        continue;
      }

      await Future.delayed(pollingDelay);
      current = await _functions.getExecution(
        functionId: functionId,
        executionId: current.$id,
      );
    }

    return current;
  }

  static String executionErrorMessage(Execution execution) {
    if (execution.status == 'failed' && execution.errors.isNotEmpty) {
      return execution.errors;
    }

    final parsed = parseExecution(execution);
    if (parsed != null) {
      if (parsed['error'] != null) return parsed['error'].toString();
      if (parsed['success'] == false) {
        return parsed['error']?.toString() ?? 'Analysis failed';
      }
    }

    if (execution.responseBody.isNotEmpty) {
      final preview = execution.responseBody.length > 300
          ? '${execution.responseBody.substring(0, 300)}...'
          : execution.responseBody;
      return preview;
    }

    return 'Réponse vide du serveur. Redéployez analyze_session.js (main.js) '
        'sur Appwrite avec GROQ_API_KEY + HUME_API_KEY + variables Storage.';
  }

  static Map<String, dynamic>? parseExecution(Execution execution) {
    if (execution.status == 'failed') {
      debugPrint('Failed: ${execution.errors} ${execution.responseBody}');
      return null;
    }
    if (execution.responseBody.isEmpty) return null;
    return _decodeJsonMap(execution.responseBody);
  }

  static Map<String, dynamic>? _decodeJsonMap(String raw) {
    try {
      var decoded = jsonDecode(raw.trim());
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('JSON error: $e');
    }
    return null;
  }
}
