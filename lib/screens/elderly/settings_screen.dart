import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

/// Settings screen with large, elderly-friendly controls.
/// Allows adjusting language, text size, morning check-in time, and voice speed.
/// All values stored via SettingsNotifier (SharedPreferences).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _textScale = AppConstants.defaultTextScale;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 6, minute: 30);
  double _voiceSpeed = AppConstants.voiceSpeechRate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      final parts = settings.morningCheckInTime.split(':');
      setState(() {
        _textScale = settings.textScale;
        _voiceSpeed = settings.voiceSpeed;
        if (parts.length == 2) {
          _checkInTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 6,
            minute: int.tryParse(parts[1]) ?? 30,
          );
        }
        _isLoading = false;
      });
    });
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await ref.read(settingsProvider.notifier).setTextScale(_textScale);
      await ref.read(settingsProvider.notifier).setVoiceSpeed(_voiceSpeed);
      await ref.read(settingsProvider.notifier).setMorningCheckInTime(
        '${_checkInTime.hour.toString().padLeft(2, '0')}:${_checkInTime.minute.toString().padLeft(2, '0')}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.isEnglish ? 'Settings saved!' : 'Tetapan disimpan!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            backgroundColor: KampungCareTheme.primaryGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('[Settings] Error saving: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime() async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialTextStyle: const TextStyle(fontSize: 22),
              helpTextStyle: const TextStyle(fontSize: 20),
              hourMinuteTextStyle: const TextStyle(fontSize: 40),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _checkInTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider); // rebuild on language change

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: KampungCareTheme.textSecondary,
        foregroundColor: KampungCareTheme.textOnDark,
        leading: Semantics(
          button: true,
          label: S.isEnglish ? 'Back to home' : 'Kembali ke halaman utama',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.elderlyHome);
            },
          ),
        ),
        title: Text(
          S.tetapan,
          style: const TextStyle(
            fontSize: AppConstants.headerTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: KampungCareTheme.primaryGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Language toggle
                  _SettingsCard(
                    title: S.isEnglish ? 'Language' : 'Bahasa',
                    icon: Icons.language_rounded,
                    child: Row(
                      children: [
                        Text(
                          'BM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: !S.isEnglish
                                ? KampungCareTheme.primaryGreen
                                : KampungCareTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: S.isEnglish,
                          activeThumbColor: KampungCareTheme.primaryGreen,
                          activeTrackColor: KampungCareTheme.primaryGreen.withValues(alpha: 0.5),
                          onChanged: (value) async {
                            HapticFeedback.mediumImpact();
                            await ref
                                .read(settingsProvider.notifier)
                                .setIsEnglish(value);
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: S.isEnglish
                                ? KampungCareTheme.primaryGreen
                                : KampungCareTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text Size slider
                  _SettingsCard(
                    title: S.isEnglish ? 'Text Size' : 'Saiz Teks',
                    icon: Icons.text_fields_rounded,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'A',
                              style: TextStyle(
                                fontSize: 18,
                                color: KampungCareTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${(_textScale * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: KampungCareTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'A',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: KampungCareTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: S.isEnglish
                              ? 'Text size. Currently ${(_textScale * 100).round()} percent.'
                              : 'Saiz teks. Sekarang ${(_textScale * 100).round()} peratus.',
                          slider: true,
                          child: SliderTheme(
                            data: SliderThemeData(
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 16),
                              trackHeight: 8,
                              activeTrackColor: KampungCareTheme.calmBlue,
                              inactiveTrackColor:
                                  KampungCareTheme.calmBlue.withValues(alpha: 0.2),
                              thumbColor: KampungCareTheme.calmBlue,
                              overlayColor:
                                  KampungCareTheme.calmBlue.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: _textScale,
                              min: 1.0,
                              max: 2.0,
                              divisions: 10,
                              onChanged: (value) {
                                setState(() => _textScale = value);
                              },
                            ),
                          ),
                        ),
                        // Preview text
                        Text(
                          S.isEnglish
                              ? 'Example text at this size'
                              : 'Contoh teks pada saiz ini',
                          style: TextStyle(
                            fontSize: 20 * _textScale / 1.3,
                            color: KampungCareTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Morning check-in time
                  _SettingsCard(
                    title: S.isEnglish ? 'Morning Check-in Time' : 'Masa Check-in Pagi',
                    icon: Icons.access_time_rounded,
                    child: Semantics(
                      button: true,
                      label: S.isEnglish
                          ? 'Morning check-in time. Currently ${_checkInTime.format(context)}. Tap to change.'
                          : 'Masa check-in pagi. Sekarang ${_checkInTime.format(context)}. Tekan untuk tukar.',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickTime,
                          child: Container(
                            width: double.infinity,
                            constraints:
                                const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: KampungCareTheme.calmBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: KampungCareTheme.calmBlue,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.alarm_rounded,
                                  size: 32,
                                  color: KampungCareTheme.calmBlue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _checkInTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: KampungCareTheme.calmBlue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 24,
                                  color: KampungCareTheme.calmBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Voice speed slider
                  _SettingsCard(
                    title: S.isEnglish ? 'Voice Speed' : 'Kelajuan Suara',
                    icon: Icons.speed_rounded,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              S.isEnglish ? 'Slow' : 'Perlahan',
                              style: const TextStyle(
                                fontSize: 18,
                                color: KampungCareTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _voiceSpeed <= 0.4
                                  ? (S.isEnglish ? 'Slow' : 'Perlahan')
                                  : _voiceSpeed <= 0.6
                                      ? (S.isEnglish ? 'Normal' : 'Sederhana')
                                      : (S.isEnglish ? 'Fast' : 'Cepat'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: KampungCareTheme.textPrimary,
                              ),
                            ),
                            Text(
                              S.isEnglish ? 'Fast' : 'Cepat',
                              style: const TextStyle(
                                fontSize: 18,
                                color: KampungCareTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: S.isEnglish
                              ? 'Voice speed. Currently ${_voiceSpeed <= 0.4 ? 'slow' : _voiceSpeed <= 0.6 ? 'normal' : 'fast'}.'
                              : 'Kelajuan suara. Sekarang ${_voiceSpeed <= 0.4 ? 'perlahan' : _voiceSpeed <= 0.6 ? 'sederhana' : 'cepat'}.',
                          slider: true,
                          child: SliderTheme(
                            data: SliderThemeData(
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 16),
                              trackHeight: 8,
                              activeTrackColor: KampungCareTheme.primaryGreen,
                              inactiveTrackColor:
                                  KampungCareTheme.primaryGreen.withValues(alpha: 0.2),
                              thumbColor: KampungCareTheme.primaryGreen,
                              overlayColor:
                                  KampungCareTheme.primaryGreen.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: _voiceSpeed,
                              min: 0.3,
                              max: 0.8,
                              divisions: 5,
                              onChanged: (value) {
                                setState(() => _voiceSpeed = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  Semantics(
                    button: true,
                    label: S.isEnglish ? 'Save settings' : 'Simpan tetapan',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isSaving ? null : _saveSettings,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 80),
                          decoration: BoxDecoration(
                            color: _isSaving
                                ? KampungCareTheme.primaryGreen.withValues(alpha: 0.5)
                                : KampungCareTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: KampungCareTheme.primaryGreen
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.save_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                _isSaving ? S.silaTunggu : S.simpan,
                                style: const TextStyle(
                                  fontSize: AppConstants.buttonTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

/// Settings card wrapper with title and icon.
class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: KampungCareTheme.textPrimary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KampungCareTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
