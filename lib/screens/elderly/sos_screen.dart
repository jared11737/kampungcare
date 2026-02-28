import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/mock_data.dart';
import '../../models/user_profile.dart';
import '../../providers/settings_provider.dart';

/// CRITICAL SOS emergency screen.
/// Full red background with 10-second countdown timer.
/// Cancel button to abort. After countdown, shows delivery status with
/// timed response simulation, health packet display, and cancel confirmation.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

enum SosState { countdown, broadcasting, delivered }

class _SosScreenState extends ConsumerState<SosScreen> with TickerProviderStateMixin {
  SosState _sosState = SosState.countdown;
  int _secondsRemaining = AppConstants.sosCountdownSeconds;
  Timer? _countdownTimer;

  // Timed response simulation
  final List<_StatusMessage> _statusMessages = [];
  final List<Timer> _responseTimers = [];
  bool _healthPacketExpanded = false;

  // Animation controllers for fade+slide
  final List<AnimationController> _animControllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    HapticFeedback.heavyImpact();
    _startCountdown();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _countdownTimer?.cancel();
    for (final timer in _responseTimers) {
      timer.cancel();
    }
    for (final controller in _animControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _onCountdownComplete();
      } else {
        setState(() {
          _secondsRemaining--;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _onCountdownComplete() {
    setState(() {
      _sosState = SosState.broadcasting;
    });
    HapticFeedback.heavyImpact();

    // Start timed response simulation
    _startTimedResponses();
  }

  void _addStatusMessage(_StatusMessage message) {
    if (!mounted) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    setState(() {
      _animControllers.add(controller);
      _fadeAnimations.add(fade);
      _slideAnimations.add(slide);
      _statusMessages.add(message);
    });

    controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _startTimedResponses() {
    // 0s: "Menghantar kecemasan..."
    _addStatusMessage(_StatusMessage(
      text: S.isEnglish ? 'Sending emergency...' : 'Menghantar kecemasan...',
      icon: Icons.send_rounded,
      color: Colors.white,
      iconColor: Colors.white70,
    ));

    // 2s: "Kak Zainab — dimaklumkan"
    _responseTimers.add(Timer(const Duration(seconds: 2), () {
      _addStatusMessage(_StatusMessage(
        text: S.isEnglish ? 'Kak Zainab \u2014 notified' : 'Kak Zainab \u2014 dimaklumkan',
        icon: Icons.check_circle_rounded,
        color: Colors.greenAccent,
        iconColor: Colors.greenAccent,
      ));
    }));

    // 4s: "Aisyah — dimaklumkan"
    _responseTimers.add(Timer(const Duration(seconds: 4), () {
      _addStatusMessage(_StatusMessage(
        text: S.isEnglish ? 'Aisyah \u2014 notified' : 'Aisyah \u2014 dimaklumkan',
        icon: Icons.check_circle_rounded,
        color: Colors.greenAccent,
        iconColor: Colors.greenAccent,
      ));
      if (mounted) {
        setState(() {
          _sosState = SosState.delivered;
        });
      }
    }));

    // 8s: "Kak Zainab sedang ke rumah..."
    _responseTimers.add(Timer(const Duration(seconds: 8), () {
      _addStatusMessage(_StatusMessage(
        text: S.isEnglish
            ? 'Kak Zainab is on her way (est. 2 min)'
            : 'Kak Zainab sedang ke rumah Mak Cik (anggaran 2 minit)',
        icon: Icons.directions_walk_rounded,
        color: Colors.white,
        iconColor: Colors.amberAccent,
      ));
    }));

    // 15s: "Aisyah telah menelefon"
    _responseTimers.add(Timer(const Duration(seconds: 15), () {
      _addStatusMessage(_StatusMessage(
        text: S.isEnglish ? 'Aisyah has called' : 'Aisyah telah menelefon',
        icon: Icons.phone_in_talk_rounded,
        color: Colors.white,
        iconColor: Colors.lightBlueAccent,
      ));
    }));
  }

  void _cancelSos() {
    HapticFeedback.heavyImpact();
    _showCancelConfirmation();
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Semantics(
                  header: true,
                  child: Text(
                    S.isEnglish ? 'Are you sure you are OK?' : 'Betul Mak Cik OK?',
                    style: const TextStyle(
                      fontSize: AppConstants.headerTextSize,
                      fontWeight: FontWeight.bold,
                      color: KampungCareTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  S.isEnglish
                      ? 'Press YES to cancel the emergency.'
                      : 'Tekan YA untuk batalkan kecemasan.',
                  style: const TextStyle(
                    fontSize: AppConstants.minTextSize,
                    color: KampungCareTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // "Ya, saya OK" button (green)
                Semantics(
                  button: true,
                  label: 'Ya, saya OK. Tekan untuk batalkan kecemasan.',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(dialogContext).pop();
                        _countdownTimer?.cancel();
                        for (final timer in _responseTimers) {
                          timer.cancel();
                        }
                        // Navigate home with success
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              S.isEnglish
                                  ? "Emergency cancelled. Glad you're OK!"
                                  : 'Kecemasan dibatalkan. Syukur Mak Cik OK!',
                              style: const TextStyle(fontSize: 18),
                            ),
                            backgroundColor: KampungCareTheme.primaryGreen,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        context.go(AppRoutes.elderlyHome);
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: AppConstants.minTouchTarget,
                        ),
                        decoration: BoxDecoration(
                          color: KampungCareTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            S.isEnglish ? "Yes, I'm OK" : 'Ya, saya OK',
                            style: const TextStyle(
                              fontSize: AppConstants.minTextSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // "Tidak, perlukan bantuan" button (red)
                Semantics(
                  button: true,
                  label:
                      'Tidak, perlukan bantuan. Tekan untuk teruskan kecemasan.',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(dialogContext).pop();
                        // Continue SOS — do nothing
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: AppConstants.minTouchTarget,
                        ),
                        decoration: BoxDecoration(
                          color: KampungCareTheme.urgentRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            S.isEnglish ? 'No, I need help' : 'Tidak, perlukan bantuan',
                            style: const TextStyle(
                              fontSize: AppConstants.minTextSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _call999() async {
    HapticFeedback.heavyImpact();
    final uri = Uri.parse('tel:999');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('[SOS] Error calling 999: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider); // rebuild on language change
    return Scaffold(
      backgroundColor: KampungCareTheme.urgentRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Header
              Semantics(
                header: true,
                liveRegion: true,
                label: _sosState == SosState.countdown
                    ? (S.isEnglish
                        ? 'Emergency activated. Sending in $_secondsRemaining seconds.'
                        : 'Kecemasan diaktifkan. Menghantar dalam $_secondsRemaining saat.')
                    : (S.isEnglish
                        ? 'Emergency sent. Your contacts have been notified.'
                        : 'Kecemasan dihantar. Kenalan anda dimaklumkan.'),
                child: Text(
                  S.isEnglish ? 'EMERGENCY ACTIVATED' : 'KECEMASAN DIAKTIFKAN',
                  style: const TextStyle(
                    fontSize: AppConstants.headerTextSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Divider
              Container(
                width: 80,
                height: 3,
                color: Colors.white.withValues(alpha: 0.5),
              ),

              const SizedBox(height: 32),

              // Main content
              Expanded(
                child: _buildContent(),
              ),

              // Bottom actions
              _buildBottomActions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_sosState) {
      case SosState.countdown:
        return _buildCountdown();
      case SosState.broadcasting:
      case SosState.delivered:
        return _buildDeliveryStatus();
    }
  }

  Widget _buildCountdown() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Countdown circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '$_secondsRemaining',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Countdown text
        Text(
          '${S.menghantar} $_secondsRemaining...',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeliveryStatus() {
    final elderly = MockData.elderlyUser;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isEnglish ? 'Emergency Status:' : 'Status Kecemasan:',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Animated status messages
          ...List.generate(_statusMessages.length, (index) {
            final msg = _statusMessages[index];
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    label: msg.text,
                    child: Row(
                      children: [
                        Icon(
                          msg.icon,
                          size: 28,
                          color: msg.iconColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: AppConstants.minTextSize,
                              color: msg.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Location sent indicator (show after delivered)
          if (_sosState == SosState.delivered) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.lokasiDihantar,
                      style: const TextStyle(
                        fontSize: AppConstants.minTextSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Health Packet Card (collapsible, shown after delivered)
          if (_sosState == SosState.delivered) ...[
            const SizedBox(height: 20),
            _buildHealthPacketCard(elderly),
          ],

          const SizedBox(height: 32),

          // Call 999 button
          Semantics(
            button: true,
            label: 'Panggil 999. Tekan untuk panggil perkhidmatan kecemasan.',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _call999,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.call_rounded,
                        size: 36,
                        color: KampungCareTheme.urgentRed,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        S.panggil999,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: KampungCareTheme.urgentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPacketCard(UserProfile elderly) {
    final meds = MockData.medications;
    final medNames = meds.map((m) => m.name).join(', ');
    final conditions = elderly.conditions.map((c) => c.name).join(', ');
    final allergies = elderly.allergies.join(', ');

    return Semantics(
      label: 'Maklumat kesihatan yang dihantar kepada kenalan kecemasan',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _healthPacketExpanded = !_healthPacketExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with expand/collapse icon
              Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    size: 28,
                    color: KampungCareTheme.urgentRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.isEnglish ? 'Health Information Sent' : 'Maklumat Kesihatan Dihantar',
                      style: const TextStyle(
                        fontSize: AppConstants.minTextSize,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _healthPacketExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 28,
                    color: KampungCareTheme.textSecondary,
                  ),
                ],
              ),

              // Expanded health data
              if (_healthPacketExpanded) ...[
                const SizedBox(height: 16),
                _healthRow(S.isEnglish ? 'Name' : 'Nama', elderly.name),
                _healthRow(S.isEnglish ? 'Age' : 'Umur', '${elderly.age}'),
                _healthRow(S.isEnglish ? 'Blood' : 'Darah', elderly.bloodType),
                _healthRow(
                    S.isEnglish ? 'Allergies' : 'Alergi',
                    allergies.isNotEmpty ? allergies : (S.isEnglish ? 'None' : 'Tiada')),
                _healthRow(S.isEnglish ? 'Conditions' : 'Penyakit', conditions),
                _healthRow(S.isEnglish ? 'Medicine' : 'Ubat', medNames),
                _healthRow(
                    'Hospital', '${elderly.preferredHospital}, Kuantan'),
                _healthRow(S.isEnglish ? 'Address' : 'Alamat', elderly.address),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _healthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: AppConstants.minTextSize,
                fontWeight: FontWeight.bold,
                color: KampungCareTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppConstants.minTextSize,
                color: KampungCareTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    // Cancel button -- available during countdown and delivery
    return Semantics(
      button: true,
      label: 'Batalkan kecemasan. Tekan jika anda OK.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _cancelSos,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close_rounded, size: 32, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  S.isEnglish ? "I'm OK \u2014 Cancel" : 'Saya OK \u2014 Batalkan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status message for the timed response simulation.
class _StatusMessage {
  final String text;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _StatusMessage({
    required this.text,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}
