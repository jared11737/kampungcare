import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/health_log.dart';
import '../../models/medication.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_logs_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/settings_provider.dart';

/// Main home screen for elderly users.
/// Shows time-based greeting, reactive status banner,
/// 2x2 feature grid, full-width SOS button, and settings link.
class ElderlyHomeScreen extends ConsumerWidget {
  const ElderlyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider); // rebuild on language change
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Mak Cik';
    final displayName = _getDisplayName(userName);
    final now = DateTime.now();

    // Data driven via providers — no initState required
    final logsAsync = user != null
        ? ref.watch(recentHealthLogsProvider(user.uid))
        : const AsyncValue<List<HealthLog>>.data([]);
    final medsAsync = user != null
        ? ref.watch(medicationsProvider(user.uid))
        : const AsyncValue<List<Medication>>.data([]);

    final latestLog = logsAsync.valueOrNull?.isNotEmpty == true
        ? logsAsync.valueOrNull!.first
        : null;
    final medsTotal = medsAsync.valueOrNull?.length ?? 0;
    final medsTaken = medsTotal > 0 ? 1 : 0; // demo: first med always taken

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [KampungCareTheme.primaryGreen, Color(0xFF1B5E20)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.greeting(),
                      style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: AppConstants.headerTextSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      S.date(now),
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ── Status Card (overlaps header) ──
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatusBanner(
                    latestLog: latestLog,
                    medsTaken: medsTaken,
                    medsTotal: medsTotal,
                  ),
                ),
              ),

              // ── Feature Grid ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.screenPadding, 4,
                    AppConstants.screenPadding, 0),
                child: _FeatureGrid(),
              ),
              const SizedBox(height: 24),

              // ── SOS Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                child: _SosButton(),
              ),
              const SizedBox(height: 24),

              // ── Settings Link ──
              Center(
                child: Semantics(
                  button: true,
                  label: S.tetapan,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(AppRoutes.settings);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings_rounded, size: 24, color: KampungCareTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(S.tetapan, style: const TextStyle(fontSize: AppConstants.minTextSize, color: KampungCareTheme.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.isNotEmpty) {
      if (fullName.toLowerCase().startsWith('mak cik') ||
          fullName.toLowerCase().startsWith('pak cik')) {
        return parts.take(3).join(' ');
      }
      return 'Mak Cik ${parts.first}';
    }
    return 'Mak Cik';
  }
}

/// White card status banner showing daily overview.
/// Updates reactively based on latest health log.
class _StatusBanner extends StatelessWidget {
  final HealthLog? latestLog;
  final int medsTaken;
  final int medsTotal;

  const _StatusBanner({
    this.latestLog,
    this.medsTaken = 0,
    this.medsTotal = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlag = latestLog != null && latestLog!.flags.isNotEmpty;
    final isGood = !hasFlag;
    final statusText = isGood ? S.semuaBaik : S.perluPerhatian;
    final statusColor = isGood ? KampungCareTheme.primaryGreen : KampungCareTheme.warningAmber;

    final medStatus = medsTotal > 0
        ? (S.isEnglish
            ? 'Morning medicine: ${medsTaken > 0 ? "✅ Taken" : "❌ Not yet"}'
            : 'Ubat pagi: ${medsTaken > 0 ? "✅ Sudah" : "❌ Belum"}')
        : (S.isEnglish ? 'Morning medicine: Please check' : 'Ubat pagi: Sila periksa');

    final moodString = latestLog != null
        ? 'Mood: ${_moodEmoji(latestLog!.mood)} ${_moodLabel(latestLog!.mood)}'
        : '';

    return Semantics(
      label: 'Status: $statusText. $medStatus',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 60,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
                  const SizedBox(height: 4),
                  Text(medStatus, style: const TextStyle(fontSize: AppConstants.minTextSize, color: KampungCareTheme.textPrimary)),
                  if (moodString.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(moodString, style: const TextStyle(fontSize: AppConstants.minTextSize, color: KampungCareTheme.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _moodEmoji(int mood) {
    return switch (mood) {
      5 => '\u{1F60A}',
      4 => '\u{1F642}',
      3 => '\u{1F610}',
      2 => '\u{1F61F}',
      1 => '\u{1F622}',
      _ => '\u{1F610}',
    };
  }

  String _moodLabel(int mood) {
    if (S.isEnglish) {
      return switch (mood) {
        5 => 'Very Happy', 4 => 'Good', 3 => 'Okay', 2 => 'Not Well', 1 => 'Poor', _ => 'Okay',
      };
    }
    return switch (mood) {
      5 => 'Sangat gembira', 4 => 'Baik', 3 => 'Biasa', 2 => 'Kurang sihat', 1 => 'Tidak baik', _ => 'Biasa',
    };
  }
}

/// 2x2 grid of large feature buttons.
class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GridButton(
                label: S.sembang,
                icon: Icons.chat_bubble_rounded,
                color: KampungCareTheme.calmBlue,
                semanticsLabel: S.isEnglish
                    ? 'Chat. Tap to talk with Sayang.'
                    : 'Sembang. Tekan untuk bercakap dengan Sayang.',
                onTap: () {
                  context.push(
                    '${AppRoutes.voiceChat}?type=check_in',
                  );
                },
              ),
            ),
            const SizedBox(width: AppConstants.buttonSpacing),
            Expanded(
              child: _GridButton(
                label: S.ubat,
                icon: Icons.medication_rounded,
                color: KampungCareTheme.primaryGreen,
                semanticsLabel: S.isEnglish
                    ? 'Medicine. Tap to view medicine list.'
                    : 'Ubat. Tekan untuk lihat senarai ubat.',
                onTap: () {
                  context.push(AppRoutes.medication);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.buttonSpacing),
        Row(
          children: [
            Expanded(
              child: _GridButton(
                label: S.kesihatan,
                icon: Icons.favorite_rounded,
                color: KampungCareTheme.warningAmber,
                semanticsLabel: S.isEnglish
                    ? 'Health. Tap to view health records.'
                    : 'Kesihatan. Tekan untuk lihat rekod kesihatan.',
                onTap: () {
                  context.push(AppRoutes.health);
                },
              ),
            ),
            const SizedBox(width: AppConstants.buttonSpacing),
            Expanded(
              child: _GridButton(
                label: S.keluarga,
                icon: Icons.people_rounded,
                color: const Color(0xFF6A1B9A),
                semanticsLabel: S.isEnglish
                    ? 'Family. Tap to view family and neighbours.'
                    : 'Keluarga. Tekan untuk lihat senarai keluarga dan jiran.',
                onTap: () {
                  context.push(AppRoutes.family);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual grid button with icon and label, styled for elderly users.
class _GridButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _GridButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 44,
                  color: KampungCareTheme.textOnDark,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppConstants.buttonTextSize,
                    fontWeight: FontWeight.bold,
                    color: KampungCareTheme.textOnDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width red SOS emergency button — 120dp tall.
class _SosButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.isEnglish
          ? 'Emergency button. Tap to call for help.'
          : 'Butang kecemasan. Tekan untuk panggil bantuan segera.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.heavyImpact();
            context.push(AppRoutes.sos);
          },
          child: Container(
            width: double.infinity,
            height: AppConstants.sosTouchTarget,
            decoration: BoxDecoration(
              color: KampungCareTheme.urgentRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: KampungCareTheme.urgentRed.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  size: 44,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  S.kecemasan,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
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
