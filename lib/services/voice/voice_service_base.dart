/// Abstract interface for voice service.
/// Wraps speech-to-text (STT) and text-to-speech (TTS) capabilities
/// for the elderly voice chat experience.
abstract class VoiceServiceBase {
  /// Initialize the voice engines (STT + TTS).
  /// Returns true if initialization was successful.
  Future<bool> initialize();

  /// Speak the given text aloud using TTS.
  Future<void> speak(String text);

  /// Stop any current TTS playback.
  Future<void> stopSpeaking();

  /// Listen for speech input via STT.
  /// Returns the recognized text, or null if nothing was captured.
  /// [timeout] is an optional duration to limit listening.
  Future<String?> listen({Duration? timeout});

  /// Stop listening for speech input.
  Future<void> stopListening();

  /// Whether STT is currently listening.
  bool get isListening;

  /// Whether TTS is currently speaking.
  bool get isSpeaking;

  /// Stream of partial speech recognition results as user speaks.
  Stream<String> get onPartialResult;

  /// Release all resources.
  Future<void> dispose();
}
