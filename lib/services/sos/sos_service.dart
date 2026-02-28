import '../../models/alert.dart';
import '../../models/care_network.dart';
import '../auth/auth_service_base.dart';
import '../database/database_service_base.dart';
import '../location/location_service_base.dart';
import '../notification/notification_service_base.dart';

/// Result of an SOS trigger, showing delivery status to each contact.
class SosDeliveryStatus {
  final bool sent;
  final Map<String, double>? location;
  final List<SosContactStatus> contactStatuses;
  final String alertId;

  const SosDeliveryStatus({
    required this.sent,
    this.location,
    this.contactStatuses = const [],
    required this.alertId,
  });
}

/// Delivery status for a single SOS contact.
class SosContactStatus {
  final String name;
  final String relation;
  final String phone;
  final bool notified;

  const SosContactStatus({
    required this.name,
    required this.relation,
    required this.phone,
    required this.notified,
  });
}

/// Logic layer for SOS emergency features.
/// Triggers emergency alerts, notifies care network, and includes location.
class SosService {
  final DatabaseServiceBase _db;
  final LocationServiceBase _location;
  final NotificationServiceBase _notifications;
  final AuthServiceBase _auth;

  /// Rate limiting: track last SOS trigger time per user.
  final Map<String, DateTime> _lastSosTrigger = {};

  /// Minimum interval between SOS triggers (60 seconds).
  static const _sosCooldown = Duration(seconds: 60);

  SosService({
    required DatabaseServiceBase db,
    required LocationServiceBase location,
    required NotificationServiceBase notifications,
    required AuthServiceBase auth,
  })  : _db = db,
        _location = location,
        _notifications = notifications,
        _auth = auth;

  /// Trigger an SOS emergency.
  /// Gets current location, creates a red alert, and sends notifications
  /// to all care network contacts. Returns delivery status.
  ///
  /// Security: Validates that the current user matches the requested UID
  /// and enforces rate limiting to prevent SOS spam.
  Future<SosDeliveryStatus> triggerSos(String uid) async {
    // Authorization: only the user themselves can trigger their own SOS
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      print('[SOS] DENIED — unauthorized trigger attempt');
      return const SosDeliveryStatus(
        sent: false,
        contactStatuses: [],
        alertId: '',
      );
    }

    // Rate limiting: prevent rapid-fire SOS triggers
    final lastTrigger = _lastSosTrigger[uid];
    if (lastTrigger != null &&
        DateTime.now().difference(lastTrigger) < _sosCooldown) {
      print('[SOS] RATE LIMITED — too soon since last trigger');
      return const SosDeliveryStatus(
        sent: false,
        contactStatuses: [],
        alertId: '',
      );
    }
    _lastSosTrigger[uid] = DateTime.now();

    print('[SOS] TRIGGERED');

    // Get location and care network in parallel
    final locationFuture = _location.getCurrentLocation();
    final networkFuture = _db.getCareNetwork(uid);
    final profileFuture = _db.getUserProfile(uid);

    final results = await Future.wait([
      locationFuture,
      networkFuture,
      profileFuture,
    ]);

    final location = results[0] as Map<String, double>?;
    final network = results[1] as CareNetwork?;
    final profile = results[2];

    final userName = profile != null ? (profile as dynamic).name : 'Pengguna';
    final alertId = 'sos_${DateTime.now().millisecondsSinceEpoch}';

    // Create red alert (location stored separately, not in message text)
    final alert = Alert(
      id: alertId,
      elderlyUid: uid,
      type: AlertType.sos,
      severity: AlertSeverity.red,
      message: 'KECEMASAN! $userName perlukan bantuan segera!',
      status: AlertStatus.pending,
      createdAt: DateTime.now(),
    );

    await _db.createAlert(alert);

    // Show SOS notification locally
    await _notifications.showSosAlert(alert.message);

    // Build contact delivery statuses (mock: all contacts notified successfully)
    final contactStatuses = <SosContactStatus>[];

    if (network != null) {
      // Notify buddies first (they're closer)
      for (final buddy in network.buddies) {
        contactStatuses.add(SosContactStatus(
          name: buddy.name,
          relation: buddy.relation,
          phone: buddy.phone,
          notified: true,
        ));
        print('[SOS] Notified buddy: ${buddy.name}');
      }

      // Then notify caregivers
      for (final caregiver in network.caregivers) {
        contactStatuses.add(SosContactStatus(
          name: caregiver.name,
          relation: caregiver.relation,
          phone: caregiver.phone,
          notified: true,
        ));
        print('[SOS] Notified caregiver: ${caregiver.name}');
      }
    }

    print('[SOS] Alert created, ${contactStatuses.length} contacts notified');

    return SosDeliveryStatus(
      sent: true,
      location: location,
      contactStatuses: contactStatuses,
      alertId: alertId,
    );
  }

  /// Cancel an active SOS.
  /// Resolves the alert and notifies contacts that the user is OK.
  Future<void> cancelSos(String uid) async {
    // Authorization: only the user themselves can cancel their own SOS
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      print('[SOS] Cancel DENIED — unauthorized');
      return;
    }
    print('[SOS] Cancelled');

    // In a real app, we would find the active SOS alert and resolve it.
    // For mock, we just show a cancellation notification.
    await _notifications.showSosAlert(
      'SOS dibatalkan. Pengguna selamat.',
    );
  }
}
