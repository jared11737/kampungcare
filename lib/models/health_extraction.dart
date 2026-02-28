/// Model for Gemini's health data extraction from check-in conversations.
/// Matches the JSON structure from the data extraction prompt in GEMINI_PROMPTS.md.
class CognitiveFlags {
  final bool repetition;
  final String wordFinding; // "normal" | "difficulty"
  final String timeOrientation; // "normal" | "confused"
  final String memoryGaps; // "normal" | "concerning"
  final String overallConcern; // "none" | "mild" | "moderate" | "significant"

  const CognitiveFlags({
    this.repetition = false,
    this.wordFinding = 'normal',
    this.timeOrientation = 'normal',
    this.memoryGaps = 'normal',
    this.overallConcern = 'none',
  });

  factory CognitiveFlags.fromJson(Map<String, dynamic> json) {
    return CognitiveFlags(
      repetition: json['repetition'] as bool? ?? false,
      wordFinding: json['wordFinding'] as String? ?? 'normal',
      timeOrientation: json['timeOrientation'] as String? ?? 'normal',
      memoryGaps: json['memoryGaps'] as String? ?? 'normal',
      overallConcern: json['overallConcern'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() => {
        'repetition': repetition,
        'wordFinding': wordFinding,
        'timeOrientation': timeOrientation,
        'memoryGaps': memoryGaps,
        'overallConcern': overallConcern,
      };

  CognitiveFlags copyWith({
    bool? repetition,
    String? wordFinding,
    String? timeOrientation,
    String? memoryGaps,
    String? overallConcern,
  }) {
    return CognitiveFlags(
      repetition: repetition ?? this.repetition,
      wordFinding: wordFinding ?? this.wordFinding,
      timeOrientation: timeOrientation ?? this.timeOrientation,
      memoryGaps: memoryGaps ?? this.memoryGaps,
      overallConcern: overallConcern ?? this.overallConcern,
    );
  }
}

class HealthExtraction {
  final int mood; // 1-5
  final int? sleepQuality; // 1-5 or null if not discussed
  final Map<String, int> painLevels; // e.g. {"knee": 4}
  final String appetite; // "good" | "fair" | "poor" | "not_discussed"
  final String emotionalState; // "content" | "lonely" | "anxious" | "sad" | "confused" | "not_clear"
  final CognitiveFlags cognitiveFlags;
  final String aiNotes;
  final bool shouldAlertCaregiver;
  final String? alertReason;

  const HealthExtraction({
    this.mood = 3,
    this.sleepQuality,
    this.painLevels = const {},
    this.appetite = 'not_discussed',
    this.emotionalState = 'not_clear',
    this.cognitiveFlags = const CognitiveFlags(),
    this.aiNotes = '',
    this.shouldAlertCaregiver = false,
    this.alertReason,
  });

  factory HealthExtraction.fromJson(Map<String, dynamic> json) {
    return HealthExtraction(
      mood: json['mood'] as int? ?? 3,
      sleepQuality: json['sleepQuality'] as int?,
      painLevels: (json['painLevels'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      appetite: json['appetite'] as String? ?? 'not_discussed',
      emotionalState:
          json['emotionalState'] as String? ?? 'not_clear',
      cognitiveFlags: json['cognitiveFlags'] != null
          ? CognitiveFlags.fromJson(
              json['cognitiveFlags'] as Map<String, dynamic>)
          : const CognitiveFlags(),
      aiNotes: json['aiNotes'] as String? ?? '',
      shouldAlertCaregiver:
          json['shouldAlertCaregiver'] as bool? ?? false,
      alertReason: json['alertReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'sleepQuality': sleepQuality,
        'painLevels': painLevels,
        'appetite': appetite,
        'emotionalState': emotionalState,
        'cognitiveFlags': cognitiveFlags.toJson(),
        'aiNotes': aiNotes,
        'shouldAlertCaregiver': shouldAlertCaregiver,
        'alertReason': alertReason,
      };

  HealthExtraction copyWith({
    int? mood,
    int? sleepQuality,
    Map<String, int>? painLevels,
    String? appetite,
    String? emotionalState,
    CognitiveFlags? cognitiveFlags,
    String? aiNotes,
    bool? shouldAlertCaregiver,
    String? alertReason,
  }) {
    return HealthExtraction(
      mood: mood ?? this.mood,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      painLevels: painLevels ?? this.painLevels,
      appetite: appetite ?? this.appetite,
      emotionalState: emotionalState ?? this.emotionalState,
      cognitiveFlags: cognitiveFlags ?? this.cognitiveFlags,
      aiNotes: aiNotes ?? this.aiNotes,
      shouldAlertCaregiver:
          shouldAlertCaregiver ?? this.shouldAlertCaregiver,
      alertReason: alertReason ?? this.alertReason,
    );
  }
}
