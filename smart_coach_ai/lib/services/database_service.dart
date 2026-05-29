import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../core/appwrite_constants.dart';
import 'appwrite_service.dart';

class DatabaseService {
  final Databases _db = AppwriteService.instance.databases;

  // ─── ANALYSES ─────────────────────────────────────────────────────────────
  // Your Appwrite schema requires: userId, title, status, analysisType, runDate, note, fileId

  Future<Map<String, dynamic>?> createAnalysis({
    required String userId,
    required String title,
    required String analysisType,
    required String fileId,
    String status = 'completed',
    String note = '',
  }) async {
    try {
      final doc = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.analysesCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'title': title,
          'status': status,
          'analysisType': analysisType,
          'runDate': DateTime.now().toUtc().toIso8601String(),
          'note': note,
          'fileId': fileId,
        },
      );
      return doc.data;
    } on AppwriteException catch (e) {
      debugPrint('DB createAnalysis Error: ${e.message} (code ${e.code})');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAnalyses(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.analysesCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('runDate'),
          Query.limit(100),
        ],
      );
      return res.documents.map((d) => d.data).toList();
    } on AppwriteException catch (e) {
      debugPrint('DB getUserAnalyses Error: ${e.message}');
      return [];
    }
  }

  /// Score is stored inside [note] as "Score: 78 — …" (no score column in schema).
  static int? scoreFromNote(dynamic note) {
    if (note == null) return null;
    final m = RegExp(r'Score:\s*(\d+)').firstMatch(note.toString());
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  // ─── CHAT MESSAGES ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> sendChatMessage({
    required String sessionId,
    required String userId,
    required String sender,
    required String messageText,
    String messageType = 'text',
    bool isRead = false,
  }) async {
    try {
      final doc = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        documentId: ID.unique(),
        data: {
          'sessionId': sessionId,
          'userId': userId,
          'sender': sender,
          'messageText': messageText,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'isRead': isRead,
          'messageType': messageType,
        },
      );
      return doc.data;
    } on AppwriteException catch (e) {
      debugPrint('DB sendChatMessage Error: ${e.message} (code ${e.code})');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String sessionId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        queries: [
          Query.equal('sessionId', sessionId),
          Query.orderAsc('timestamp'),
          Query.limit(100),
        ],
      );
      return res.documents.map((d) => d.data).toList();
    } on AppwriteException catch (e) {
      debugPrint('DB getChatMessages Error: ${e.message}');
      return [];
    }
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final res = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return res.documents.map((d) => d.data).toList();
    } on AppwriteException catch (e) {
      debugPrint('DB getUserNotifications Error: ${e.message}');
      return [];
    }
  }

  Future<void> markNotificationRead(String docId) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: docId,
        data: {'isRead': true},
      );
    } on AppwriteException catch (e) {
      debugPrint('DB markNotificationRead Error: ${e.message}');
    }
  }
}
