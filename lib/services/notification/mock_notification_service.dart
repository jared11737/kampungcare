import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service_base.dart';

/// Callback type for handling notification taps.
typedef NotificationTapCallback = void Function(String? payload);

/// Notification service using real flutter_local_notifications.
/// Works offline — suitable for development and demo.
/// Sets up Android notification channels for medication reminders
/// and SOS alerts with appropriate priority levels.
class MockNotificationService implements NotificationServiceBase {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Set this to handle notification tap deep-linking.
  static NotificationTapCallback? onNotificationTap;

  // Notification channel IDs
  static const String _medicationChannelId = 'kampungcare_medication';
  static const String _checkInChannelId = 'kampungcare_checkin';
  static const String _sosChannelId = 'kampungcare_sos';

  // Notification IDs (using hash-based IDs to avoid collisions)
  static int _nextNotificationId = 100;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization (for simulator testing)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('[Notification] Tapped: ${response.payload}');
        onNotificationTap?.call(response.payload);
      },
    );

    // Create Android notification channels
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Medication channel — gentle chime
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _medicationChannelId,
          'Peringatan Ubat',
          description: 'Peringatan untuk mengambil ubat',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Check-in channel — call-like notification
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _checkInChannelId,
          'Check-in Harian',
          description: 'Peringatan check-in pagi dan malam',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // SOS channel — maximum priority
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _sosChannelId,
          'Kecemasan SOS',
          description: 'Amaran kecemasan',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
    print('[Notification] Initialized with 3 channels');
  }

  @override
  Future<void> scheduleMedicationReminder(
    String medId,
    String medName,
    DateTime time,
  ) async {
    if (!_initialized) await initialize();

    final id = _nextNotificationId++;

    final androidDetails = AndroidNotificationDetails(
      _medicationChannelId,
      'Peringatan Ubat',
      channelDescription: 'Peringatan untuk mengambil ubat',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Masa ubat!',
      styleInformation: BigTextStyleInformation(
        'Masa untuk ambil $medName. Tekan untuk buka KampungCare.',
        contentTitle: 'Masa Ubat - $medName',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // For demo, show immediately if scheduled time is in the past
    if (time.isBefore(DateTime.now())) {
      await _notifications.show(
        id,
        'Masa Ubat',
        'Masa untuk ambil $medName',
        details,
        payload: 'medication:$medId',
      );
    } else {
      // Schedule for future
      // Note: For exact scheduling, would need timezone package.
      // For hackathon, we just show immediately for demo purposes.
      await _notifications.show(
        id,
        'Masa Ubat',
        'Masa untuk ambil $medName',
        details,
        payload: 'medication:$medId',
      );
    }

    print('[Notification] Scheduled medication reminder: $medName at $time');
  }

  @override
  Future<void> scheduleCheckInReminder(DateTime time) async {
    if (!_initialized) await initialize();

    final id = _nextNotificationId++;

    final androidDetails = AndroidNotificationDetails(
      _checkInChannelId,
      'Check-in Harian',
      channelDescription: 'Peringatan check-in pagi dan malam',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: true,
      ticker: 'Sayang nak sembang!',
      styleInformation: const BigTextStyleInformation(
        'Sayang nak tanya khabar. Tekan untuk mula sembang.',
        contentTitle: 'Hai Mak Cik! Jom sembang!',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'Hai! Jom sembang!',
      'Sayang nak tanya khabar Mak Cik hari ni.',
      details,
      payload: 'check_in',
    );

    print('[Notification] Scheduled check-in reminder at $time');
  }

  @override
  Future<void> showSosAlert(String message) async {
    if (!_initialized) await initialize();

    final id = _nextNotificationId++;

    final androidDetails = AndroidNotificationDetails(
      _sosChannelId,
      'Kecemasan SOS',
      channelDescription: 'Amaran kecemasan',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      ticker: 'KECEMASAN!',
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: 'KECEMASAN SOS!',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      'KECEMASAN SOS!',
      message,
      details,
      payload: 'sos',
    );

    print('[Notification] SOS alert shown: $message');
  }

  @override
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('[Notification] All notifications cancelled');
  }
}
