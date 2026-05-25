import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/auth/presentation/login_screen.dart';
import 'package:frontend_flutter/features/dashboard/presentation/dashboard_screen.dart';

import 'package:frontend_flutter/features/tanks/presentation/tanks_screen.dart';
import 'package:frontend_flutter/features/water_quality/presentation/water_quality_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AquaSertaoApp(),
    ),
  );
}

class AquaSertaoApp extends ConsumerWidget {
  const AquaSertaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication state to trigger router redirects
    final authState = ref.watch(authNotifierProvider);

    final router = GoRouter(
      initialLocation: '/dashboard',
      redirect: (context, state) {
        final isGoingToLogin = state.matchedLocation == '/login';
        
        // If the user is NOT authenticated, kick them to the login screen
        if (!authState.isAuthenticated && !isGoingToLogin) {
          return '/login';
        }
        
        // If the user IS authenticated but tries to go to login, send them to dashboard
        if (authState.isAuthenticated && isGoingToLogin) {
          return '/dashboard';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/tanks',
          builder: (context, state) => const TanksScreen(),
        ),
        GoRoute(
          path: '/water-quality',
          builder: (context, state) => const WaterQualityScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'AquaSertão',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
