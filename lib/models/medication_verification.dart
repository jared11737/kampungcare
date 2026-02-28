/// Model for Gemini Vision medication photo verification response.
/// Matches the JSON structure from the vision prompt in GEMINI_PROMPTS.md.
class MedicationVerification {
  final bool identified;
  final bool? correct; // null if image is unclear
  final double confidence;
  final String messageBm; // Message to display to user in Bahasa Melayu

  const MedicationVerification({
    this.identified = false,
    this.correct,
    this.confidence = 0.0,
    this.messageBm = '',
  });

  factory MedicationVerification.fromJson(Map<String, dynamic> json) {
    return MedicationVerification(
      identified: json['identified'] as bool? ?? false,
      correct: json['correct'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      messageBm: json['message_to_user_bm'] as String? ??
          json['messageBm'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'identified': identified,
        'correct': correct,
        'confidence': confidence,
        'message_to_user_bm': messageBm,
      };

  MedicationVerification copyWith({
    bool? identified,
    bool? correct,
    double? confidence,
    String? messageBm,
  }) {
    return MedicationVerification(
      identified: identified ?? this.identified,
      correct: correct ?? this.correct,
      confidence: confidence ?? this.confidence,
      messageBm: messageBm ?? this.messageBm,
    );
  }
}
