import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth/auth_service_base.dart';
import 'auth/mock_auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'database/database_service_base.dart';
import 'database/mock_database_service.dart';
import 'database/firestore_service.dart';
import 'ai/ai_service_base.dart';
import 'ai/mock_gemini_service.dart';
import 'ai/gemini_service.dart';
import 'voice/voice_service_base.dart';
import 'voice/mock_voice_service.dart';
import 'notification/notification_service_base.dart';
import 'notification/mock_notification_service.dart';
import 'notification/fcm_notification_service.dart';
import 'location/location_service_base.dart';
import 'location/mock_location_service.dart';
import 'location/geolocator_service.dart';
import 'medication/medication_service.dart';
import 'sos/sos_service.dart';
import 'health_analysis/health_analysis_service.dart';

/// Central service registry for KampungCare.
///
/// When [useMocks] is true, all services return mock/offline implementations
/// suitable for development and demo.
/// When false, services use real Firebase/Gemini implementations.
///
/// Usage:
/// ```dart
/// final auth = ServiceLocator.auth;
/// final user = await auth.signIn(phone, otp);
/// ```
class ServiceLocator {
  ServiceLocator._();

  /// True on web (uses mock data); false on Android (uses real Firebase).
  static bool get useMocks => kIsWeb;

  // ======== Singleton instances ========

  static AuthServiceBase? _auth;
  static DatabaseServiceBase? _db;
  static AiServiceBase? _ai;
  static VoiceServiceBase? _voice;
  static NotificationServiceBase? _notification;
  static LocationServiceBase? _location;
  static MedicationService? _medication;
  static SosService? _sos;
  static HealthAnalysisService? _healthAnalysis;

  // ======== Core Services ========

  /// Authentication service (phone OTP + session management).
  static AuthServiceBase get auth {
    _auth ??= useMocks ? MockAuthService() : FirebaseAuthService();
    return _auth!;
  }

  /// Database service (Firestore CRUD operations).
  static DatabaseServiceBase get database {
    _db ??= useMocks ? MockDatabaseService() : FirestoreService();
    return _db!;
  }

  /// AI/Gemini service (chat, vision, analysis).
  static AiServiceBase get ai {
    _ai ??= useMocks ? MockGeminiService() : GeminiService();
    return _ai!;
  }

  /// Voice service (speech-to-text + text-to-speech).
  /// MockVoiceService uses REAL STT/TTS packages — no real alternative needed.
  static VoiceServiceBase get voice {
    _voice ??= MockVoiceService();
    return _voice!;
  }

  /// Notification service (local + FCM push notifications).
  static NotificationServiceBase get notification {
    _notification ??= useMocks ? MockNotificationService() : FcmNotificationService();
    return _notification!;
  }

  /// Location service (GPS coordinates).
  static LocationServiceBase get location {
    _location ??= useMocks ? MockLocationService() : GeolocatorService();
    return _location!;
  }

  // ======== Composite Services ========

  /// Medication tracking service (schedule, confirm, snooze).
  static MedicationService get medication {
    _medication ??= MedicationService(
      db: database,
      notifications: notification,
    );
    return _medication!;
  }

  /// SOS emergency service (trigger, cancel, notify contacts).
  static SosService get sos {
    _sos ??= SosService(
      db: database,
      location: location,
      notifications: notification,
      auth: auth,
    );
    return _sos!;
  }

  /// Health analysis service (pattern detection, weekly reports).
  static HealthAnalysisService get healthAnalysis {
    _healthAnalysis ??= HealthAnalysisService(
      db: database,
      ai: ai,
    );
    return _healthAnalysis!;
  }

  // ======== Convenience accessors ========

  /// Get the mock auth service (for signInAs demo feature).
  /// Only available when useMocks is true.
  static MockAuthService get mockAuth {
    assert(useMocks, 'mockAuth only available when useMocks is true');
    return auth as MockAuthService;
  }

  /// Get the mock Gemini service (for resetConversation feature).
  /// Only available when useMocks is true.
  static MockGeminiService get mockAi {
    assert(useMocks, 'mockAi only available when useMocks is true');
    return ai as MockGeminiService;
  }

  // ======== Utility ========

  /// Reset all cached service instances.
  static void reset() {
    if (_auth is MockAuthService) {
      (_auth as MockAuthService).dispose();
    }
    _auth = null;
    _db = null;
    _ai = null;
    _voice = null;
    _notification = null;
    _location = null;
    _medication = null;
    _sos = null;
    _healthAnalysis = null;
    print('[ServiceLocator] All services reset');
  }
}
