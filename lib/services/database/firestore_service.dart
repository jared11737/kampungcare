import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service_base.dart';
import '../../models/user_profile.dart';
import '../../models/health_log.dart';
import '../../models/medication.dart';
import '../../models/medication_log.dart';
import '../../models/conversation.dart';
import '../../models/alert.dart';
import '../../models/care_network.dart';
import '../../models/ai_memory.dart';
import '../../models/caregiver_view.dart';

class FirestoreService implements DatabaseServiceBase {
  final _db = FirebaseFirestore.instance;

  CollectionReference _u() => _db.collection('users');
  CollectionReference _sub(String uid, String col) =>
      _u().doc(uid).collection(col);

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _u().doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data() as Map<String, dynamic>, uid: uid);
  }

  @override
  Future<List<HealthLog>> getHealthLogs(String uid, {int days = 14}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _sub(uid, 'healthLogs')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => HealthLog.fromJson(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
  }

  @override
  Future<void> saveHealthLog(String uid, HealthLog log) =>
      _sub(uid, 'healthLogs').doc(log.id).set(log.toJson());

  @override
  Future<List<Medication>> getMedications(String uid) async {
    final doc = await _u().doc(uid).get();
    if (!doc.exists) return [];
    final meds =
        (doc.data() as Map<String, dynamic>)['medications'] as List? ?? [];
    return meds
        .map((m) => Medication.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MedicationLog>> getMedicationLogs(String uid,
      {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _sub(uid, 'medicationLogs')
        .where('scheduledTime', isGreaterThan: since.toIso8601String())
        .orderBy('scheduledTime', descending: true)
        .get();
    return snap.docs
        .map((d) =>
            MedicationLog.fromJson(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
  }

  @override
  Future<void> saveMedicationLog(String uid, MedicationLog log) =>
      _sub(uid, 'medicationLogs').doc(log.id).set(log.toJson());

  @override
  Future<List<Conversation>> getConversations(String uid,
      {int limit = 10}) async {
    final snap = await _sub(uid, 'conversations')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) =>
            Conversation.fromJson(d.data() as Map<String, dynamic>, id: d.id))
        .toList();
  }

  @override
  Future<void> saveConversation(String uid, Conversation c) =>
      _sub(uid, 'conversations').doc(c.id).set(c.toJson());

  @override
  Future<AiMemory?> getAiMemory(String uid) async {
    final doc = await _sub(uid, 'aiMemory').doc('context').get();
    if (!doc.exists) return null;
    return AiMemory.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> updateAiMemory(String uid, AiMemory m) =>
      _sub(uid, 'aiMemory')
          .doc('context')
          .set(m.toJson(), SetOptions(merge: true));

  @override
  Future<CareNetwork?> getCareNetwork(String uid) async {
    final doc = await _u().doc(uid).get();
    if (!doc.exists) return null;
    final cn = (doc.data() as Map<String, dynamic>)['careNetwork'];
    if (cn == null) return null;
    return CareNetwork.fromJson(cn as Map<String, dynamic>);
  }

  @override
  Future<CaregiverView?> getCaregiverView(String cgUid, String elUid) async {
    final doc = await _db
        .collection('caregiverViews')
        .doc(cgUid)
        .collection('watched')
        .doc(elUid)
        .get();
    if (!doc.exists) return null;
    return CaregiverView.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<List<Alert>> getAlerts(String uid, {int limit = 20}) async {
    final snap = await _db
        .collection('alerts')
        .where('elderlyUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => Alert.fromJson(d.data(), id: d.id))
        .toList();
  }

  @override
  Future<void> createAlert(Alert alert) =>
      _db.collection('alerts').doc(alert.id).set(alert.toJson());
}
