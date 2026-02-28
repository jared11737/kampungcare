import '../database/database_service_base.dart';
import '../ai/ai_service_base.dart';

/// Result of a health pattern analysis.
class PatternAnalysisResult {
  final String overallStatus; // "good" | "mild_concern" | "concerning"
  final bool shouldAlertCaregiver;
  final Map<String, String> trends;
  final List<String> concerns;
  final List<String> recommendations;

  const PatternAnalysisResult({
    required this.overallStatus,
    required this.shouldAlertCaregiver,
    this.trends = const {},
    this.concerns = const [],
    this.recommendations = const [],
  });
}

/// Result of a weekly report generation.
class WeeklyReportResult {
  final String summaryBm;
  final String summaryEn;
  final String highlight;
  final String concern;
  final String suggestedAction;
  final String? sharedStory;

  const WeeklyReportResult({
    required this.summaryBm,
    required this.summaryEn,
    required this.highlight,
    required this.concern,
    required this.suggestedAction,
    this.sharedStory,
  });
}

/// Logic layer for health pattern analysis and weekly report generation.
/// Fetches data from the database, then uses AI to analyze patterns
/// and generate natural language summaries.
class HealthAnalysisService {
  final DatabaseServiceBase _db;
  final AiServiceBase _ai;

  HealthAnalysisService({
    required DatabaseServiceBase db,
    required AiServiceBase ai,
  })  : _db = db,
        _ai = ai;

  /// Analyze recent health patterns for a user.
  /// Fetches the last 14 days of health logs, sends them to AI
  /// for pattern detection, and returns structured results.
  Future<PatternAnalysisResult> analyzeRecentPatterns(String uid) async {
    // Fetch recent health logs
    final healthLogs = await _db.getHealthLogs(uid, days: 14);

    if (healthLogs.isEmpty) {
      return const PatternAnalysisResult(
        overallStatus: 'good',
        shouldAlertCaregiver: false,
        trends: {},
        concerns: [],
        recommendations: ['Tiada data kesihatan untuk dianalisis'],
      );
    }

    // Convert logs to serializable format for AI
    final logData = healthLogs.map((log) => {
      'date': log.timestamp.toIso8601String(),
      'mood': log.mood,
      'sleepQuality': log.sleepQuality,
      'painLevel': log.painLevel,
      'notes': log.notes,
      'flags': log.flags,
    }).toList();

    // Run AI pattern analysis
    final analysis = await _ai.analyzePatterns(logData);

    // Parse AI response into structured result
    final trends = <String, String>{};
    if (analysis['trends'] is Map) {
      (analysis['trends'] as Map).forEach((key, value) {
        trends[key.toString()] = value.toString();
      });
    }

    final concerns = <String>[];
    if (analysis['concerns'] is List) {
      concerns.addAll(
        (analysis['concerns'] as List).map((e) => e.toString()),
      );
    }

    final recommendations = <String>[];
    if (analysis['recommendations'] is List) {
      recommendations.addAll(
        (analysis['recommendations'] as List).map((e) => e.toString()),
      );
    }

    print('[HealthAnalysis] Analyzed ${healthLogs.length} logs for $uid: '
        '${analysis['overallStatus']}');

    return PatternAnalysisResult(
      overallStatus: analysis['overallStatus'] as String? ?? 'good',
      shouldAlertCaregiver: analysis['shouldAlertCaregiver'] as bool? ?? false,
      trends: trends,
      concerns: concerns,
      recommendations: recommendations,
    );
  }

  /// Generate a weekly report for the caregiver.
  /// Combines health logs, medication logs, and conversations
  /// into a comprehensive AI-generated summary.
  Future<WeeklyReportResult> generateWeeklyReport(String uid) async {
    // Let the AI service handle data aggregation and summary generation
    final summary = await _ai.generateWeeklySummary(uid);

    print('[HealthAnalysis] Generated weekly report for $uid');

    return WeeklyReportResult(
      summaryBm: summary['summary_bm'] as String? ?? '',
      summaryEn: summary['summary_en'] as String? ?? '',
      highlight: summary['highlight'] as String? ?? '',
      concern: summary['concern'] as String? ?? '',
      suggestedAction: summary['suggested_action'] as String? ?? '',
      sharedStory: summary['shared_story'] as String?,
    );
  }
}
