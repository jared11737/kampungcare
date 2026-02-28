import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth/auth_service_base.dart';
import '../services/database/database_service_base.dart';
import '../services/ai/ai_service_base.dart';
import '../services/voice/voice_service_base.dart';
import '../services/service_locator.dart';

/// DI bridge: exposes ServiceLocator singletons as Riverpod providers.
/// All data providers should depend on these instead of calling ServiceLocator directly.
final authServiceProvider = Provider<AuthServiceBase>((_) => ServiceLocator.auth);
final databaseServiceProvider = Provider<DatabaseServiceBase>((_) => ServiceLocator.database);
final aiServiceProvider = Provider<AiServiceBase>((_) => ServiceLocator.ai);
final voiceServiceProvider = Provider<VoiceServiceBase>((_) => ServiceLocator.voice);
