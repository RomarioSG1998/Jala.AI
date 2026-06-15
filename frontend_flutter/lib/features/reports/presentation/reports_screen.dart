import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Relatórios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          Text(
            'Visão Geral e Métricas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            icon: Icons.trending_up,
            color: Colors.blue,
            title: 'Crescimento dos peixes',
            subtitle: 'Acompanhe o desenvolvimento e ganho de peso.',
          ),
          _buildReportCard(
            context,
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            title: 'Mortalidade',
            subtitle: 'Estatísticas de perdas e causas.',
          ),
          _buildReportCard(
            context,
            icon: Icons.restaurant,
            color: Colors.orange,
            title: 'Consumo de ração',
            subtitle: 'Análise de custos e quantidade fornecida.',
          ),
          _buildReportCard(
            context,
            icon: Icons.agriculture,
            color: Colors.green,
            title: 'Previsão de despesca',
            subtitle: 'Estimativa de datas para a colheita.',
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          radius: 24,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
        ),
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.black26),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Relatório de $title em breve!')),
          );
        },
      ),
    );
  }
}
