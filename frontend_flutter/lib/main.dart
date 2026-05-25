import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/auth/presentation/login_screen.dart';
import 'package:frontend_flutter/features/dashboard/presentation/dashboard_screen.dart';

import 'package:frontend_flutter/features/tanks/presentation/tanks_screen.dart';
import 'package:frontend_flutter/features/water_quality/presentation/water_quality_screen.dart';
import 'package:frontend_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:frontend_flutter/features/harvests/presentation/harvests_screen.dart';
import 'package:frontend_flutter/features/maintenance/presentation/maintenance_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/saas_dashboard_screen.dart';

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
        // Dummy Routes for RBAC Modules
        GoRoute(path: '/saas-dashboard', builder: (context, state) => const SaasDashboardScreen()),
        GoRoute(path: '/tenants', builder: (context, state) => const DummyScreen(title: 'Manage Tenants')),
        GoRoute(path: '/suppliers', builder: (context, state) => const DummyScreen(title: 'B2B Suppliers')),
        GoRoute(path: '/production-dashboard', builder: (context, state) => const DummyScreen(title: 'Production Dashboard')),
        GoRoute(path: '/finances', builder: (context, state) => const DummyScreen(title: 'Finances')),
        GoRoute(path: '/maintenance', builder: (context, state) => const MaintenanceScreen()),
        GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
        GoRoute(path: '/harvests', builder: (context, state) => const HarvestsScreen()),
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

class DummyScreen extends StatelessWidget {
  final String title;
  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title is coming soon!', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
