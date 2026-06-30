import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'theme/app_theme.dart';

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
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/bills',
              builder: (context, state) => const BillsScreen(),
            ),
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsScreen(),
            ),
            GoRoute(
              path: '/friends',
              builder: (context, state) => const FriendsScreen(),
            ),
            GoRoute(
              path: '/me',
              builder: (context, state) => const MeScreen(),
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

/// Simple branded splash screen shown while auth state is being restored.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 88, height: 88),
            const SizedBox(height: 20),
            Text(
              'Kidtang',
              style: GoogleFonts.notoSansThai(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
