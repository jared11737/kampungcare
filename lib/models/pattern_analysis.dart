/// Model for Gemini pattern analysis response (daily background job).
/// Matches the JSON structure from the analysis prompt in GEMINI_PROMPTS.md.
class PatternAnalysis {
  final String overallStatus; // "stable" | "mild_concern" | "concerning" | "urgent"
  final bool shouldAlertCaregiver;
  final String alertSummaryBm;
  final String alertSummaryEn;

  const PatternAnalysis({
    this.overallStatus = 'stable',
    this.shouldAlertCaregiver = false,
    this.alertSummaryBm = '',
    this.alertSummaryEn = '',
  });

  factory PatternAnalysis.fromJson(Map<String, dynamic> json) {
    return PatternAnalysis(
      overallStatus: json['overallStatus'] as String? ?? 'stable',
      shouldAlertCaregiver:
          json['shouldAlertCaregiver'] as bool? ?? false,
      alertSummaryBm:
          json['alertSummary_bm'] as String? ??
          json['alertSummaryBm'] as String? ??
          '',
      alertSummaryEn:
          json['alertSummary_en'] as String? ??
          json['alertSummaryEn'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'overallStatus': overallStatus,
        'shouldAlertCaregiver': shouldAlertCaregiver,
        'alertSummary_bm': alertSummaryBm,
        'alertSummary_en': alertSummaryEn,
      };

  PatternAnalysis copyWith({
    String? overallStatus,
    bool? shouldAlertCaregiver,
    String? alertSummaryBm,
    String? alertSummaryEn,
  }) {
    return PatternAnalysis(
      overallStatus: overallStatus ?? this.overallStatus,
      shouldAlertCaregiver:
          shouldAlertCaregiver ?? this.shouldAlertCaregiver,
      alertSummaryBm: alertSummaryBm ?? this.alertSummaryBm,
      alertSummaryEn: alertSummaryEn ?? this.alertSummaryEn,
    );
  }
}
