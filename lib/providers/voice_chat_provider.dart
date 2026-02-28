import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/alert.dart';
import '../models/conversation.dart';
import '../models/health_extraction.dart';
import '../models/health_log.dart';
import '../services/ai/mock_gemini_service.dart';
import 'service_providers.dart';

/// Business-logic phase of the voice conversation (replaces the ChatState
/// enum that previously lived inside VoiceChatScreen).
enum ChatPhase { initializing, aiSpeaking, listening, processing, ended }

/// Immutable snapshot of the voice-chat session.
class VoiceChatState {
  final ChatPhase phase;
  final String currentAiMessage;
  final String partialUserText;
  final int exchangeCount;
  final bool sttAvailable;
  final List<ChatMessage> messages;
  final HealthExtraction? extraction;

  const VoiceChatState({
    this.phase = ChatPhase.initializing,
    this.currentAiMessage = '',
    this.partialUserText = '',
    this.exchangeCount = 0,
    this.sttAvailable = true,
    this.messages = const [],
    this.extraction,
  });

  VoiceChatState copyWith({
    ChatPhase? phase,
    String? currentAiMessage,
    String? partialUserText,
    int? exchangeCount,
    bool? sttAvailable,
    List<ChatMessage>? messages,
    HealthExtraction? extraction,
  }) =>
      VoiceChatState(
        phase: phase ?? this.phase,
        currentAiMessage: currentAiMessage ?? this.currentAiMessage,
        partialUserText: partialUserText ?? this.partialUserText,
        exchangeCount: exchangeCount ?? this.exchangeCount,
        sttAvailable: sttAvailable ?? this.sttAvailable,
        messages: messages ?? this.messages,
        extraction: extraction ?? this.extraction,
      );
}

/// Scoped per conversation type via `.family`.
final voiceChatProvider = StateNotifierProvider.family<
    VoiceChatNotifier, VoiceChatState, String>(
  (ref, conversationType) =>
      VoiceChatNotifier(ref: ref, conversationType: conversationType),
);

/// Owns the entire STT/TTS/AI loop and persistence logic.
/// The screen holds only animation + text-field UI state.
class VoiceChatNotifier extends StateNotifier<VoiceChatState> {
  VoiceChatNotifier({required this.ref, required this.conversationType})
      : super(const VoiceChatState());

  final Ref ref;
  final String conversationType;

  // Internal implementation state — not exposed via VoiceChatState
  final List<Map<String, String>> _historyForAi = [];
  int _sttFailCount = 0;
  Timer? _silenceTimer;
  Timer? _autoEndTimer;

