import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_log.dart';
import 'service_providers.dart';

final healthLogsProvider = FutureProvider.family<List<HealthLog>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getHealthLogs(uid, days: 14);
});

final recentHealthLogsProvider = FutureProvider.family<List<HealthLog>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getHealthLogs(uid, days: 7);
});
