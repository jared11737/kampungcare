import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/mock_data.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = MockData.weeklySummaryData;

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(title: const Text('Laporan Mingguan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BM Summary
            _sectionCard(
              'Ringkasan (Bahasa Melayu)',
              summary['summary_bm'] as String,
              KampungCareTheme.primaryGreen,
            ),
            const SizedBox(height: 16),

            // EN Summary
            _sectionCard(
              'Summary (English)',
              summary['summary_en'] as String,
              KampungCareTheme.calmBlue,
            ),
            const SizedBox(height: 16),

            // Highlight
            _sectionCard(
              'Perkara Gembira',
              summary['highlight'] as String,
              KampungCareTheme.primaryGreen,
              icon: Icons.star,
            ),
            const SizedBox(height: 16),

            // Concern
            if (summary['concern'] != null)
              _sectionCard(
                'Perlu Perhatian',
                summary['concern'] as String,
                KampungCareTheme.warningAmber,
                icon: Icons.warning_amber,
              ),
            const SizedBox(height: 16),

            // Suggested action
            _sectionCard(
              'Cadangan',
              summary['suggested_action'] as String,
              KampungCareTheme.calmBlue,
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: 16),

            // Shared story
            if (summary['shared_story'] != null)
              _sectionCard(
                'Cerita Dikongsi',
                summary['shared_story'] as String,
                KampungCareTheme.warningAmber,
                icon: Icons.menu_book,
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, String content, Color accentColor, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              if (icon != null) ...[
                Icon(icon, size: 24, color: accentColor),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 20, height: 1.6),
          ),
        ],
      ),
    );
  }
}
