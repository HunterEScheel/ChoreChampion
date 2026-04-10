import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/join_screen.dart';
import '../features/auth/screens/create_household_screen.dart';
import '../features/member_select/screens/member_select_screen.dart';
import '../features/chores/screens/chore_list_screen.dart';
import '../features/rewards/screens/rewards_screen.dart';
import '../features/admin/screens/admin_panel_screen.dart';
import '../shared/widgets/responsive_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuth = authState.value?.isAuthenticated ?? false;
      final hasMember = authState.value?.hasActiveMember ?? false;

      // Splash handles initial load
      if (location == '/') return null;

      // Not authenticated — force to join
      if (!isAuth && location != '/join' && location != '/create-household') {
        return '/join';
      }

      // Authenticated but no member selected
      if (isAuth && !hasMember && location != '/select-member') {
        return '/select-member';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (_, __) => const JoinScreen(),
      ),
      GoRoute(
        path: '/create-household',
        builder: (_, __) => const CreateHouseholdScreen(),
      ),
      GoRoute(
        path: '/select-member',
        builder: (_, __) => const MemberSelectScreen(),
      ),
      // Main app shell with bottom nav / side rail
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, state, child) => ResponsiveScaffold(child: child),
        routes: [
          GoRoute(
            path: '/chores',
            builder: (_, __) => const ChoreListScreen(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (_, __) => const RewardsScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminPanelScreen(),
          ),
        ],
      ),
    ],
  );
});
