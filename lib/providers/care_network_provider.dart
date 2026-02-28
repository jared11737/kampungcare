import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/care_network.dart';
import 'service_providers.dart';

final careNetworkProvider = FutureProvider.family<CareNetwork?, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getCareNetwork(uid);
});
