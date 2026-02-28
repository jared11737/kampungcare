import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/routes.dart';
import '../providers/settings_provider.dart';
import '../services/service_locator.dart';
import '../models/user_profile.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  Future<void> _quickLogin(UserRole role) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    await ServiceLocator.auth.signInAs(role);

    // Schedule demo notifications for elderly
    if (role == UserRole.elderly) {
      final now = DateTime.now();
      ServiceLocator.notification.scheduleMedicationReminder(
        'metformin_001',
        'Metformin 500mg',
        now.add(const Duration(minutes: 2)),
      );
      ServiceLocator.notification.scheduleCheckInReminder(
        now.add(const Duration(minutes: 5)),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    switch (role) {
      case UserRole.elderly:
        context.go(AppRoutes.elderlyHome);
      case UserRole.caregiver:
        context.go(AppRoutes.caregiverDashboard);
      case UserRole.buddy:
        context.go(AppRoutes.buddyHome);
    }
  }

  /// Malaysian phone format: +60 followed by 9-10 digits starting with 1-9
  static final _phoneRegex = RegExp(r'^\+60[1-9]\d{8,9}$');

  /// OTP: exactly 6 digits
  static final _otpRegex = RegExp(r'^\d{6}$');

  String? _phoneError;
  String? _otpError;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    // Validate Malaysian phone format
    if (!_phoneRegex.hasMatch(phone)) {
      setState(() => _phoneError = S.isEnglish ? 'Format: +60121234567' : 'Format nombor tidak sah');
      return;
    }

    setState(() => _phoneError = null);
    HapticFeedback.mediumImpact();
    setState(() {
      _otpSent = true;
      _loading = false;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    // Validate OTP is exactly 6 digits
    if (!_otpRegex.hasMatch(otp)) {
      setState(() => _otpError = 'Masukkan 6 digit kod');
      return;
    }

    setState(() => _otpError = null);
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    final user = await ServiceLocator.auth.signIn(
      _phoneController.text,
      _otpController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      // Schedule demo notifications for elderly
      if (user.role == UserRole.elderly) {
        final now = DateTime.now();
        ServiceLocator.notification.scheduleMedicationReminder(
          'metformin_001',
          'Metformin 500mg',
          now.add(const Duration(minutes: 2)),
        );
        ServiceLocator.notification.scheduleCheckInReminder(
          now.add(const Duration(minutes: 5)),
        );
      }

      switch (user.role) {
        case UserRole.elderly:
          context.go(AppRoutes.elderlyHome);
        case UserRole.caregiver:
          context.go(AppRoutes.caregiverDashboard);
        case UserRole.buddy:
          context.go(AppRoutes.buddyHome);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gradient Hero ──
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [KampungCareTheme.primaryGreen, Color(0xFF1B5E20)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 72, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppConstants.tagline,
                        style: TextStyle(fontSize: 15, color: Colors.white70, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              color: KampungCareTheme.warmWhite,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Demo login card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.isEnglish ? 'Quick Demo Login' : 'Demo — Masuk Pantas',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KampungCareTheme.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _roleButton(
                          S.isEnglish ? 'Aunty Siti (Elderly)' : 'Masuk sebagai Mak Cik Siti',
                          S.isEnglish ? 'Elderly resident, 74 years old' : 'Warga emas, 74 tahun',
                          Icons.elderly_rounded, KampungCareTheme.primaryGreen, UserRole.elderly,
                        ),
                        const SizedBox(height: 12),
                        _roleButton(
                          S.isEnglish ? 'Aisyah (Caregiver)' : 'Masuk sebagai Aisyah',
                          S.isEnglish ? 'Caregiver (daughter)' : 'Penjaga (anak perempuan)',
                          Icons.supervisor_account_rounded, KampungCareTheme.calmBlue, UserRole.caregiver,
                        ),
                        const SizedBox(height: 12),
                        _roleButton(
                          S.isEnglish ? 'Kak Zainab (Buddy)' : 'Masuk sebagai Kak Zainab',
                          S.isEnglish ? 'Buddy (neighbour)' : 'Buddy (jiran)',
                          Icons.people_rounded, KampungCareTheme.warningAmber, UserRole.buddy,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone login card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.isEnglish ? 'Sign in with Phone' : 'Masuk dengan Telefon',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KampungCareTheme.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            hintText: '+60121234567',
                            labelText: S.nomorTelefon,
                            prefixIcon: const Icon(Icons.phone_rounded, size: 28),
                            errorText: _phoneError,
                          ),
                          onChanged: (_) { if (_phoneError != null) setState(() => _phoneError = null); },
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 24),
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: '123456',
                              labelText: S.isEnglish ? 'OTP Code' : 'Kod OTP',
                              prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                              errorText: _otpError,
                            ),
                            onChanged: (_) { if (_otpError != null) setState(() => _otpError = null); },
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KampungCareTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(_otpSent ? S.masuk : S.hantarOtp,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Language toggle
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await ref.read(settingsProvider.notifier).setIsEnglish(!S.isEnglish);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language_rounded, size: 22, color: KampungCareTheme.calmBlue),
                            const SizedBox(width: 8),
                            Text(
                              S.isEnglish ? 'English | BM' : 'BM | English',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KampungCareTheme.calmBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(String name, String subtitle, IconData icon, Color color, UserRole role) {
    return Semantics(
      label: '$name. $subtitle',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : () => _quickLogin(role),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                      Text(subtitle, style: TextStyle(fontSize: 15, color: color.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}
