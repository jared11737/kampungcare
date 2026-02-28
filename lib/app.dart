import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'services/notification/mock_notification_service.dart';
import 'widgets/demo_mode_fab.dart';

class KampungCareApp extends StatefulWidget {
  const KampungCareApp({super.key});

  @override
  State<KampungCareApp> createState() => _KampungCareAppState();
}

class _KampungCareAppState extends State<KampungCareApp> {
  static const _sosChannel = MethodChannel('com.kampungcare.app/sos');

  @override
  void initState() {
    super.initState();

    // Handle SOS widget intent
    _sosChannel.setMethodCallHandler((call) async {
      if (call.method == 'triggerSos') {
        AppRoutes.router.go(AppRoutes.sos);
      }
    });

    // Handle notification deep-linking
    MockNotificationService.onNotificationTap = _handleNotificationTap;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    if (payload.startsWith('medication:')) {
      AppRoutes.router.go(AppRoutes.medication);
    } else if (payload == 'check_in') {
      AppRoutes.router.go('${AppRoutes.voiceChat}?type=check_in');
    } else if (payload == 'sos') {
      AppRoutes.router.go(AppRoutes.sos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: KampungCareTheme.lightTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: Stack(
            children: [
              child!,
              if (kDebugMode)
                const Positioned(
                  left: 16,
                  bottom: 16,
                  child: DemoModeFab(),
                ),
            ],
          ),
        );
      },
    );
  }
}
