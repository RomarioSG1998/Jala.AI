import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/core/theme/theme_provider.dart';

class MoreMenuBody extends ConsumerWidget {
  const MoreMenuBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('MAIS MÓDULOS', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
        if (role == 'FARM_OWNER' || role == 'CLIENT' || role == 'FIELD_OPERATOR') ...[
          _menuTile(context, Icons.restaurant, 'Alimentação', 'Registro de tratos diários', Colors.purple, '/feeding-records'),
          _menuTile(context, Icons.inventory, 'Estoque', 'Controle de ração e insumos', Colors.orange, '/inventory'),
          _menuTile(context, Icons.agriculture, 'Colheitas', 'Registre e acompanhe despescas', Colors.green, '/harvests'),
          _menuTile(context, Icons.warning_amber_rounded, 'Mortalidade', 'Controle e taxa de mortalidade', Colors.red, '/mortality'),
          _menuTile(context, Icons.monitor_weight_outlined, 'Biometria', 'Acompanhe o crescimento e conversão alimentar', Colors.teal.shade700, '/biometrics'),
          _menuTile(context, Icons.cloud_rounded, 'Previsão do Tempo', 'Próximos 5 dias para sua região', Colors.lightBlue, '/weather'),
        ],
        if (role == 'FARM_OWNER' || role == 'CLIENT') ...[
          _menuTile(context, Icons.book, 'Biblioteca', 'Guias de manejo e doenças', Colors.teal, '/library'),
          _menuTile(context, Icons.store, 'Mercado Local', 'Compre e venda insumos', Colors.orange, '/marketplace'),
          _menuTile(context, Icons.calculate_outlined, 'Calculadora', 'Cálculos de ração e biometria', Colors.purple, '/calculator'),
          _menuTile(context, Icons.insert_chart, 'Relatórios', 'Métricas e previsões', Colors.blue, '/reports'),
          _menuTile(context, Icons.people, 'Funcionários', 'Gerenciar equipe', Colors.indigo, '/employees'),
          _menuTile(context, Icons.build, 'Manutenção', 'Tarefas e agendamentos', Colors.grey, '/maintenance'),
          _menuTile(context, Icons.attach_money, 'Finanças', 'Controle financeiro', Colors.green.shade700, '/finances'),
          _menuTile(context, Icons.assignment_turned_in, 'Aprovações', 'Central de solicitações', Colors.deepOrange, '/approvals'),
        ],
        if (role == 'SAAS_ADMIN') ...[
          _menuTile(context, Icons.business, 'Tenants', 'Gerenciar clientes', Colors.indigo, '/tenants'),
          _menuTile(context, Icons.local_shipping, 'Fornecedores', 'Parceiros B2B', Colors.brown, '/suppliers'),
        ],
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('CONFIGURAÇÕES', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
        _menuTile(
          context,
          themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
          'Tema Escuro',
          themeMode == ThemeMode.dark ? 'Ativado' : 'Desativado',
          Colors.blue,
          null,
          trailingWidget: Switch(
            value: themeMode == ThemeMode.dark,
            activeColor: const Color(0xFF13A538),
            onChanged: (val) {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('CONTA', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        ),
        _menuTile(context, Icons.logout, 'Sair', 'Encerrar sessão', Colors.red, null,
          onTap: () => ref.read(authNotifierProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String subtitle, Color color, String? route, {VoidCallback? onTap, Widget? trailingWidget}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade500, fontSize: 12)),
        trailing: trailingWidget ?? (route != null ? Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.black26) : null),
        onTap: onTap ?? (route != null ? () => context.go(route) : null),
      ),
    );
  }
}
