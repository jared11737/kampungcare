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
import '../../widgets/health_trend_chart.dart';
import '../../widgets/alert_card.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final _caregiverView = MockData.caregiverView;
  final _healthLogs = MockData.healthLogs;
  final _alerts = MockData.alerts;
  final _elderly = MockData.elderlyUser;
  final _weeklySummaryData = MockData.weeklySummaryData;

  // Pattern analysis dismissal
  bool _patternWarningDismissed = false;

  List<double> _getMoodData() {
    final recent = _healthLogs.length > 7
        ? _healthLogs.sublist(_healthLogs.length - 7)
        : _healthLogs;
    return recent.map((l) => l.mood.toDouble()).toList();
  }

  List<double> _getSleepData() {
    final recent = _healthLogs.length > 7
        ? _healthLogs.sublist(_healthLogs.length - 7)
        : _healthLogs;
    return recent.map((l) => l.sleepQuality.toDouble()).toList();
  }

  List<double> _getPainData() {
    final recent = _healthLogs.length > 7
        ? _healthLogs.sublist(_healthLogs.length - 7)
        : _healthLogs;
    return recent.map((l) => (l.painLevel['knee'] ?? 0).toDouble()).toList();
  }

  Future<void> _callElderlyPhone() async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:${_elderly.phone}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('[Dashboard] Error calling: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        title: const Text('Dashboard Penjaga'),
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
            // ======== Pattern Analysis Warning Card ========
            if (!_patternWarningDismissed) _buildPatternWarningCard(),

            // Elderly person status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                        backgroundColor:
                            KampungCareTheme.primaryGreen.withValues(alpha: 0.2),
                        child: const Icon(Icons.elderly,
                            size: 36, color: KampungCareTheme.primaryGreen),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _elderly.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            StatusIndicator(
                                status: _caregiverView.currentStatus),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.access_time, 'Check-in terakhir',
                      '${_caregiverView.lastCheckIn.hour}:${_caregiverView.lastCheckIn.minute.toString().padLeft(2, '0')} hari ini'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.medication, 'Ubat hari ini',
                      '${_caregiverView.todayMedsTaken}/${_caregiverView.todayMedsScheduled} diambil'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.mood, 'Purata mood minggu ini',
                      '${_caregiverView.weeklyMoodAvg}/5'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Panggil Mak Cik',
                    Icons.phone,
                    KampungCareTheme.primaryGreen,
                    () async {
                      HapticFeedback.mediumImpact();
                      final uri = Uri.parse('tel:${_elderly.phone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    'Laporan Mingguan',
                    Icons.description,
                    KampungCareTheme.calmBlue,
                    () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.weeklyReport);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'Cerita Dikongsi',
                    Icons.menu_book,
                    KampungCareTheme.warningAmber,
                    () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.stories);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    'Tukar Peranan',
                    Icons.swap_horiz,
                    KampungCareTheme.textSecondary,
                    () {
                      HapticFeedback.mediumImpact();
                      context.go(AppRoutes.login);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ======== Weekly Summary Card ========
            _buildWeeklySummaryCard(),
            const SizedBox(height: 24),

            // Trend charts
            const Text(
              'Trend Minggu Ini',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            HealthTrendChart(
              title: 'Mood',
              data: _getMoodData(),
              color: KampungCareTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            HealthTrendChart(
              title: 'Tidur',
              data: _getSleepData(),
              color: KampungCareTheme.calmBlue,
            ),
            const SizedBox(height: 16),
            HealthTrendChart(
              title: 'Sakit Lutut',
              data: _getPainData(),
              color: KampungCareTheme.urgentRed,
            ),
            const SizedBox(height: 24),

            // ======== Alert History Timeline ========
            _buildAlertHistorySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ======== Pattern Analysis Warning Card ========
  Widget _buildPatternWarningCard() {
    return Semantics(
      label:
          'Amaran: Gemini mengesan corak membimbangkan mengenai sakit lutut dan ubat terlepas',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(
              color: KampungCareTheme.warningAmber,
              width: 6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: KampungCareTheme.warningAmber.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 28,
                    color: KampungCareTheme.warningAmber,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gemini Mengesan Corak Membimbangkan',
                      style: TextStyle(
                        fontSize: AppConstants.minTextSize,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description
              const Text(
                'Sakit lutut Mak Cik Siti semakin teruk sejak 3 hari lepas dan menjejaskan kualiti tidur. Pematuhan ubat juga terjejas \u2014 2 dos terlepas minggu ini.',
                style: TextStyle(
                  fontSize: AppConstants.minTextSize,
                  color: KampungCareTheme.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Suggestion
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: KampungCareTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 22, color: KampungCareTheme.warningAmber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cadangan: Buat temujanji doktor untuk lutut',
                        style: TextStyle(
                          fontSize: AppConstants.minTextSize,
                          fontWeight: FontWeight.w600,
                          color: KampungCareTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Call button
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Hubungi Mak Cik melalui telefon',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _callElderlyPhone,
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppConstants.minTouchTarget,
                            ),
                            decoration: BoxDecoration(
                              color: KampungCareTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone, size: 22, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Hubungi Mak Cik',
                                  style: TextStyle(
                                    fontSize: AppConstants.minTextSize,
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
                  ),
                  const SizedBox(width: 12),
                  // Noted button
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Maklumkan amaran ini',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _patternWarningDismissed = true;
                            });
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: AppConstants.minTouchTarget,
                            ),
                            decoration: BoxDecoration(
                              color: KampungCareTheme.textSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 22, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Noted',
                                  style: TextStyle(
                                    fontSize: AppConstants.minTextSize,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== Weekly Summary Card ========
  Widget _buildWeeklySummaryCard() {
    final summaryBm = _weeklySummaryData['summary_bm'] as String? ?? '';
    final highlight = _weeklySummaryData['highlight'] as String? ?? '';
    final concern = _weeklySummaryData['concern'] as String? ?? '';
    final suggestion = _weeklySummaryData['suggested_action'] as String? ?? '';

    return Semantics(
      label: 'Ringkasan mingguan dijana oleh AI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 24, color: KampungCareTheme.calmBlue),
              SizedBox(width: 8),
              Text(
                'Ringkasan Mingguan (dijana oleh AI)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main summary text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: KampungCareTheme.calmBlue.withValues(alpha: 0.3)),
            ),
            child: Text(
              summaryBm,
              style: const TextStyle(
                fontSize: AppConstants.minTextSize,
                height: 1.6,
                color: KampungCareTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Highlight card (green left border)
          if (highlight.isNotEmpty)
            _summaryDetailCard(
              icon: Icons.lightbulb_rounded,
              label: 'Highlight',
              text: highlight,
              borderColor: KampungCareTheme.primaryGreen,
              iconColor: KampungCareTheme.primaryGreen,
            ),
          const SizedBox(height: 10),

          // Concern card (amber left border)
          if (concern.isNotEmpty)
            _summaryDetailCard(
              icon: Icons.warning_amber_rounded,
              label: 'Perhatian',
              text: concern,
              borderColor: KampungCareTheme.warningAmber,
              iconColor: KampungCareTheme.warningAmber,
            ),
          const SizedBox(height: 10),

          // Suggestion card (blue left border)
          if (suggestion.isNotEmpty)
            _summaryDetailCard(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Cadangan',
              text: suggestion,
              borderColor: KampungCareTheme.calmBlue,
              iconColor: KampungCareTheme.calmBlue,
            ),
        ],
      ),
    );
  }

  Widget _summaryDetailCard({
    required IconData icon,
    required String label,
    required String text,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppConstants.minTextSize,
              color: KampungCareTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ======== Alert History Timeline ========
  Widget _buildAlertHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded,
                size: 24, color: KampungCareTheme.textPrimary),
            SizedBox(width: 8),
            Text(
              'Sejarah Amaran',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_alerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Tiada amaran buat masa ini',
              style: TextStyle(
                fontSize: AppConstants.minTextSize,
                color: KampungCareTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertCard(alert: alert),
              )),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: KampungCareTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 18, color: KampungCareTheme.textSecondary)),
        Text(value,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
