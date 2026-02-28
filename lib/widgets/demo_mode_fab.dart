import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/user_profile.dart';
import '../services/service_locator.dart';

/// Floating action button for quick role switching and demo scenarios.
/// Shows a small icon that expands into a bottom sheet with 7 options:
/// 3 role switches + 4 demo scenario launchers.
class DemoModeFab extends StatelessWidget {
  const DemoModeFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'demo_fab',
      backgroundColor: Colors.black54,
      onPressed: () => _showRoleSwitcher(context),
      child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: KampungCareTheme.warmWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tukar Peranan (Demo)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // === Role buttons (1-3) ===
            _roleButton(ctx, 'Mak Cik Siti — Warga Emas', Icons.elderly,
                KampungCareTheme.primaryGreen, UserRole.elderly),
            const SizedBox(height: 12),
            _roleButton(ctx, 'Aisyah — Penjaga', Icons.supervisor_account,
                KampungCareTheme.calmBlue, UserRole.caregiver),
            const SizedBox(height: 12),
            _roleButton(ctx, 'Kak Zainab — Buddy', Icons.people,
                KampungCareTheme.warningAmber, UserRole.buddy),

            // === Divider ===
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Demo Senario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: KampungCareTheme.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider(thickness: 1.5)),
              ],
            ),
            const SizedBox(height: 16),

            // === Demo scenario buttons (4-7) ===
            _demoButton(
              ctx,
              'Demo: Check-in Pagi',
              Icons.wb_sunny_rounded,
              KampungCareTheme.primaryGreen,
              () => _launchDemoChat(ctx, 'check_in'),
            ),
            const SizedBox(height: 12),
            _demoButton(
              ctx,
              'Demo: Cerita Mode',
              Icons.auto_stories_rounded,
              KampungCareTheme.calmBlue,
              () => _launchDemoChat(ctx, 'cerita'),
            ),
            const SizedBox(height: 12),
            _demoButton(
              ctx,
              'Demo: Ubat Salah',
              Icons.medication_rounded,
              KampungCareTheme.urgentRed,
              () => _launchWrongPillDemo(ctx),
            ),
            const SizedBox(height: 12),
            _demoButton(
              ctx,
              'Demo: Cognitive Concern',
              Icons.psychology_rounded,
              KampungCareTheme.warningAmber,
              () => _launchDemoChat(ctx, 'concerning'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Ensure we are signed in as elderly, then navigate to voice chat
  /// with conversation reset for the given type.
  Future<void> _launchDemoChat(BuildContext context, String chatType) async {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(); // close bottom sheet

    // Sign in as elderly if not already
    final currentUser = ServiceLocator.auth.currentUser;
    if (currentUser == null || currentUser.role != UserRole.elderly) {
      await ServiceLocator.auth.signInAs(UserRole.elderly);
    }

    // Reset the AI conversation for this type
    ServiceLocator.mockAi.resetConversation(chatType);

    if (!context.mounted) return;
    context.go('${AppRoutes.voiceChat}?type=$chatType');
  }

  /// Force wrong pill detection then navigate to medication camera.
  Future<void> _launchWrongPillDemo(BuildContext context) async {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(); // close bottom sheet

    // Sign in as elderly if not already
    final currentUser = ServiceLocator.auth.currentUser;
    if (currentUser == null || currentUser.role != UserRole.elderly) {
      await ServiceLocator.auth.signInAs(UserRole.elderly);
    }

    // Set the flag so the next verification returns wrong pill
    ServiceLocator.mockAi.forceWrongPill = true;

    if (!context.mounted) return;
    context.go(AppRoutes.medicationCamera);
  }

  Widget _roleButton(BuildContext context, String label, IconData icon,
      Color color, UserRole role) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          await ServiceLocator.auth.signInAs(role);
          if (!context.mounted) return;
          switch (role) {
            case UserRole.elderly:
              context.go(AppRoutes.elderlyHome);
            case UserRole.caregiver:
              context.go(AppRoutes.caregiverDashboard);
            case UserRole.buddy:
              context.go(AppRoutes.buddyHome);
          }
        },
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _demoButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
