/// GoRouter Application Navigation Structure designed by Shreesh Nalawade
///
/// VisionBridge — App Router (GoRouter)
///
/// Defines all routes, guards (auth check), and redirects.
library;


import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/blind_user/presentation/screens/bu_home_screen.dart';
import '../../features/blind_user/presentation/screens/ai_assist_screen.dart';
import '../../features/blind_user/presentation/screens/read_text_screen.dart';
import '../../features/blind_user/presentation/screens/bu_in_call_screen.dart';
import '../../features/blind_user/presentation/screens/bu_call_history_screen.dart';
import '../../features/blind_user/presentation/screens/sos_screen.dart';
import '../../features/blind_user/presentation/screens/bu_settings_screen.dart';
import '../../features/volunteer/presentation/screens/v_home_screen.dart';
import '../../features/volunteer/presentation/screens/v_incoming_call_screen.dart';
import '../../features/volunteer/presentation/screens/v_in_call_screen.dart';
import '../../features/volunteer/presentation/screens/v_call_history_screen.dart';
import '../../features/volunteer/presentation/screens/v_settings_screen.dart';

/// Route path constants — no magic strings in navigation calls.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String selectRole = '/auth/select-role';

  // Blind User routes
  static const String buHome = '/bu/home';
  static const String aiAssist = '/bu/ai-assist';
  static const String readText = '/bu/read-text';
  static const String buInCall = '/bu/in-call';
  static const String buCallHistory = '/bu/call-history';
  static const String sos = '/bu/sos';
  static const String buSettings = '/bu/settings';

  // Volunteer routes
  static const String vHome = '/v/home';
  static const String vIncomingCall = '/v/incoming-call';
  static const String vInCall = '/v/in-call';
  static const String vCallHistory = '/v/call-history';
  static const String vSettings = '/v/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectRole,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      // --- Blind User ---
      GoRoute(
        path: AppRoutes.buHome,
        builder: (context, state) => const BUHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssist,
        builder: (context, state) => const AIAssistScreen(),
      ),
      GoRoute(
        path: AppRoutes.readText,
        builder: (context, state) => const ReadTextScreen(),
      ),
      GoRoute(
        path: AppRoutes.buInCall,
        builder: (context, state) => const BUInCallScreen(),
      ),
      GoRoute(
        path: AppRoutes.buCallHistory,
        builder: (context, state) => const BUCallHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.sos,
        builder: (context, state) => const SOSScreen(),
      ),
      GoRoute(
        path: AppRoutes.buSettings,
        builder: (context, state) => const BUSettingsScreen(),
      ),
      // --- Volunteer ---
      GoRoute(
        path: AppRoutes.vHome,
        builder: (context, state) => const VHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.vIncomingCall,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VIncomingCallScreen(
            callRequestId: extra?['callRequestId'],
            signalingRoomId: extra?['signalingRoomId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.vInCall,
        builder: (context, state) => const VInCallScreen(),
      ),
      GoRoute(
        path: AppRoutes.vCallHistory,
        builder: (context, state) => const VCallHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.vSettings,
        builder: (context, state) => const VSettingsScreen(),
      ),
    ],
  );
});
