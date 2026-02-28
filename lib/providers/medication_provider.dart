import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';
import 'service_providers.dart';

final medicationsProvider = FutureProvider.family<List<Medication>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getMedications(uid);
});

final medicationLogsProvider = FutureProvider.family<List<MedicationLog>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getMedicationLogs(uid, days: 7);
});
