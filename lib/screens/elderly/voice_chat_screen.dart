import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/voice_chat_provider.dart';

/// Voice conversation screen — the "wow" feature.
/// Business logic lives in [VoiceChatNotifier]; this widget owns only
/// the animation controller and the text-fallback UI state.
class VoiceChatScreen extends ConsumerStatefulWidget {
  final String conversationType;

  const VoiceChatScreen({
    super.key,
    required this.conversationType,
  });

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  // Animation — must stay in the widget state (needs vsync)
  late AnimationController _avatarController;
  late Animation<double> _avatarPulse;

  // Pure UI state — not part of business logic
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  int? _selectedMood;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _avatarPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );

    // Kick off the chat after the first frame so ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceChatProvider(widget.conversationType).notifier).initialize();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _avatarController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncAnimation(ChatPhase phase) {
    if (phase == ChatPhase.aiSpeaking) {
      if (!_avatarController.isAnimating) {
        _avatarController.repeat(reverse: true);
      }
    } else {
      _avatarController.stop();
      _avatarController.reset();
    }
  }

  void _onTextSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedMood == null) return;

    String userInput = text;
    if (_selectedMood != null && text.isEmpty) {
      userInput = switch (_selectedMood) {
        5 => S.isEnglish ? "I'm feeling very happy today" : 'Saya rasa sangat gembira hari ni',
        4 => S.isEnglish ? "I'm feeling good today" : 'Saya rasa baik hari ni',
        3 => S.isEnglish ? "I'm feeling okay" : 'Biasa-biasa sahaja',
        2 => S.isEnglish ? "I'm not feeling well" : 'Kurang sihat sikit',
        1 => S.isEnglish ? "I'm not doing well today" : 'Saya rasa tak baik hari ni',
        _ => S.isEnglish ? "I'm feeling okay" : 'Biasa-biasa sahaja',
      };
    }

    _textController.clear();
    setState(() => _selectedMood = null);
    ref
        .read(voiceChatProvider(widget.conversationType).notifier)
        .handleUserInput(userInput);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider); // rebuild on language change
    final state = ref.watch(voiceChatProvider(widget.conversationType));
    _syncAnimation(state.phase);

    // Auto-scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && state.messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: KampungCareTheme.calmBlue,
        foregroundColor: Colors.white,
        leading: Semantics(
          button: true,
          label: S.isEnglish ? 'Back to home' : 'Kembali ke halaman utama',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(voiceChatProvider(widget.conversationType).notifier).endConversation();
              context.go(AppRoutes.elderlyHome);
            },
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallAvatar(state.phase),
            const SizedBox(width: 10),
            const Text(AppConstants.aiCompanionName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (state.phase != ChatPhase.ended)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                button: true,
                label: S.isEnglish ? 'End conversation' : 'Tamat perbualan',
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    ref.read(voiceChatProvider(widget.conversationType).notifier).endConversation();
                  },
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: KampungCareTheme.urgentRed, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat history ──
          Expanded(
            child: state.messages.isEmpty
                ? _buildWaitingState(state.phase)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: state.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = state.messages[i];
                      return _ChatBubble(message: msg.content, isAi: msg.role == 'assistant');
                    },
                  ),
          ),

          // ── Status bar ──
          _buildStatusBar(state),

          // ── Text input (always visible when active) ──
          if (state.phase != ChatPhase.initializing && state.phase != ChatPhase.ended)
            _buildTextInput(),

          // ── Back button when ended ──
          if (state.phase == ChatPhase.ended)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildBackButton(context, state),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(ChatPhase phase) {
    return AnimatedBuilder(
      animation: _avatarPulse,
      builder: (ctx, child) => Transform.scale(
        scale: phase == ChatPhase.aiSpeaking ? _avatarPulse.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: const Icon(Icons.record_voice_over_rounded, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildWaitingState(ChatPhase phase) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: KampungCareTheme.calmBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: KampungCareTheme.calmBlue, width: 2),
            ),
            child: const Icon(Icons.record_voice_over_rounded, size: 52, color: KampungCareTheme.calmBlue),
          ),
          const SizedBox(height: 16),
          const Text(AppConstants.aiCompanionName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KampungCareTheme.calmBlue)),
          const SizedBox(height: 8),
          Text(phase == ChatPhase.initializing ? S.silaTunggu : S.bercakap,
              style: const TextStyle(fontSize: 18, color: KampungCareTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(VoiceChatState state) {
    final (icon, label, color) = switch (state.phase) {
      ChatPhase.initializing => (Icons.hourglass_empty_rounded, S.silaTunggu, KampungCareTheme.textSecondary),
      ChatPhase.aiSpeaking => (Icons.volume_up_rounded, S.bercakap, KampungCareTheme.calmBlue),
      ChatPhase.listening => (Icons.mic_rounded, S.mendengar, KampungCareTheme.primaryGreen),
      ChatPhase.processing => (Icons.psychology_rounded, S.berfikir, KampungCareTheme.warningAmber),
      ChatPhase.ended => (Icons.check_circle_rounded, S.checkInSelesai, KampungCareTheme.primaryGreen),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: color.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
          if (state.phase == ChatPhase.listening && state.partialUserText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(state.partialUserText,
                  style: const TextStyle(fontSize: 16, color: KampungCareTheme.textSecondary, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MoodButton(emoji: '\u{1F60A}', value: 4, selected: _selectedMood == 4, onTap: () => setState(() => _selectedMood = 4)),
              const SizedBox(width: 12),
              _MoodButton(emoji: '\u{1F610}', value: 3, selected: _selectedMood == 3, onTap: () => setState(() => _selectedMood = 3)),
              const SizedBox(width: 12),
              _MoodButton(emoji: '\u{1F61F}', value: 2, selected: _selectedMood == 2, onTap: () => setState(() => _selectedMood = 2)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: S.isEnglish ? 'Type your message' : 'Taip mesej anda',
                  textField: true,
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: AppConstants.minTextSize, color: KampungCareTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: S.isEnglish ? 'Type here...' : 'Taip di sini...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _onTextSubmit(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: S.isEnglish ? 'Send message' : 'Hantar mesej',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () { HapticFeedback.mediumImpact(); _onTextSubmit(); },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: KampungCareTheme.calmBlue, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, VoiceChatState state) {
    return Semantics(
      button: true,
      label: S.isEnglish ? 'Back to home' : 'Kembali ke halaman utama',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () { HapticFeedback.mediumImpact(); context.go(AppRoutes.elderlyHome); },
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              color: KampungCareTheme.primaryGreen,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: KampungCareTheme.primaryGreen.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Text(
                S.isEnglish ? 'Back to Home' : 'Kembali',
                style: const TextStyle(fontSize: AppConstants.buttonTextSize, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mood emoji button for text fallback mode.
class _MoodButton extends StatelessWidget {
  final String emoji;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mood $value daripada 5',
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected
                  ? KampungCareTheme.calmBlue.withValues(alpha: 0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? KampungCareTheme.calmBlue
                    : KampungCareTheme.textSecondary.withValues(alpha: 0.3),
                width: selected ? 3 : 1,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isAi;
  const _ChatBubble({required this.message, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAi
              ? KampungCareTheme.calmBlue.withValues(alpha: 0.1)
              : KampungCareTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 4 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 4),
          ),
          border: Border.all(
            color: isAi
                ? KampungCareTheme.calmBlue.withValues(alpha: 0.2)
                : KampungCareTheme.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Text(message,
            style: const TextStyle(fontSize: 20, color: KampungCareTheme.textPrimary, height: 1.5)),
      ),
    );
  }
}
