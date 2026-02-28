import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/elderly/home_screen.dart';
import '../screens/elderly/voice_chat_screen.dart';
import '../screens/elderly/medication_screen.dart';
import '../screens/elderly/medication_camera_screen.dart';
import '../screens/elderly/health_screen.dart';
import '../screens/elderly/family_screen.dart';
import '../screens/elderly/sos_screen.dart';
import '../screens/elderly/settings_screen.dart';
import '../screens/caregiver/dashboard_screen.dart';
import '../screens/caregiver/weekly_report_screen.dart';
import '../screens/caregiver/stories_screen.dart';
import '../screens/buddy/buddy_screen.dart';
import '../services/service_locator.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String elderlyHome = '/elderly';
  static const String voiceChat = '/elderly/chat';
  static const String medication = '/elderly/medication';
  static const String medicationCamera = '/elderly/medication/camera';
  static const String health = '/elderly/health';
  static const String family = '/elderly/family';
  static const String sos = '/elderly/sos';
  static const String settings = '/elderly/settings';
  static const String caregiverDashboard = '/caregiver';
  static const String weeklyReport = '/caregiver/report';
  static const String stories = '/caregiver/stories';
  static const String buddyHome = '/buddy';

  /// Valid conversation types for voice chat route.
  static const _validChatTypes = {'check_in', 'cerita', 'casual', 'concerning'};

  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      final user = ServiceLocator.auth.currentUser;
      final path = state.uri.path;

      // Allow unauthenticated routes
      if (path == login || path == onboarding) return null;

      // Require authentication for all other routes
      if (user == null) return login;

      // Role-based access control
      if (path.startsWith('/elderly') && user.role != UserRole.elderly) {
        return _homeForRole(user.role);
      }
      if (path.startsWith('/caregiver') && user.role != UserRole.caregiver) {
        return _homeForRole(user.role);
      }
      if (path.startsWith('/buddy') && user.role != UserRole.buddy) {
        return _homeForRole(user.role);
      }

      return null; // allow navigation
    },
    routes: [
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: elderlyHome,
        builder: (context, state) => const ElderlyHomeScreen(),
      ),
      GoRoute(
        path: voiceChat,
        builder: (context, state) {
          final raw = state.uri.queryParameters['type'] ?? 'check_in';
          final chatType = _validChatTypes.contains(raw) ? raw : 'check_in';
          return VoiceChatScreen(conversationType: chatType);
        },
      ),
      GoRoute(
        path: medication,
        builder: (context, state) => const MedicationScreen(),
      ),
      GoRoute(
        path: medicationCamera,
        builder: (context, state) {
          final medId = state.uri.queryParameters['medId'];
          // Sanitize medId: only allow alphanumeric + underscore
          final safeMedId = (medId != null && RegExp(r'^[\w]+$').hasMatch(medId))
              ? medId
              : null;
          return MedicationCameraScreen(medicationId: safeMedId);
        },
      ),
      GoRoute(
        path: health,
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: family,
        builder: (context, state) => const FamilyScreen(),
      ),
      GoRoute(
        path: sos,
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: caregiverDashboard,
        builder: (context, state) => const CaregiverDashboardScreen(),
      ),
      GoRoute(
        path: weeklyReport,
        builder: (context, state) => const WeeklyReportScreen(),
      ),
      GoRoute(
        path: stories,
        builder: (context, state) => const StoriesScreen(),
      ),
      GoRoute(
        path: buddyHome,
        builder: (context, state) => const BuddyScreen(),
      ),
    ],
  );

  /// Return the correct home route for a given role.
  static String _homeForRole(UserRole role) {
    return switch (role) {
      UserRole.elderly => elderlyHome,
      UserRole.caregiver => caregiverDashboard,
      UserRole.buddy => buddyHome,
    };
  }
}
