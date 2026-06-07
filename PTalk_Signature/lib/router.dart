import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mode_select_screen.dart';
import 'screens/main_voice_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/medicine_scanner_screen.dart';
import 'spike/spike_screen.dart';
import 'account/account_screen.dart';
import 'account/parent_screen.dart';
import 'account/children_screen.dart';
import 'account/child_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/mode-select', builder: (_, _) => const ModeSelectScreen()),
    GoRoute(path: '/home', builder: (_, _) => const MainVoiceScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
        path: '/subscription', builder: (_, _) => const SubscriptionScreen()),
    GoRoute(path: '/scan', builder: (_, _) => const MedicineScannerScreen()),
    GoRoute(path: '/spike', builder: (_, _) => const SpikeScreen()),
    GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
    GoRoute(path: '/account/parent', builder: (_, _) => const ParentScreen()),
    GoRoute(path: '/account/children', builder: (_, _) => const ChildrenScreen()),
    GoRoute(
        path: '/account/children/:id',
        builder: (_, s) =>
            ChildDetailScreen(childId: s.pathParameters['id']!)),
  ],
);
