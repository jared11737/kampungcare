import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/alert.dart';

/// Alert display card with severity-colored left border.
/// Shows alert type icon, message, timestamp, status badge, and acknowledge button.
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onAcknowledge;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case AlertSeverity.red:
        return KampungCareTheme.urgentRed;
      case AlertSeverity.yellow:
        return KampungCareTheme.warningAmber;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case AlertType.missedCheckin:
        return Icons.event_busy;
      case AlertType.sos:
        return Icons.emergency;
      case AlertType.patternAnomaly:
        return Icons.trending_down;
      case AlertType.missedMedication:
        return Icons.medication;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case AlertType.missedCheckin:
        return 'Terlepas Daftar Masuk';
      case AlertType.sos:
        return 'Kecemasan SOS';
      case AlertType.patternAnomaly:
        return 'Anomali Corak';
      case AlertType.missedMedication:
        return 'Terlepas Ubat';
    }
  }

  String get _statusLabel {
    switch (alert.status) {
      case AlertStatus.pending:
        return 'Menunggu';
      case AlertStatus.acknowledged:
        return 'Dimaklumkan';
      case AlertStatus.resolved:
        return 'Selesai';
    }
  }

  Color get _statusColor {
    switch (alert.status) {
      case AlertStatus.pending:
        return KampungCareTheme.warningAmber;
      case AlertStatus.acknowledged:
        return KampungCareTheme.calmBlue;
      case AlertStatus.resolved:
        return KampungCareTheme.primaryGreen;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Amaran: $_typeLabel. ${alert.message}. Status: $_statusLabel',
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _severityColor,
                width: 6,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icon + type label + status badge
                Row(
                  children: [
                    Icon(
                      _typeIcon,
                      size: 32,
                      color: _severityColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _severityColor,
                        ),
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 20,
                    color: KampungCareTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimestamp(alert.createdAt),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                // Acknowledge button when pending
                if (alert.status == AlertStatus.pending &&
                    onAcknowledge != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      button: true,
                      label: 'Maklumkan amaran ini',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onAcknowledge!();
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: KampungCareTheme.calmBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: KampungCareTheme.calmBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 28,
                                  color: KampungCareTheme.textOnDark,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Maklumkan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: KampungCareTheme.textOnDark,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor, width: 1.5),
      ),
      child: Text(
        _statusLabel,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _statusColor,
        ),
      ),
    );
  }
}
