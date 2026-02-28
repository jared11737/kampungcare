import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
import 'service_providers.dart';

final alertsProvider = FutureProvider.family<List<Alert>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getAlerts(uid, limit: 20);
});
