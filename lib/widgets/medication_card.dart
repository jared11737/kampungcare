import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/medication.dart';

/// Card displaying a medication with status and action buttons.
/// Supports pending/taken/missed states with elderly-friendly design.
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final String status; // 'pending', 'taken', 'missed'
  final VoidCallback? onTaken;
  final VoidCallback? onPhoto;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.status,
    this.onTaken,
    this.onPhoto,
  });

  Color get _statusColor {
    switch (status) {
      case 'taken':
        return KampungCareTheme.primaryGreen;
      case 'missed':
        return KampungCareTheme.urgentRed;
      case 'pending':
      default:
        return KampungCareTheme.warningAmber;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.access_time;
    }
  }

  String get _statusLabel {
    if (S.isEnglish) {
      return switch (status) {
        'taken' => 'Taken',
        'missed' => 'Missed',
        _ => 'Pending',
      };
    }
    return switch (status) {
      'taken' => 'Sudah Diambil',
      'missed' => 'Terlepas',
      _ => 'Belum Diambil',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${S.isEnglish ? "Medicine" : "Ubat"} ${medication.name}, ${medication.dosage}, '
          '${S.isEnglish ? "Status" : "Status"}: $_statusLabel',
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: medication name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Dosage
              Text(
                medication.dosage,
                style: const TextStyle(
                  fontSize: 20,
                  color: KampungCareTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Pill description
              if (medication.pillDescription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.medication, size: 24, color: KampungCareTheme.calmBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medication.pillDescription,
                          style: const TextStyle(
                            fontSize: 20,
                            color: KampungCareTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Instructions
              if (medication.instructions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 24, color: KampungCareTheme.warningAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medication.instructions,
                          style: const TextStyle(
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            color: KampungCareTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons when pending
              if (status == 'pending') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: S.sudahAmbil,
                        icon: Icons.check,
                        color: KampungCareTheme.primaryGreen,
                        onTap: onTaken,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: S.ambilGambar,
                        icon: Icons.camera_alt,
                        color: KampungCareTheme.calmBlue,
                        onTap: onPhoto,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 22, color: _statusColor),
          const SizedBox(width: 6),
          Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal action button used for medication card actions.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onTap!();
                }
              : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: KampungCareTheme.textOnDark),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KampungCareTheme.textOnDark,
                    ),
                    overflow: TextOverflow.ellipsis,
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
