import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/me_screen.dart';
import 'screens/bill_detail_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoading = authProvider.loading;
        final isLoggedIn = authProvider.isLoggedIn;
        final needsOnboarding = authProvider.needsOnboarding;
        final location = state.matchedLocation;

        if (isLoading) {
          return location == '/splash' ? null : '/splash';
        }

        final isLoginRoute = location == '/login';
        final isSplashRoute = location == '/splash';
        final isOnboardingRoute = location == '/onboarding';

        if (isSplashRoute) {
          if (!isLoggedIn) return '/login';
          return needsOnboarding ? '/onboarding' : '/home';
        }

        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) {
          return needsOnboarding ? '/onboarding' : '/home';
        }
        if (isLoggedIn && needsOnboarding && !isOnboardingRoute) {
          return '/onboarding';
        }
        if (isLoggedIn && !needsOnboarding && isOnboardingRoute) {
          return '/home';
        }
        return null;
      },
      refreshListenable: authProvider,
      routes: [
        // Splash / loading screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(child: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HomeScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bills',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: BillsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/groups',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: GroupsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/friends',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: FriendsScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/me',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MeScreen()),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/bills/:id',
          builder: (context, state) =>
              BillDetailScreen(billId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/groups/:id',
          builder: (context, state) =>
              GroupDetailScreen(groupId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );
  }
}

/// Shown while auth state is being restored — kept pixel-identical to the
/// native/web splash (flutter_native_splash config in pubspec.yaml: same
/// bg color, same plain centered logo, no text/spinner) so the handoff
/// from that splash to this route is invisible instead of a visible flash.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFDDEAFF),
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo.png'),
          width: 128,
          height: 128,
        ),
      ),
    );
  }
}
