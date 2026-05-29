/// Aggregated metrics for the dashboard screen.
class DashboardStats {
  const DashboardStats({
    required this.sessionCount,
    required this.avgScorePercent,
    required this.progressPercent,
    required this.weeklyScores,
    required this.unreadNotifications,
    this.lastSessionScore,
    this.recentSessions = const [],
  });

  final int sessionCount;
  final int avgScorePercent;
  final int progressPercent;
  final List<double> weeklyScores;
  final int unreadNotifications;
  final int? lastSessionScore;
  final List<Map<String, dynamic>> recentSessions;

  static const DashboardStats empty = DashboardStats(
    sessionCount: 0,
    avgScorePercent: 0,
    progressPercent: 0,
    weeklyScores: [0, 0, 0, 0, 0, 0, 0],
    unreadNotifications: 0,
    lastSessionScore: null,
    recentSessions: [],
  );

  String get sessionsLabel => sessionCount.toString();
  String get avgScoreLabel => '$avgScorePercent%';
  String get progressLabel {
    final sign = progressPercent >= 0 ? '+' : '';
    return '$sign$progressPercent%';
  }
}
