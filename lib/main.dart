import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route all Flutter framework errors to Crashlytics in release mode
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Initialize notification channels before app launches
  await ServiceLocator.notification.initialize();

  runApp(
    const ProviderScope(
      child: KampungCareApp(),
    ),
  );
}
