import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/health_log.dart';
import '../../providers/settings_provider.dart';
import '../../services/service_locator.dart';

/// Health screen showing mood, sleep, and pain trends over 7 days,
/// plus a list of recent health log entries.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  List<HealthLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthLogs();
  }

  Future<void> _loadHealthLogs() async {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final logs = await ServiceLocator.database.getHealthLogs(user.uid, days: 14);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print('[HealthScreen] Error loading logs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: KampungCareTheme.warningAmber,
        foregroundColor: KampungCareTheme.textPrimary,
        leading: Semantics(
          button: true,
          label: 'Kembali ke halaman utama',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.elderlyHome);
            },
          ),
        ),
        title: Text(
          S.isEnglish ? 'My Health' : 'Kesihatan Saya',
          style: const TextStyle(
            fontSize: AppConstants.headerTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: KampungCareTheme.warningAmber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    S.silaTunggu,
                    style: const TextStyle(
                      fontSize: AppConstants.minTextSize,
                      color: KampungCareTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Mood chart (7 days)
                  _SimpleTrendCard(
                    title: 'Mood',
                    icon: Icons.sentiment_satisfied_rounded,
                    color: KampungCareTheme.primaryGreen,
                    data: _getLast7DaysData((log) => log.mood),
                    maxValue: 5,
                    valueLabels: S.moodLabels,
                  ),
                  const SizedBox(height: 16),

                  // Sleep chart (7 days)
                  _SimpleTrendCard(
                    title: S.isEnglish ? 'Sleep' : 'Tidur',
                    icon: Icons.bedtime_rounded,
                    color: KampungCareTheme.calmBlue,
                    data: _getLast7DaysData((log) => log.sleepQuality),
                    maxValue: 5,
                    valueLabels: S.sleepLabels,
                  ),
                  const SizedBox(height: 16),

                  // Knee Pain chart (7 days)
                  _SimpleTrendCard(
                    title: S.isEnglish ? 'Knee Pain' : 'Sakit Lutut',
                    icon: Icons.accessibility_new_rounded,
                    color: KampungCareTheme.urgentRed,
                    data: _getLast7DaysData(
                        (log) => log.painLevel['knee'] ?? 0),
                    maxValue: 5,
                    valueLabels: S.painLabels,
                    invertColor: true, // Higher is worse
                  ),
                  const SizedBox(height: 24),

                  // Recent health log entries
                  Text(
                    S.isEnglish ? 'Recent Records' : 'Rekod Terkini',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: KampungCareTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        S.isEnglish ? 'No health records' : 'Tiada rekod kesihatan',
                        style: const TextStyle(
                          fontSize: AppConstants.minTextSize,
                          color: KampungCareTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    ..._logs.take(7).map((log) => _HealthLogCard(log: log)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Extract last 7 days of a specific metric from health logs.
  List<_DataPoint> _getLast7DaysData(int Function(HealthLog) extractor) {
    final points = <_DataPoint>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayStr = _shortDayName(targetDate.weekday);

      // Find a log for this day
      final log = _logs.where((l) =>
          l.timestamp.year == targetDate.year &&
          l.timestamp.month == targetDate.month &&
          l.timestamp.day == targetDate.day).toList();

      if (log.isNotEmpty) {
        points.add(_DataPoint(label: dayStr, value: extractor(log.first)));
      } else {
        points.add(_DataPoint(label: dayStr, value: 0));
      }
    }
    return points;
  }

  String _shortDayName(int weekday) {
    return S.dayLabels[weekday - 1];
  }
}

/// Simple data point for the trend chart.
class _DataPoint {
  final String label;
  final int value;
  const _DataPoint({required this.label, required this.value});
}

/// Simple trend card with a bar chart visualization.
/// Avoids fl_chart dependency for simplicity (hackathon).
class _SimpleTrendCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_DataPoint> data;
  final int maxValue;
  final List<String> valueLabels;
  final bool invertColor;

  const _SimpleTrendCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.data,
    required this.maxValue,
    this.valueLabels = const [],
    this.invertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final latestValue = data.isNotEmpty ? data.last.value : 0;
    final latestLabel = latestValue > 0 && latestValue <= valueLabels.length
        ? valueLabels[latestValue - 1]
        : '-';

    return Semantics(
      label: S.isEnglish
          ? '$title: 7-day trend. Today: $latestLabel'
          : '$title: 7 hari trend. Hari ini: $latestLabel',
      child: Container(
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
            // Header
            Row(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  latestLabel,
                  style: TextStyle(
                    fontSize: AppConstants.minTextSize,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Simple bar chart
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((point) {
                  final normalizedHeight = maxValue > 0
                      ? (point.value / maxValue).clamp(0.0, 1.0)
                      : 0.0;
                  final barColor = invertColor
                      ? Color.lerp(KampungCareTheme.primaryGreen, color,
                          normalizedHeight)!
                      : Color.lerp(
                          color.withValues(alpha: 0.3), color, normalizedHeight)!;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (normalizedHeight * 50).clamp(4.0, 50.0),
                            decoration: BoxDecoration(
                              color: point.value == 0
                                  ? Colors.grey.shade200
                                  : barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            point.label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: KampungCareTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual health log entry card.
class _HealthLogCard extends StatelessWidget {
  final HealthLog log;

  const _HealthLogCard({required this.log});

  String _moodEmoji(int mood) {
    return switch (mood) {
      5 => '\u{1F604}',
      4 => '\u{1F60A}',
      3 => '\u{1F610}',
      2 => '\u{1F614}',
      1 => '\u{1F622}',
      _ => '\u{1F610}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = S.date(log.timestamp);
    final kneePain = log.painLevel['knee'] ?? 0;

    return Semantics(
      label: S.isEnglish
          ? 'Record $dateStr. Mood: ${log.mood} out of 5. ${log.notes}'
          : 'Rekod $dateStr. Mood: ${log.mood} daripada 5. ${log.notes}',
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + mood emoji
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _moodEmoji(log.mood),
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick stats row
              Row(
                children: [
                  _StatChip(
                    label: S.isEnglish ? 'Sleep' : 'Tidur',
                    value: '${log.sleepQuality}/5',
                    color: KampungCareTheme.calmBlue,
                  ),
                  const SizedBox(width: 8),
                  if (kneePain > 0)
                    _StatChip(
                      label: S.isEnglish ? 'Knee' : 'Lutut',
                      value: '$kneePain/5',
                      color: kneePain >= 4
                          ? KampungCareTheme.urgentRed
                          : KampungCareTheme.warningAmber,
                    ),
                ],
              ),

              // Notes
              if (log.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  log.notes,
                  style: const TextStyle(
                    fontSize: 18,
                    color: KampungCareTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small stat chip widget.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
