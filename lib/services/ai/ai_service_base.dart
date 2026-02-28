/// Abstract interface for AI/Gemini service.
/// Handles all AI-powered features: chat, health extraction,
/// medication verification, pattern analysis, and weekly summaries.
abstract class AiServiceBase {
  /// Send a message in a conversation context.
  /// [conversationType] is one of: "check_in", "casual", "cerita", "emergency"
  /// [userMessage] is what the user said.
  /// [history] is optional prior conversation turns as [{role, content}].
  /// Returns the AI response text.
  Future<String> sendMessage(
    String conversationType,
    String userMessage, {
    List<Map<String, String>>? history,
  });

  /// Extract structured health data from a conversation transcript.
  /// Returns a map with keys like: mood, sleepQuality, painLevel, flags, etc.
  Future<Map<String, dynamic>> extractHealthData(String transcript);

  /// Verify medication photo against expected medications.
  /// [photoBytes] is the image data (Uint8List in real impl).
  /// [meds] is a list of medication data to match against.
  /// Returns: {identified, correct, confidence, notes}
  Future<Map<String, dynamic>> verifyMedication(
    dynamic photoBytes,
    List<dynamic> meds,
  );

  /// Analyze health patterns from a list of health logs.
  /// Returns: {overallStatus, trends, shouldAlertCaregiver, recommendations}
  Future<Map<String, dynamic>> analyzePatterns(List<dynamic> logs);

  /// Generate a weekly summary for the caregiver dashboard.
  /// Returns: {summary_bm, summary_en, highlight, concern, suggested_action}
  Future<Map<String, dynamic>> generateWeeklySummary(String userId);

  /// Get the initial greeting for a conversation type.
  /// Returns a scripted opening line in Bahasa Melayu.
  String getInitialGreeting(String conversationType);
}
