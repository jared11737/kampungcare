import 'dart:math';
import '../../models/user_profile.dart';
import '../../models/health_log.dart';
import '../../models/medication.dart';
import '../../models/medication_log.dart';
import '../../models/conversation.dart';
import '../../models/alert.dart';
import '../../models/care_network.dart';
import '../../models/ai_memory.dart';
import '../../models/caregiver_view.dart';
import '../../data/mock_data.dart';
import 'database_service_base.dart';

/// Mock database service that returns data from MockData and stores
/// changes in-memory. Simulates network delays of 300-800ms.
class MockDatabaseService implements DatabaseServiceBase {
  final _random = Random();

  // In-memory storage for changes
  final Map<String, UserProfile> _users = {};
  final Map<String, List<HealthLog>> _healthLogs = {};
  final Map<String, List<MedicationLog>> _medicationLogs = {};
  final Map<String, List<Conversation>> _conversations = {};
  final Map<String, AiMemory> _aiMemories = {};
  final List<Alert> _alerts = [];

  bool _initialized = false;

  /// Initialize mock data on first access.
  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // Seed users
    _users['siti_001'] = MockData.elderlyUser;
    _users['aisyah_001'] = MockData.caregiver;
    _users['zainab_001'] = MockData.buddy;

    // Seed health logs
    _healthLogs['siti_001'] = MockData.healthLogs;

    // Seed medication logs
    _medicationLogs['siti_001'] = MockData.medicationLogs;

    // Seed conversations
    _conversations['siti_001'] = MockData.conversations;

    // Seed AI memory
    _aiMemories['siti_001'] = MockData.aiMemory;

    // Seed alerts
    _alerts.addAll(MockData.alerts);
  }

  /// Simulate a network delay between 300-800ms.
  Future<void> _simulateDelay() async {
    final delayMs = 300 + _random.nextInt(500);
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  // ======== User Profile ========

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    _ensureInitialized();
    await _simulateDelay();
    return _users[uid];
  }

  // ======== Health Logs ========

  @override
  Future<List<HealthLog>> getHealthLogs(String uid, {int days = 14}) async {
    _ensureInitialized();
    await _simulateDelay();

    final logs = _healthLogs[uid] ?? [];
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return logs
        .where((log) => log.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> saveHealthLog(String uid, HealthLog log) async {
    _ensureInitialized();
    await _simulateDelay();

    _healthLogs.putIfAbsent(uid, () => []);
    _healthLogs[uid]!.add(log);
    print('[MockDB] Saved health log ${log.id} for $uid');
  }

  // ======== Medications ========

  @override
  Future<List<Medication>> getMedications(String uid) async {
    _ensureInitialized();
    await _simulateDelay();

    // All elderly users share the same medications for demo
    if (uid == 'siti_001') {
      return MockData.medications;
    }
    return [];
  }

  // ======== Medication Logs ========

  @override
  Future<List<MedicationLog>> getMedicationLogs(String uid,
      {int days = 7}) async {
    _ensureInitialized();
    await _simulateDelay();

    final logs = _medicationLogs[uid] ?? [];
    // MedicationLog uses scheduledTime (a time string), so we filter by
    // index approximation. For simplicity, return last N days worth.
    // Each day has ~5 logs (3 morning + 2 evening).
    final maxLogs = days * 5;
    final sorted = List<MedicationLog>.from(logs);
    if (sorted.length > maxLogs) {
      return sorted.sublist(sorted.length - maxLogs);
    }
    return sorted;
  }

  @override
  Future<void> saveMedicationLog(String uid, MedicationLog log) async {
    _ensureInitialized();
    await _simulateDelay();

    _medicationLogs.putIfAbsent(uid, () => []);
    _medicationLogs[uid]!.add(log);
    print('[MockDB] Saved medication log ${log.id} for $uid');
  }

  // ======== Conversations ========

  @override
  Future<List<Conversation>> getConversations(String uid,
      {int limit = 10}) async {
    _ensureInitialized();
    await _simulateDelay();

    final convos = _conversations[uid] ?? [];
    final sorted = List<Conversation>.from(convos)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (sorted.length > limit) {
      return sorted.sublist(0, limit);
    }
    return sorted;
  }

  @override
  Future<void> saveConversation(String uid, Conversation conversation) async {
    _ensureInitialized();
    await _simulateDelay();

    _conversations.putIfAbsent(uid, () => []);
    _conversations[uid]!.add(conversation);
    print('[MockDB] Saved conversation ${conversation.id} for $uid');
  }

  // ======== AI Memory ========

  @override
  Future<AiMemory?> getAiMemory(String uid) async {
    _ensureInitialized();
    await _simulateDelay();
    return _aiMemories[uid];
  }

  @override
  Future<void> updateAiMemory(String uid, AiMemory memory) async {
    _ensureInitialized();
    await _simulateDelay();

    _aiMemories[uid] = memory;
    print('[MockDB] Updated AI memory for $uid');
  }

  // ======== Care Network ========

  @override
  Future<CareNetwork?> getCareNetwork(String uid) async {
    _ensureInitialized();
    await _simulateDelay();

    // Only Siti has a care network in mock data
    if (uid == 'siti_001') {
      return MockData.careNetwork;
    }
    return null;
  }

  // ======== Caregiver View ========

  @override
  Future<CaregiverView?> getCaregiverView(
      String caregiverUid, String elderlyUid) async {
    _ensureInitialized();
    await _simulateDelay();

    // Only Aisyah watching Siti in mock data
    if (caregiverUid == 'aisyah_001' && elderlyUid == 'siti_001') {
      return MockData.caregiverView;
    }
    return null;
  }

  // ======== Alerts ========

  @override
  Future<List<Alert>> getAlerts(String uid, {int limit = 20}) async {
    _ensureInitialized();
    await _simulateDelay();

    final userAlerts = _alerts
        .where((a) => a.elderlyUid == uid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (userAlerts.length > limit) {
      return userAlerts.sublist(0, limit);
    }
    return userAlerts;
  }

  @override
  Future<void> createAlert(Alert alert) async {
    _ensureInitialized();
    await _simulateDelay();

    _alerts.add(alert);
    print('[MockDB] Created alert ${alert.id}');
  }
}
