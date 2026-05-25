import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AquaSertão', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.email ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    authState.accountType ?? 'UNKNOWN ROLE',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Modules Grid
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                if (authState.accountType == 'SAAS_ADMIN') ...[
                  _buildModuleCard(
                    context: context,
                    title: 'SaaS Dashboard',
                    icon: Icons.analytics,
                    color: Colors.deepPurple,
                    route: '/saas-dashboard',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Tenants',
                    icon: Icons.business,
                    color: Colors.indigo,
                    route: '/tenants',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Suppliers',
                    icon: Icons.local_shipping,
                    color: Colors.brown,
                    route: '/suppliers',
                  ),
                ],

                if (authState.accountType == 'FARM_OWNER') ...[
                  _buildModuleCard(
                    context: context,
                    title: 'Production Dashboard',
                    icon: Icons.dashboard,
                    color: Colors.deepOrange,
                    route: '/production-dashboard',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Finances',
                    icon: Icons.attach_money,
                    color: Colors.green.shade700,
                    route: '/finances',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Maintenance',
                    icon: Icons.build,
                    color: Colors.grey.shade700,
                    route: '/maintenance',
                  ),
                ],

                if (authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT') ...[
                  _buildModuleCard(
                    context: context,
                    title: 'Tanks',
                    icon: Icons.water,
                    color: Colors.cyan,
                    route: '/tanks',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Water Quality',
                    icon: Icons.science,
                    color: Colors.teal,
                    route: '/water-quality',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Inventory',
                    icon: Icons.inventory,
                    color: Colors.orange,
                    route: '/inventory',
                  ),
                  _buildModuleCard(
                    context: context,
                    title: 'Harvests',
                    icon: Icons.agriculture,
                    color: Colors.green,
                    route: '/harvests',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        context.push(route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
