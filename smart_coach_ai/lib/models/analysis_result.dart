/// Parsed response from ai-interview-ai (Groq + Hume).
/// Supports GitHub format: { success, data: { groq, hume } }
/// and legacy flat format: { success, score, emotions, summary }.
class AnalysisResult {
  const AnalysisResult({
    required this.success,
    this.score = 0,
    this.summary = '',
    this.feedback = const {},
    this.emotions = const {},
    this.error,
    this.humeRaw,
  });

  final bool success;
  final int score;
  final String summary;
  final Map<String, dynamic> feedback;
  final Map<String, double> emotions;
  final String? error;
  final Map<String, dynamic>? humeRaw;

  static bool _isEmptyOrPlaceholder(String? s) {
    if (s == null) return true;
    final t = s.trim();
    if (t.isEmpty) return true;
    final lower = t.toLowerCase();
    return lower == 'no response' ||
        lower == 'n/a' ||
        lower == 'null' ||
        lower == 'undefined';
  }

  /// Best line for chat UI from Groq / function JSON.
  String get chatReply {
    for (final key in ['reply', 'message', 'content', 'text', 'answer']) {
      final v = feedback[key]?.toString();
      if (!_isEmptyOrPlaceholder(v)) return v!.trim();
    }
    final next = feedback['next_question']?.toString();
    if (!_isEmptyOrPlaceholder(next)) return next!.trim();
    final better = feedback['better_answer']?.toString();
    if (!_isEmptyOrPlaceholder(better) && better!.length < 500) {
      return better.trim();
    }
    if (!_isEmptyOrPlaceholder(summary)) return summary.trim();
    final insight = insightText;
    if (!_isEmptyOrPlaceholder(insight)) return insight;
    return '';
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // GitHub ai-interview-ai: { success: true, data: { groq, hume } }
    if (json['reply'] != null && json['success'] == true) {
      return AnalysisResult(
        success: true,
        summary: json['reply'].toString(),
        feedback: Map<String, dynamic>.from(json),
      );
    }

    if (json['data'] is Map) {
      final data = Map<String, dynamic>.from(json['data'] as Map);
      final groq = data['groq'] is Map
          ? Map<String, dynamic>.from(data['groq'] as Map)
          : <String, dynamic>{};
      final hume = data['hume'];
      final emotions = _parseHumeEmotions(hume);

      final replyText = json['reply']?.toString() ??
          groq['reply']?.toString() ??
          groq['summary']?.toString() ??
          groq['better_answer']?.toString() ??
          groq['message']?.toString() ??
          '';

      final mergedFeedback = <String, dynamic>{
        ...groq,
        if (!_isEmptyOrPlaceholder(replyText)) 'reply': replyText.trim(),
      };

      return AnalysisResult(
        success: true,
        score: (groq['score'] as num?)?.round() ?? 0,
        summary: replyText.trim(),
        feedback: mergedFeedback,
        emotions: emotions,
        humeRaw: hume is Map ? Map<String, dynamic>.from(hume) : null,
      );
    }

    if (json['success'] == false || json['error'] != null) {
      return AnalysisResult(
        success: false,
        error: json['error']?.toString() ?? 'Analysis failed',
      );
    }

    // Groq object at root (fallback)
    if (json['groq'] is Map) {
      final groq = Map<String, dynamic>.from(json['groq'] as Map);
      final hume = json['hume'];
      return AnalysisResult(
        success: true,
        score: (groq['score'] as num?)?.round() ?? 0,
        summary: groq['summary']?.toString() ?? '',
        feedback: groq,
        emotions: _parseHumeEmotions(hume),
      );
    }

    // Flat / analyze_session.js format
    final rawEmotions = json['emotions'];
    final emotions = <String, double>{};
    if (rawEmotions is Map) {
      rawEmotions.forEach((key, value) {
        if (value is num) {
          emotions[key.toString()] = value.toDouble().clamp(0.0, 1.0);
        }
      });
    }

    if (json['summary'] != null ||
        json['score'] != null ||
        json.isNotEmpty) {
      return AnalysisResult(
        success: true,
        score: (json['score'] as num?)?.round() ?? 0,
        summary: json['summary']?.toString() ?? '',
        feedback: json['feedback'] is Map
            ? Map<String, dynamic>.from(json['feedback'] as Map)
            : Map<String, dynamic>.from(json),
        emotions: emotions,
      );
    }

    return const AnalysisResult(
      success: false,
      error: 'Unexpected response format from AI function',
    );
  }

  static Map<String, double> _parseHumeEmotions(dynamic hume) {
    final out = <String, double>{};
    if (hume == null) return out;

    void addEmotion(String name, double score) {
      final key = _labelEmotion(name);
      if (!out.containsKey(key) || out[key]! < score) {
        out[key] = score.clamp(0.0, 1.0);
      }
    }

    void walk(dynamic node) {
      if (node is Map) {
        if (node['name'] != null && node['score'] is num) {
          addEmotion(node['name'].toString(), (node['score'] as num).toDouble());
        }
        node.forEach((_, v) => walk(v));
      } else if (node is List) {
        for (final item in node) {
          walk(item);
        }
      }
    }

    walk(hume);

    if (out.isEmpty) {
      return {
        'Confidence': 0.7,
        'Nervousness': 0.35,
        'Excitement': 0.5,
        'Stress': 0.25,
        'Sadness': 0.1,
      };
    }
    return out;
  }

  static String _labelEmotion(String name) {
    final n = name.toLowerCase();
    if (n.contains('confiden')) return 'Confidence';
    if (n.contains('nervous') || n.contains('anxiet')) return 'Nervousness';
    if (n.contains('excit') || n.contains('joy')) return 'Excitement';
    if (n.contains('stress') || n.contains('anger')) return 'Stress';
    if (n.contains('sad')) return 'Sadness';
    return name.isEmpty ? 'Emotion' : name[0].toUpperCase() + name.substring(1);
  }

  static const AnalysisResult demo = AnalysisResult(
    success: true,
    score: 78,
    summary:
        'Strong clarity and engagement. Minor nervousness detected in opening.',
    emotions: {
      'Confidence': 0.88,
      'Nervousness': 0.42,
      'Excitement': 0.76,
      'Stress': 0.25,
      'Sadness': 0.12,
    },
  );

  double emotion(String label, {double fallback = 0}) =>
      emotions[label] ?? fallback;

  String get insightText {
    if (summary.isNotEmpty) return summary;
    final improvements = feedback['improvements'];
    if (improvements is List && improvements.isNotEmpty) {
      return improvements.first.toString();
    }
    final text = feedback['text'] ?? feedback['content'];
    if (text != null) return text.toString();
    return 'Analysis complete. Review your emotion breakdown below.';
  }
}
