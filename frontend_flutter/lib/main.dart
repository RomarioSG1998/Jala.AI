import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:frontend_flutter/features/finances/presentation/finances_screen.dart';
import 'package:frontend_flutter/features/suppliers/presentation/suppliers_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/tenants_screen.dart';
import 'package:frontend_flutter/features/feeding_records/presentation/feeding_records_screen.dart';
import 'package:frontend_flutter/features/employees/presentation/employees_screen.dart';
import 'package:frontend_flutter/features/profile/presentation/profile_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AquaSertaoApp(),
    ),
  );
}

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
    initialLocation: '/dashboard',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isGoingToLogin = state.matchedLocation == '/login';
      if (!authState.isAuthenticated && !isGoingToLogin) return '/login';
      if (authState.isAuthenticated && isGoingToLogin) return '/dashboard';

      if (authState.isAuthenticated) {
        final role = authState.accountType;
        final location = state.matchedLocation;

        // SaaS Admin exclusive routes
        final isSaasRoute = location == '/tenants' || location == '/suppliers' || location == '/saas-dashboard';
        if (isSaasRoute && role != 'SAAS_ADMIN') {
          return '/dashboard';
        }

        // Farm Owner / Client exclusive routes
        final isOwnerRoute = location == '/employees' || location == '/finances' || location == '/maintenance';
        if (isOwnerRoute && role != 'FARM_OWNER' && role != 'CLIENT') {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
                builder: (context, state) => const TanksScreen(),
              ),
            ],
          ),
          // Aba 2 – Qualidade da Água (Relatórios)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/water-quality',
                builder: (context, state) => const WaterQualityScreen(),
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
            ],
          ),
        ],
      ),
    ],
  );
});

class AquaSertaoApp extends ConsumerWidget {
  const AquaSertaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AquaSertão',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003366)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      routerConfig: router,
    );
  }
}

// ─── Tela "Mais opções" (aba 3 da shell) ─────────────────────────────────────

class MoreMenuBody extends ConsumerWidget {
  const MoreMenuBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('MAIS MÓDULOS', style: TextStyle(color: Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
        if (role == 'FARM_OWNER' || role == 'CLIENT' || role == 'FIELD_OPERATOR') ...[
          _menuTile(context, Icons.restaurant, 'Alimentação', 'Registro de tratos diários', Colors.purple, '/feeding-records'),
          _menuTile(context, Icons.inventory, 'Estoque', 'Controle de ração e insumos', Colors.orange, '/inventory'),
          _menuTile(context, Icons.agriculture, 'Colheitas', 'Registre e acompanhe despescas', Colors.green, '/harvests'),
        ],
        if (role == 'FARM_OWNER' || role == 'CLIENT') ...[
          _menuTile(context, Icons.people, 'Funcionários', 'Gerenciar equipe', Colors.indigo, '/employees'),
          _menuTile(context, Icons.build, 'Manutenção', 'Tarefas e agendamentos', Colors.grey, '/maintenance'),
          _menuTile(context, Icons.attach_money, 'Finanças', 'Controle financeiro', Colors.green.shade700, '/finances'),
        ],
        if (role == 'SAAS_ADMIN') ...[
          _menuTile(context, Icons.business, 'Tenants', 'Gerenciar clientes', Colors.indigo, '/tenants'),
          _menuTile(context, Icons.local_shipping, 'Fornecedores', 'Parceiros B2B', Colors.brown, '/suppliers'),
        ],
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('CONTA', style: TextStyle(color: Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
        _menuTile(context, Icons.logout, 'Sair', 'Encerrar sessão', Colors.red, null,
          onTap: () => ref.read(authNotifierProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String subtitle, Color color, String? route, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: route != null ? const Icon(Icons.chevron_right, color: Colors.black26) : null,
        onTap: onTap ?? (route != null ? () => context.go(route) : null),
      ),
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
        child: Text('$title em breve!', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
