import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../data/mock_data.dart';
import '../../models/medication.dart';
import '../../providers/settings_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/medication_card.dart';

/// A group of medications sharing the same time slot.
class _TimeSlot {
  final String time; // e.g. '07:00'
  final bool isMorning; // true = morning (<14:00), false = evening
  final List<Medication> medications;

  const _TimeSlot({
    required this.time,
    required this.isMorning,
    required this.medications,
  });

  /// Localised label ('Pagi' / 'Morning', 'Malam' / 'Evening').
  String get label => isMorning ? S.ubatPagi : S.ubatMalam;
}

/// Medication screen showing today's medication list grouped by time slot.
/// Each slot has a header ("Ubat Pagi (7:00)") and shows pills with status.
class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  List<Medication> _medications = [];
  List<_TimeSlot> _timeSlots = [];
  final Map<String, String> _medicationStatus = {}; // medId -> status
  bool _isLoading = true;
  int _takenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  /// Determine whether a time string is morning (before 14:00) or evening.
  bool _isMorning(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 7;
    return hour < 14;
  }

  /// Group medications into time slots, sorted by time.
  List<_TimeSlot> _buildTimeSlots(List<Medication> meds) {
    // Collect all unique times from all medications
    final Map<String, List<Medication>> grouped = {};
    for (final med in meds) {
      for (final time in med.times) {
        grouped.putIfAbsent(time, () => []);
        grouped[time]!.add(med);
      }
    }

    // Sort times chronologically
    final sortedTimes = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return sortedTimes.map((time) {
      return _TimeSlot(
        time: time,
        isMorning: _isMorning(time),
        medications: grouped[time]!,
      );
    }).toList();
  }

  Future<void> _loadMedications() async {
    final user = ServiceLocator.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final meds = await ServiceLocator.database.getMedications(user.uid);
      _initMedications(meds);
    } catch (e) {
      print('[MedicationScreen] Error loading meds: $e');
      // Fallback to mock data
      _initMedications(MockData.medications);
    }
  }

  void _initMedications(List<Medication> meds) {
    // Initialize statuses — first med as taken (demo), rest as pending
    final statuses = <String, String>{};
    int taken = 0;
    final seenIds = <String>{};
    for (int i = 0; i < meds.length; i++) {
      if (seenIds.contains(meds[i].id)) continue;
      seenIds.add(meds[i].id);
      if (i == 0) {
        statuses[meds[i].id] = 'taken';
        taken++;
      } else {
        statuses[meds[i].id] = 'pending';
      }
    }

    final timeSlots = _buildTimeSlots(meds);

    setState(() {
      _medications = meds;
      _timeSlots = timeSlots;
      _medicationStatus.addAll(statuses);
      _takenCount = taken;
      _isLoading = false;
    });
  }

  void _markAsTaken(String medId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _medicationStatus[medId] = 'taken';
      _takenCount = _medicationStatus.values.where((s) => s == 'taken').length;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.isEnglish ? 'Well done! Medicine recorded.' : 'Bagus! Ubat sudah dicatat.',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: KampungCareTheme.primaryGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openCamera(String medId) {
    HapticFeedback.mediumImpact();
    context.push('${AppRoutes.medicationCamera}?medId=$medId');
  }

  /// Count unique medication IDs across all time slots.
  int get _totalUniqueMeds {
    final ids = <String>{};
    for (final med in _medications) {
      ids.add(med.id);
    }
    return ids.length;
  }

  @override
  Widget build(BuildContext context) {
    // Watch settings so UI rebuilds when language toggles.
    ref.watch(settingsProvider);

    final totalMeds = _totalUniqueMeds;
    final adherencePercent = totalMeds == 0
        ? 0
        : ((_takenCount / totalMeds) * 100).round();

    return Scaffold(
      backgroundColor: KampungCareTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: KampungCareTheme.primaryGreen,
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
          S.isEnglish ? "Today's Medicine" : 'Ubat Hari Ini',
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
                    color: KampungCareTheme.primaryGreen,
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
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Semantics(
                      label: S.date(DateTime.now()),
                      child: Text(
                        S.date(DateTime.now()),
                        style: const TextStyle(
                          fontSize: AppConstants.minTextSize,
                          color: KampungCareTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medication cards grouped by time slot
                  if (_timeSlots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          S.isEnglish
                              ? 'No medicines scheduled now'
                              : 'Tiada ubat dijadualkan sekarang',
                          style: const TextStyle(
                            fontSize: AppConstants.minTextSize,
                            color: KampungCareTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...(_timeSlots.map((slot) {
                      return _buildTimeSlotSection(slot);
                    })),

                  const SizedBox(height: 24),

                  // Adherence this week
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Semantics(
                      label: S.isEnglish
                          ? 'Medicine adherence this week: $adherencePercent percent'
                          : 'Kadar ubat minggu ini: $adherencePercent peratus',
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
                            Text(
                              S.isEnglish ? "This Week's Medicine" : 'Ubat Minggu Ini',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: KampungCareTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: adherencePercent / 100,
                                minHeight: 16,
                                backgroundColor:
                                    KampungCareTheme.primaryGreen.withValues(alpha: 0.15),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  KampungCareTheme.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              S.isEnglish
                                  ? 'Today: $_takenCount / $totalMeds taken ($adherencePercent%)'
                                  : 'Hari ini: $_takenCount / $totalMeds ubat sudah diambil ($adherencePercent%)',
                              style: const TextStyle(
                                fontSize: AppConstants.minTextSize,
                                color: KampungCareTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Minggu ini: 90% (19/21 dos)',
                              style: TextStyle(
                                fontSize: AppConstants.minTextSize,
                                color: KampungCareTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build a full time-slot section with header and medication cards.
  Widget _buildTimeSlotSection(_TimeSlot slot) {
    final headerColor = slot.isMorning
        ? KampungCareTheme.warningAmber
        : KampungCareTheme.calmBlue;
    final headerIcon =
        slot.isMorning ? Icons.wb_sunny_rounded : Icons.nightlight_round;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time slot header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Semantics(
            header: true,
            label: '${S.isEnglish ? "Medicine" : "Ubat"} ${slot.label}, '
                '${S.isEnglish ? "at" : "pukul"} ${slot.time}',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: headerColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    headerIcon,
                    size: 30,
                    color: headerColor,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time_rounded,
                    size: 24,
                    color: headerColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${slot.label} (${slot.time})',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KampungCareTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${slot.medications.length} ${S.isEnglish ? "med(s)" : "ubat"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Medication cards for this slot
        ...(slot.medications.map((med) {
          final status = _medicationStatus[med.id] ?? 'pending';
          return MedicationCard(
            medication: med,
            status: status,
            onTaken: status == 'pending'
                ? () => _markAsTaken(med.id)
                : null,
            onPhoto: status == 'pending'
                ? () => _openCamera(med.id)
                : null,
          );
        })),

        const SizedBox(height: 8),
      ],
    );
  }
}
