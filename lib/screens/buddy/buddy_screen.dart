import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../services/service_locator.dart';
import '../../data/mock_data.dart';
import '../../widgets/status_indicator.dart';

class BuddyScreen extends StatelessWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final elderly = MockData.elderlyUser;
    final alerts = MockData.alerts;

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        title: const Text('KampungCare — Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ServiceLocator.auth.signOut();
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jiran yang Dijaga',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Elderly person card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: KampungCareTheme.primaryGreen.withOpacity(0.2),
                        child: const Icon(Icons.elderly, size: 36, color: KampungCareTheme.primaryGreen),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              elderly.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              elderly.address,
                              style: const TextStyle(fontSize: 18, color: KampungCareTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const StatusIndicator(status: 'green'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Panggil ${elderly.name}',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              final uri = Uri.parse('tel:${elderly.phone}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            icon: const Icon(Icons.phone, size: 24),
                            label: const Text('Panggil', style: TextStyle(fontSize: 20)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KampungCareTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 64),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Semantics(
                          label: 'Saya pergi tengok',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Terima kasih! Penjaga telah dimaklumkan.',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  backgroundColor: KampungCareTheme.primaryGreen,
                                ),
                              );
                            },
                            icon: const Icon(Icons.directions_walk, size: 24),
                            label: const Text('Pergi Tengok', style: TextStyle(fontSize: 20)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KampungCareTheme.calmBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 64),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification history
            const Text(
              'Sejarah Notifikasi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...alerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: alert.severity.name == 'red'
                              ? KampungCareTheme.urgentRed
                              : KampungCareTheme.warningAmber,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.message,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${BmStrings.malayDate(alert.createdAt)} — ${alert.status.name == 'resolved' ? 'Selesai' : 'Aktif'}',
                          style: const TextStyle(fontSize: 16, color: KampungCareTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )),

            if (alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Tiada notifikasi',
                    style: TextStyle(fontSize: 20, color: KampungCareTheme.textSecondary),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Switch role button
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.go(AppRoutes.login);
                },
                child: const Text(
                  'Tukar Peranan',
                  style: TextStyle(fontSize: 20, color: KampungCareTheme.calmBlue),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
