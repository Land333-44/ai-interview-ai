import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Backend logic for the dashboard: loads user data from Appwrite and
/// computes sessions, scores, weekly progress, and notification counts.
class DashboardService {
  DashboardService({
    AuthService? auth,
    DatabaseService? database,
  })  : _auth = auth ?? AuthService(),
        _db = database ?? DatabaseService();

  final AuthService _auth;
  final DatabaseService _db;

  Future<DashboardStats> loadStats() async {
    try {
      final user = await _auth.getCurrentUser();
      if (user == null) return DashboardStats.empty;

      final analyses = await _db.getUserAnalyses(user.$id);
      final notifications = await _db.getUserNotifications(user.$id);
      final unread = notifications
          .where((n) => n['isRead'] != true && n['is_read'] != true)
          .length;

      return _computeFromAnalyses(analyses, unread);
    } catch (e) {
      debugPrint('DashboardService.loadStats Error: $e');
      return DashboardStats.empty;
    }
  }

  DashboardStats _computeFromAnalyses(
    List<Map<String, dynamic>> analyses,
    int unreadNotifications,
  ) {
    // Sort analyses by date descending
    final sortedAnalyses = List<Map<String, dynamic>>.from(analyses)
      ..sort((a, b) {
        final dA = _parseDate(a) ?? DateTime(0);
        final dB = _parseDate(b) ?? DateTime(0);
        return dB.compareTo(dA);
      });

    final sessionCount = sortedAnalyses.length;

    final scores = sortedAnalyses
        .map((a) => _parseScore(a['score']) ?? DatabaseService.scoreFromNote(a['note']))
        .whereType<int>()
        .toList();

    final avgScorePercent = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();

    final weeklyScores = _weeklyScores(sortedAnalyses);
    final progressPercent = _progressPercent(scores, sortedAnalyses);

    int? lastScore;
    if (scores.isNotEmpty) lastScore = scores.first;

    return DashboardStats(
      sessionCount: sessionCount,
      avgScorePercent: avgScorePercent,
      progressPercent: progressPercent,
      weeklyScores: weeklyScores,
      unreadNotifications: unreadNotifications,
      lastSessionScore: lastScore,
      recentSessions: sortedAnalyses.take(5).toList(),
    );
  }

  int? _parseScore(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    if (value is String) return int.tryParse(value)?.clamp(0, 100);
    return null;
  }

  DateTime? _parseDate(Map<String, dynamic> doc) {
    final raw = doc['runDate'] ?? doc['\$createdAt'];
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Last 7 days (Mon–Sun relative to today): max score per day, 0–100.
  List<double> _weeklyScores(List<Map<String, dynamic>> analyses) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final buckets = List<double>.filled(7, 0);

    for (final doc in analyses) {
      final date = _parseDate(doc);
      final score =
          _parseScore(doc['score']) ?? DatabaseService.scoreFromNote(doc['note']);
      if (date == null || score == null) continue;

      final dayStart = DateTime(date.year, date.month, date.day);
      if (dayStart.isBefore(start) || dayStart.isAfter(now)) continue;

      final index = dayStart.difference(start).inDays;
      if (index >= 0 && index < 7) {
        buckets[index] = buckets[index] > score ? buckets[index] : score.toDouble();
      }
    }

    return buckets;
  }

  /// Week-over-week change in average score (%).
  int _progressPercent(
    List<int> allScores,
    List<Map<String, dynamic>> analyses,
  ) {
    if (allScores.length < 2) return 0;

    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final thisWeek = <int>[];
    final lastWeek = <int>[];

    for (final doc in analyses) {
      final date = _parseDate(doc);
      final score =
          _parseScore(doc['score']) ?? DatabaseService.scoreFromNote(doc['note']);
      if (date == null || score == null) continue;

      if (date.isAfter(thisWeekStart)) {
        thisWeek.add(score);
      } else if (date.isAfter(lastWeekStart) && date.isBefore(thisWeekStart)) {
        lastWeek.add(score);
      }
    }

    if (thisWeek.isEmpty || lastWeek.isEmpty) return 0;

    final thisAvg = thisWeek.reduce((a, b) => a + b) / thisWeek.length;
    final lastAvg = lastWeek.reduce((a, b) => a + b) / lastWeek.length;
    if (lastAvg == 0) return 0;

    return ((thisAvg - lastAvg) / lastAvg * 100).round();
  }
}
