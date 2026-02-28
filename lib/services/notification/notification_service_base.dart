/// Abstract interface for notification service.
/// Handles scheduling and displaying local notifications for
/// medication reminders, check-in reminders, and SOS alerts.
abstract class NotificationServiceBase {
  /// Initialize the notification system (channels, permissions, etc).
  Future<void> initialize();

  /// Schedule a medication reminder notification.
  /// [medId] is the medication identifier for tracking.
  /// [medName] is the display name (e.g., "Metformin 500mg").
  /// [time] is when the reminder should fire.
  Future<void> scheduleMedicationReminder(
    String medId,
    String medName,
    DateTime time,
  );

  /// Schedule a daily check-in reminder notification.
  /// [time] is when the check-in reminder should fire.
  Future<void> scheduleCheckInReminder(DateTime time);

  /// Show an immediate SOS alert notification with high priority.
  /// [message] is the alert text to display.
  Future<void> showSosAlert(String message);

  /// Cancel all scheduled and pending notifications.
  Future<void> cancelAll();
}
