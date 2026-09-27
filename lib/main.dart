/// Project Author: Shreesh Nalawade (shreeshnalawade9@gmail.com)
/// Original Creation: 09 September 2005 (Author Reference: SN09092005)
/// Core Architecture & Main Entrypoint designed by Shreesh Nalawade
/// Copyright (c) Shreesh Nalawade. All rights reserved.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/locale/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

/// Top-level background message handler — MUST be top-level for Flutter isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await firebaseMessagingBackgroundHandler(message);
}

/// Global navigator key for CallKit accept navigation from background/killed state.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background handler (must be before any FCM calls)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM for push notifications
  await FCMService.instance.initialize();

  // Lock to portrait (accessibility: consistent layout for screen readers)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: VisionBridgeApp(),
    ),
  );
}

class VisionBridgeApp extends ConsumerStatefulWidget {
  const VisionBridgeApp({super.key});

  @override
  ConsumerState<VisionBridgeApp> createState() => _VisionBridgeAppState();
}

class _VisionBridgeAppState extends ConsumerState<VisionBridgeApp> {
  @override
  void initState() {
    super.initState();

    // Wire up CallKit accept callback to navigate to incoming call screen
    FCMService.instance.onCallAccepted = (callRequestId, signalingRoomId) {
      final router = ref.read(routerProvider);
      router.push('/v/incoming-call', extra: {
        'callRequestId': callRequestId,
        'signalingRoomId': signalingRoomId,
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // --- Localization ---
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      // --- Theme ---
      theme: VBTheme.light,
      darkTheme: VBTheme.dark,
      themeMode: themeMode,
      // --- Router ---
      routerConfig: router,
      // --- Accessibility: respect system text scaling ---
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Never clamp textScaleFactor — respect user's accessibility setting
            // This is intentionally NOT using textScaler override
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