  // ── Service shortcuts ──────────────────────────────────────────────────────
  // Use read() (not watch()) inside methods: providers don't rebuild notifiers.
  get _ai => ref.read(aiServiceProvider);
  get _voice => ref.read(voiceServiceProvider);
  get _db => ref.read(databaseServiceProvider);
  get _auth => ref.read(authServiceProvider);

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    state = state.copyWith(phase: ChatPhase.initializing);
    await _voice.initialize();
    final greeting = _ai.getInitialGreeting(conversationType);
    _addAiMessage(greeting);
    await _speakAndListen(greeting);
  }

  /// Called by the screen when the user submits text (fallback mode).
  Future<void> handleUserInput(String userText) async {
    _silenceTimer?.cancel();
    _autoEndTimer?.cancel();

    final sanitized = userText.trim();
    if (sanitized.isEmpty) return;
    final capped =
        sanitized.length > 500 ? sanitized.substring(0, 500) : sanitized;

    _addUserMessage(capped);
    state = state.copyWith(
      phase: ChatPhase.processing,
      exchangeCount: state.exchangeCount + 1,
    );

    final response = await _ai.sendMessage(
      conversationType,
      capped,
      history: _historyForAi,
    );

    if (state.phase == ChatPhase.ended) return;

    _addAiMessage(response);
    await _speakAndListen(response);
  }

  /// Called by the screen's "end call" button.
  Future<void> endConversation() async {
    _silenceTimer?.cancel();
    _autoEndTimer?.cancel();

    await _voice.stopSpeaking();
    await _voice.stopListening();

    HealthExtraction? extraction;
    final ai = _ai;
    if (ai is MockGeminiService) {
      extraction = ai.getExtractionForType(conversationType);
    }

    final summaryMsg = extraction != null
        ? _buildSummaryMessage(extraction)
        : BmStrings.checkInSelesai;

    state = state.copyWith(
      phase: ChatPhase.ended,
      currentAiMessage: summaryMsg,
      extraction: extraction,
    );

    await _saveConversationAndHealthData();
  }

  /// Computed summary string — safe to call from UI after phase == ended.
  String getSummaryMessage() => state.currentAiMessage;

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _speakAndListen(String text) async {
    state = state.copyWith(
      phase: ChatPhase.aiSpeaking,
      currentAiMessage: text,
    );

    await _voice.speak(text);

    if (state.phase == ChatPhase.ended) return;
    if (state.exchangeCount >= AppConstants.maxConversationExchanges) {
      await endConversation();
      return;
    }

    if (state.sttAvailable) {
      _startListening();
    } else {
      state = state.copyWith(phase: ChatPhase.listening);
    }
  }

  void _startListening() {
    state = state.copyWith(
      phase: ChatPhase.listening,
      partialUserText: '',
    );

    _silenceTimer?.cancel();
    _silenceTimer = Timer(
      Duration(seconds: AppConstants.silencePromptSeconds),
      _onSilenceTimeout,
    );

    _autoEndTimer?.cancel();
    _autoEndTimer = Timer(
      Duration(seconds: AppConstants.silenceAutoEndSeconds),
      _onAutoEndTimeout,
    );

    _listenForSpeech();
  }

  Future<void> _listenForSpeech() async {
    final result = await _voice.listen(
      timeout: Duration(seconds: AppConstants.silenceAutoEndSeconds),
    );

    _silenceTimer?.cancel();
    _autoEndTimer?.cancel();

    if (state.phase == ChatPhase.ended) return;

    if (result != null && result.isNotEmpty) {
      _sttFailCount = 0;
      await handleUserInput(result);
    } else {
      _sttFailCount++;
      if (_sttFailCount >= 2 && state.phase != ChatPhase.ended) {
        state = state.copyWith(sttAvailable: false, phase: ChatPhase.listening);
      } else if (state.phase != ChatPhase.ended) {
        await endConversation();
      }
    }
  }

  void _onSilenceTimeout() {
    if (state.phase == ChatPhase.listening) {
      _speakAndListen('Mak Cik masih ada?');
    }
  }

  void _onAutoEndTimeout() {
    if (state.phase != ChatPhase.ended) {
      endConversation();
    }
  }

  String _buildSummaryMessage(HealthExtraction ext) {
    final parts = <String>[];

    if (ext.mood > 0) {
      final moodLabel = switch (ext.mood) {
        5 => 'Sangat gembira',
        4 => 'Baik',
        3 => 'Biasa',
        2 => 'Kurang sihat',
        1 => 'Tidak baik',
        _ => 'Biasa',
      };
      parts.add('Mood: $moodLabel');
    }

    if (ext.sleepQuality != null && ext.sleepQuality! > 0) {
      parts.add('Tidur: ${ext.sleepQuality}/5');
    }

    if (ext.painLevels.isNotEmpty) {
      final pain = ext.painLevels.entries.first;
      parts.add('Sakit ${pain.key}: ${pain.value}/5');
    }

    if (ext.shouldAlertCaregiver) parts.add('Penjaga dimaklumkan');

    return parts.isEmpty ? BmStrings.checkInSelesai : parts.join(' \u2022 ');
  }

  Future<void> _saveConversationAndHealthData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final convId = 'conv_${now.millisecondsSinceEpoch}';
    final extraction = state.extraction;
    final aiNotes = extraction?.aiNotes ?? '';

    final conversation = Conversation(
      id: convId,
      timestamp: now,
      type: conversationType,
      duration: state.exchangeCount * 15,
      messages: state.messages,
      aiNotes: aiNotes,
      extractedData: extraction != null
          ? {
              'mood': extraction.mood,
              if (extraction.sleepQuality != null) 'sleep': extraction.sleepQuality,
              if (extraction.painLevels.isNotEmpty) 'pain': extraction.painLevels,
            }
          : null,
    );

    _db.saveConversation(user.uid, conversation);

    if (extraction != null &&
        (conversationType == 'check_in' || conversationType == 'concerning')) {
      final healthLog = HealthLog(
        id: 'log_${now.millisecondsSinceEpoch}',
        type: conversationType,
        timestamp: now,
        mood: extraction.mood,
        sleepQuality: extraction.sleepQuality ?? 3,
        painLevel: extraction.painLevels,
        notes: extraction.aiNotes,
        aiSummary: extraction.aiNotes,
        flags: [
          if (extraction.shouldAlertCaregiver) 'caregiver_alert',
          if (extraction.cognitiveFlags.overallConcern != 'none')
            'cognitive_${extraction.cognitiveFlags.overallConcern}',
        ],
      );

      _db.saveHealthLog(user.uid, healthLog);
    }

    if (extraction != null && extraction.shouldAlertCaregiver) {
      final alert = Alert(
        id: 'alert_${now.millisecondsSinceEpoch}',
        elderlyUid: user.uid,
        type: AlertType.patternAnomaly,
        severity: extraction.cognitiveFlags.overallConcern != 'none'
            ? AlertSeverity.red
            : AlertSeverity.yellow,
        message: extraction.alertReason ?? extraction.aiNotes,
        createdAt: now,
      );

      _db.createAlert(alert);
    }
  }

  void _addAiMessage(String content) {
    _historyForAi.add({'role': 'assistant', 'content': content});
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'assistant', content: content)],
    );
  }

  void _addUserMessage(String content) {
    _historyForAi.add({'role': 'user', 'content': content});
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'user', content: content)],
    );
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _autoEndTimer?.cancel();
    super.dispose();
  }
}
