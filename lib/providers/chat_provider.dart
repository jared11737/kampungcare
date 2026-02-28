import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import 'service_providers.dart';

final conversationsProvider = FutureProvider.family<List<Conversation>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).getConversations(uid, limit: 10);
});
