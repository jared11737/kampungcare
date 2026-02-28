/// Model for Gemini weekly caregiver summary response.
/// Matches the JSON structure from the weekly summary prompt in GEMINI_PROMPTS.md.
class WeeklySummary {
  final String summaryBm;
  final String summaryEn;
  final String highlight;
  final String? concern;
  final String suggestedAction;
  final String? sharedStory;

  const WeeklySummary({
    this.summaryBm = '',
    this.summaryEn = '',
    this.highlight = '',
    this.concern,
    this.suggestedAction = '',
    this.sharedStory,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      summaryBm:
          json['summary_bm'] as String? ??
          json['summaryBm'] as String? ??
          '',
      summaryEn:
          json['summary_en'] as String? ??
          json['summaryEn'] as String? ??
          '',
      highlight: json['highlight'] as String? ?? '',
      concern: json['concern'] as String?,
      suggestedAction:
          json['suggested_action'] as String? ??
          json['suggestedAction'] as String? ??
          '',
      sharedStory:
          json['shared_story'] as String? ??
          json['sharedStory'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'summary_bm': summaryBm,
        'summary_en': summaryEn,
        'highlight': highlight,
        'concern': concern,
        'suggested_action': suggestedAction,
        'shared_story': sharedStory,
      };

  WeeklySummary copyWith({
    String? summaryBm,
    String? summaryEn,
    String? highlight,
    String? concern,
    String? suggestedAction,
    String? sharedStory,
  }) {
    return WeeklySummary(
      summaryBm: summaryBm ?? this.summaryBm,
      summaryEn: summaryEn ?? this.summaryEn,
      highlight: highlight ?? this.highlight,
      concern: concern ?? this.concern,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      sharedStory: sharedStory ?? this.sharedStory,
    );
  }
}
