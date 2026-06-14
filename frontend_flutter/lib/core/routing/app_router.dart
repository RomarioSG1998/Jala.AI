import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/auth/presentation/login_screen.dart';
import 'package:frontend_flutter/features/auth/presentation/supplier_dev_screen.dart';
import 'package:frontend_flutter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:frontend_flutter/features/tanks/presentation/tanks_screen.dart';
import 'package:frontend_flutter/features/water_quality/presentation/water_quality_screen.dart';
import 'package:frontend_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:frontend_flutter/features/harvests/presentation/harvests_screen.dart';
import 'package:frontend_flutter/features/maintenance/presentation/maintenance_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/saas_dashboard_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/plans_screen.dart';
import 'package:frontend_flutter/features/finances/presentation/finances_screen.dart';
import 'package:frontend_flutter/features/suppliers/presentation/suppliers_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/tenants_screen.dart';
import 'package:frontend_flutter/features/feeding_records/presentation/feeding_records_screen.dart';
import 'package:frontend_flutter/features/employees/presentation/employees_screen.dart';
import 'package:frontend_flutter/features/profile/presentation/profile_screen.dart';
import 'package:frontend_flutter/features/approvals/presentation/approvals_screen.dart';
import 'package:frontend_flutter/core/navigation/app_shell.dart';
import 'package:frontend_flutter/core/navigation/more_menu_body.dart';

// ─── RouterNotifier: Listenable wrapper for Riverpod Auth State ──────────────
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// ─── GoRouter Provider ───────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isGoingToLogin = state.matchedLocation == '/login';
      if (!authState.isAuthenticated && !isGoingToLogin) return '/login';

      if (authState.isAuthenticated) {
        final role = authState.accountType;

        // Supplier-specific redirection
        if (role == 'SUPPLIER') {
          if (state.matchedLocation != '/supplier-dev') {
            return '/supplier-dev';
          }
          return null;
        }

        if (isGoingToLogin) return '/dashboard';

        final location = state.matchedLocation;

        // SaaS Admin exclusive routes
        final isSaasRoute = location == '/tenants' || location == '/suppliers' || location == '/saas-dashboard' || location == '/plans';
        if (isSaasRoute && role != 'SAAS_ADMIN') return '/dashboard';

        // Farm Owner / Client exclusive routes
        final isOwnerRoute = location == '/employees' || location == '/finances' || location == '/maintenance' || location == '/approvals';
        if (isOwnerRoute && role != 'FARM_OWNER' && role != 'CLIENT') return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/supplier-dev',
        builder: (context, state) => const SupplierDevScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // ── Shell permanente com Bottom Navigation ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            currentLocation: state.matchedLocation,
          );
        },
        branches: [
          // Aba 0 – Início (Dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const FarmDashboardBody(),
              ),
            ],
          ),
          // Aba 1 – Tanques
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tanks',
                builder: (context, state) {
                  final authState = ref.read(authNotifierProvider);
                  if (authState.accountType == 'SAAS_ADMIN') {
                    return const TenantsScreen();
                  }
                  return const TanksScreen();
                },
              ),
            ],
          ),
          // Aba 2 – Qualidade da Água (Relatórios)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/water-quality',
                builder: (context, state) {
                  final authState = ref.read(authNotifierProvider);
                  if (authState.accountType == 'SAAS_ADMIN') {
                    return const SuppliersScreen();
                  }
                  return const WaterQualityScreen();
                },
              ),
            ],
          ),
          // Aba 3 – Menu (mais opções via drawer)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreMenuBody(),
              ),
              GoRoute(
                path: '/saas-dashboard',
                builder: (context, state) => const SaasDashboardScreen(),
              ),
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
              GoRoute(
                path: '/harvests',
                builder: (context, state) => const HarvestsScreen(),
              ),
              GoRoute(
                path: '/maintenance',
                builder: (context, state) => const MaintenanceScreen(),
              ),
              GoRoute(
                path: '/tenants',
                builder: (context, state) => const TenantsScreen(),
              ),
              GoRoute(
                path: '/suppliers',
                builder: (context, state) => const SuppliersScreen(),
              ),
              GoRoute(
                path: '/finances',
                builder: (context, state) => const FinancesScreen(),
              ),
              GoRoute(
                path: '/feeding-records',
                builder: (context, state) => const FeedingRecordsScreen(),
              ),
              GoRoute(
                path: '/employees',
                builder: (context, state) => const EmployeesScreen(),
              ),
              GoRoute(
                path: '/approvals',
                builder: (context, state) => const ApprovalsScreen(),
              ),
              GoRoute(
                path: '/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
