import '../../models/user_profile.dart';
import '../../models/health_log.dart';
import '../../models/medication.dart';
import '../../models/medication_log.dart';
import '../../models/conversation.dart';
import '../../models/alert.dart';
import '../../models/care_network.dart';
import '../../models/ai_memory.dart';
import '../../models/caregiver_view.dart';

/// Abstract interface for database operations.
/// Covers all Firestore CRUD for users, health logs, medications,
/// conversations, AI memory, care networks, and alerts.
abstract class DatabaseServiceBase {
  // ======== User Profile ========

  /// Get a user profile by UID.
  Future<UserProfile?> getUserProfile(String uid);

  // ======== Health Logs ========

  /// Get health logs for a user, defaulting to the last 14 days.
  Future<List<HealthLog>> getHealthLogs(String uid, {int days = 14});

  /// Save a new health log entry.
  Future<void> saveHealthLog(String uid, HealthLog log);

  // ======== Medications ========

  /// Get the list of medications for a user.
  Future<List<Medication>> getMedications(String uid);

  // ======== Medication Logs ========

  /// Get medication logs for a user, defaulting to the last 7 days.
  Future<List<MedicationLog>> getMedicationLogs(String uid, {int days = 7});

  /// Save a medication log entry.
  Future<void> saveMedicationLog(String uid, MedicationLog log);

  // ======== Conversations ========

  /// Get recent conversations, limited to [limit] results.
  Future<List<Conversation>> getConversations(String uid, {int limit = 10});

  /// Save a conversation transcript.
  Future<void> saveConversation(String uid, Conversation conversation);

  // ======== AI Memory ========

  /// Get the AI memory context for a user.
  Future<AiMemory?> getAiMemory(String uid);

  /// Update the AI memory context.
  Future<void> updateAiMemory(String uid, AiMemory memory);

  // ======== Care Network ========

  /// Get the care network (caregivers + buddies) for a user.
  Future<CareNetwork?> getCareNetwork(String uid);

  // ======== Caregiver View ========

  /// Get the caregiver's view of an elderly user's status.
  Future<CaregiverView?> getCaregiverView(
      String caregiverUid, String elderlyUid);

  // ======== Alerts ========

  /// Get alerts for a user, limited to [limit] results.
  Future<List<Alert>> getAlerts(String uid, {int limit = 20});

  /// Create a new alert.
  Future<void> createAlert(Alert alert);
}
