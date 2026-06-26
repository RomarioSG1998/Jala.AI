import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/report_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final _reportProvider = FutureProvider.family<ReportSummary, String>((ref, farmId) async {
  return ReportService().fetchSummary(farmId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _farmId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadFarmId();
  }

  Future<void> _loadFarmId() async {
    const storage = FlutterSecureStorage();
    final id = await storage.read(key: 'farm_id');
    setState(() {
      _farmId = id;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading || _farmId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reportAsync = ref.watch(_reportProvider(_farmId!));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Relatórios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFF13A538),
          tabs: const [
            Tab(text: 'Crescimento', icon: Icon(Icons.trending_up, size: 18)),
            Tab(text: 'Mortalidade', icon: Icon(Icons.warning_amber, size: 18)),
            Tab(text: 'Ração', icon: Icon(Icons.restaurant, size: 18)),
            Tab(text: 'Despesca', icon: Icon(Icons.agriculture, size: 18)),
          ],
        ),
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Erro ao carregar relatórios\n$e',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(_reportProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (report) => TabBarView(
          controller: _tab,
          children: [
            _GrowthTab(report: report, isDark: isDark),
            _MortalityTab(report: report, isDark: isDark),
            _FeedingTab(report: report, isDark: isDark),
            _HarvestTab(report: report, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Crescimento
// ─────────────────────────────────────────────────────────────────────────────
class _GrowthTab extends StatelessWidget {
  final ReportSummary report;
  final bool isDark;
  const _GrowthTab({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = report.growthHistory;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('📈 Crescimento dos Peixes', 'Evolução do peso médio por biometria'),
        const SizedBox(height: 16),
        if (data.isEmpty)
          _EmptyState('Nenhuma biometria registrada ainda.')
        else
          _ChartCard(
            isDark: isDark,
            chart: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}g',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length) return const Text('');
                        final parts = data[idx].date.split('/');
                        return Text('${parts[0]}/${parts[1]}',
                            style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.avgWeightG))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Stats
        if (data.isNotEmpty) ...[
          _StatRow('Última biometria', '${data.last.avgWeightG.toStringAsFixed(0)}g'),
          _StatRow('Tanque', data.last.tankName),
          _StatRow('Total de biometrias', '${data.length}'),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Mortalidade
// ─────────────────────────────────────────────────────────────────────────────
class _MortalityTab extends StatelessWidget {
  final ReportSummary report;
  final bool isDark;
  const _MortalityTab({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = report.mortalityHistory;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('☠️ Mortalidade', 'Perdas registradas ao longo do tempo'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _KpiCard('Total de mortes', '${report.totalMortality}', Colors.red)),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard('Taxa de mortalidade', '${report.mortalityRate}%', Colors.orange)),
        ]),
        const SizedBox(height: 16),
        if (data.isEmpty)
          _EmptyState('Nenhuma mortalidade registrada. 🎉')
        else
          _ChartCard(
            isDark: isDark,
            chart: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: Colors.red.shade400,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...data.map((m) => _ListTileCard(
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          title: '${m.count} peixes — ${m.date}',
          subtitle: m.cause ?? 'Causa não informada',
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Ração
// ─────────────────────────────────────────────────────────────────────────────
class _FeedingTab extends StatelessWidget {
  final ReportSummary report;
  final bool isDark;
  const _FeedingTab({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = report.feedingHistory;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('🌾 Consumo de Ração', 'Kg fornecidos e custo acumulado'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _KpiCard('Total fornecido', '${report.totalFeedKg.toStringAsFixed(1)} kg', Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _KpiCard('Custo total', 'R\$ ${report.totalFeedCost.toStringAsFixed(2)}', Colors.deepOrange)),
        ]),
        const SizedBox(height: 16),
        if (data.isEmpty)
          _EmptyState('Nenhum registro de alimentação ainda.')
        else
          _ChartCard(
            isDark: isDark,
            chart: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}kg',
                          style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54)),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.quantityKg))
                        .toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.12)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Despesca
// ─────────────────────────────────────────────────────────────────────────────
class _HarvestTab extends StatelessWidget {
  final ReportSummary report;
  final bool isDark;
  const _HarvestTab({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final forecasts = report.harvestForecasts;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('🎣 Previsão de Despesca', 'Estimativas por tanque'),
        const SizedBox(height: 16),
        if (forecasts.isEmpty)
          _EmptyState('Nenhuma despesca prevista. Defina a data nos tanques.')
        else
          ...forecasts.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: isDark ? Border.all(color: const Color(0xFF263350)) : null,
              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.water, color: Color(0xFF13A538), size: 20),
                    const SizedBox(width: 8),
                    Text(f.tankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _MiniStat('Data prevista', f.expectedDate)),
                    Expanded(child: _MiniStat('Peixes vivos', '${f.estimatedFishCount}')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _MiniStat('Peso estimado', '${f.estimatedWeightKg.toStringAsFixed(1)} kg')),
                  ]),
                ],
              ),
            ),
          )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ],
  );
}

class _ChartCard extends StatelessWidget {
  final bool isDark;
  final Widget chart;
  const _ChartCard({required this.isDark, required this.chart});
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: isDark ? Border.all(color: const Color(0xFF263350)) : null,
      boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: chart,
  );
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ListTileCard({required this.icon, required this.color, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  ]);
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    ]),
  );
}
