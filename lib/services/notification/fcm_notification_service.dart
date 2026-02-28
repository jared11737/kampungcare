import 'package:firebase_messaging/firebase_messaging.dart';
import 'mock_notification_service.dart';

class FcmNotificationService extends MockNotificationService {
  @override
  Future<void> initialize() async {
    await super.initialize(); // sets up local notification channels

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    print('[FCM] Token: $token');
    // TODO after sign-in: save token to users/{uid}/fcmToken in Firestore

    FirebaseMessaging.onMessage.listen((msg) {
      final title = msg.notification?.title ?? '';
      final body = msg.notification?.body ?? '';
      showSosAlert('$title: $body');
      MockNotificationService.onNotificationTap?.call(msg.data['payload']);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      MockNotificationService.onNotificationTap?.call(msg.data['payload']);
    });
  }
}
