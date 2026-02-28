import '../../models/medication.dart';
import '../../models/medication_log.dart';
import '../database/database_service_base.dart';
import '../notification/notification_service_base.dart';

/// Medication status for today's view.
class TodayMedication {
  final Medication medication;
  final String scheduledTime;
  final MedicationLog? log; // null if not yet due / not logged
  final bool isTaken;
  final bool isDue; // true if scheduled time has passed

  const TodayMedication({
    required this.medication,
    required this.scheduledTime,
    this.log,
    this.isTaken = false,
    this.isDue = false,
  });
}

/// Logic layer for medication tracking.
/// Works with any [DatabaseServiceBase] implementation.
class MedicationService {
  final DatabaseServiceBase _db;
  final NotificationServiceBase _notifications;

  MedicationService({
    required DatabaseServiceBase db,
    required NotificationServiceBase notifications,
  })  : _db = db,
        _notifications = notifications;

  /// Get today's medications with their current status.
  /// Combines medication schedule with today's logs to show
  /// which meds have been taken and which are still due.
  Future<List<TodayMedication>> getTodayMedications(String uid) async {
    final medications = await _db.getMedications(uid);
    final logs = await _db.getMedicationLogs(uid, days: 1);

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final todayMeds = <TodayMedication>[];

    for (final med in medications) {
      for (final time in med.times) {
        // Find matching log for this medication at this time today
        final matchingLog = logs.where((log) =>
            log.medicationId == med.id &&
            log.scheduledTime == time &&
            log.status == MedicationStatus.taken).firstOrNull;

        todayMeds.add(TodayMedication(
          medication: med,
          scheduledTime: time,
          log: matchingLog,
          isTaken: matchingLog != null,
          isDue: currentTime.compareTo(time) >= 0,
        ));
      }
    }

    // Sort by scheduled time
    todayMeds.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return todayMeds;
  }

  /// Confirm a medication as taken.
  /// Creates a medication log entry with the current time.
  /// [photoVerified] indicates if the photo verification was completed.
  Future<void> confirmMedication(
    String uid,
    String medId, {
    bool photoVerified = false,
    Map<String, dynamic>? geminiVerification,
  }) async {
    final now = DateTime.now();
    final scheduledTime = '${now.hour.toString().padLeft(2, '0')}:00';

    final log = MedicationLog(
      id: 'mlog_${now.millisecondsSinceEpoch}',
      medicationId: medId,
      scheduledTime: scheduledTime,
      takenTime: now,
      status: MedicationStatus.taken,
      photoVerified: photoVerified,
      geminiVerification: geminiVerification,
    );

    await _db.saveMedicationLog(uid, log);
    print('[MedicationService] Confirmed: $medId at $now');
  }

  /// Snooze a medication reminder by 10 minutes.
  /// Reschedules the notification for 10 minutes from now.
  Future<void> snoozeMedication(String uid, String medId) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));

    // Find the medication name for the notification
    final medications = await _db.getMedications(uid);
    final med = medications.where((m) => m.id == medId).firstOrNull;
    final medName = med?.name ?? 'Ubat';

    await _notifications.scheduleMedicationReminder(
      medId,
      medName,
      snoozeTime,
    );

    print('[MedicationService] Snoozed $medId for 10 minutes (until $snoozeTime)');
  }
}
