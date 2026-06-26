import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Modelos de Espécie ─────────────────────────────────────────────────────

class FishSpeciesData {
  final String name;
  final String emoji;
  /// Taxa de alimentação por faixa de peso [gramas_min, gramas_max, taxa%]
  final List<List<double>> feedRates;
  /// Proteína recomendada por faixa de peso
  final List<List<dynamic>> proteinRanges; // [min_g, max_g, proteína%]
  /// Granulometria por faixa de peso (mm)
  final List<List<dynamic>> granulometry;  // [min_g, max_g, "tamanho"]
  /// Tratos por dia por faixa de peso
  final List<List<dynamic>> treatmentsPerDay;
  /// Peso médio de abate (g)
  final double harvestWeightG;
  /// Ganho de peso médio por dia (g)
  final double dailyGainG;

  const FishSpeciesData({
    required this.name,
    required this.emoji,
    required this.feedRates,
    required this.proteinRanges,
    required this.granulometry,
    required this.treatmentsPerDay,
    required this.harvestWeightG,
    required this.dailyGainG,
  });
}

const _species = <FishSpeciesData>[
  FishSpeciesData(
    name: 'Tilápia',
    emoji: '🐟',
    feedRates: [
      [0, 10, 0.10],   // 10%
      [10, 50, 0.07],  // 7%
      [50, 150, 0.05], // 5%
      [150, 300, 0.04],// 4%
      [300, 600, 0.03],// 3%
      [600, 9999, 0.02],// 2%
    ],
    proteinRanges: [
      [0, 10, '45%'],
      [10, 50, '40%'],
      [50, 300, '32%'],
      [300, 9999, '28%'],
    ],
    granulometry: [
      [0, 10, '0,5 mm (micro)'],
      [10, 50, '1,0 mm (pequena)'],
      [50, 300, '2,0–3,0 mm (média)'],
      [300, 9999, '4,0–6,0 mm (grande)'],
    ],
    treatmentsPerDay: [
      [0, 50, 6],
      [50, 200, 4],
      [200, 9999, 3],
    ],
    harvestWeightG: 900,
    dailyGainG: 3.5,
  ),
  FishSpeciesData(
    name: 'Tambaqui',
    emoji: '🐠',
    feedRates: [
      [0, 30, 0.08],
      [30, 100, 0.06],
      [100, 500, 0.04],
      [500, 9999, 0.02],
    ],
    proteinRanges: [
      [0, 30, '40%'],
      [30, 200, '32%'],
      [200, 9999, '28%'],
    ],
    granulometry: [
      [0, 30, '1,0 mm'],
      [30, 200, '3,0 mm'],
      [200, 9999, '6,0 mm'],
    ],
    treatmentsPerDay: [
      [0, 100, 4],
      [100, 9999, 3],
    ],
    harvestWeightG: 1500,
    dailyGainG: 4.5,
  ),
  FishSpeciesData(
    name: 'Pacu',
    emoji: '🐡',
    feedRates: [
      [0, 50, 0.08],
      [50, 200, 0.05],
      [200, 9999, 0.03],
    ],
    proteinRanges: [
      [0, 50, '36%'],
      [50, 9999, '28%'],
    ],
    granulometry: [
      [0, 50, '1,0 mm'],
      [50, 300, '3,0 mm'],
      [300, 9999, '6,0 mm'],
    ],
    treatmentsPerDay: [
      [0, 100, 4],
      [100, 9999, 3],
    ],
    harvestWeightG: 1200,
    dailyGainG: 4.0,
  ),
  FishSpeciesData(
    name: 'Pirarucu',
    emoji: '🐟',
    feedRates: [
      [0, 100, 0.05],
      [100, 500, 0.04],
      [500, 9999, 0.02],
    ],
    proteinRanges: [
      [0, 100, '45%'],
      [100, 9999, '38%'],
    ],
    granulometry: [
      [0, 100, '2,0 mm'],
      [100, 9999, '6,0–8,0 mm'],
    ],
    treatmentsPerDay: [
      [0, 200, 3],
      [200, 9999, 2],
    ],
    harvestWeightG: 8000,
    dailyGainG: 20.0,
  ),
  FishSpeciesData(
    name: 'Pintado',
    emoji: '🐟',
    feedRates: [
      [0, 50, 0.06],
      [50, 300, 0.04],
      [300, 9999, 0.02],
    ],
    proteinRanges: [
      [0, 50, '42%'],
      [50, 9999, '32%'],
    ],
    granulometry: [
      [0, 50, '1,0–2,0 mm'],
      [50, 9999, '4,0–6,0 mm'],
    ],
    treatmentsPerDay: [
      [0, 9999, 3],
    ],
    harvestWeightG: 1500,
    dailyGainG: 5.0,
  ),
];

// ── Helpers ────────────────────────────────────────────────────────────────

double _getFeedRate(FishSpeciesData sp, double weightG) {
  for (final r in sp.feedRates) {
    if (weightG >= r[0] && weightG < r[1]) return r[2];
  }
  return sp.feedRates.last[2];
}

String _getProtein(FishSpeciesData sp, double weightG) {
  for (final r in sp.proteinRanges) {
    if (weightG >= (r[0] as num) && weightG < (r[1] as num)) return r[2] as String;
  }
  return sp.proteinRanges.last[2] as String;
}

String _getGranulometry(FishSpeciesData sp, double weightG) {
  for (final r in sp.granulometry) {
    if (weightG >= (r[0] as num) && weightG < (r[1] as num)) return r[2] as String;
  }
  return sp.granulometry.last[2] as String;
}

int _getTreatments(FishSpeciesData sp, double weightG) {
  for (final r in sp.treatmentsPerDay) {
    if (weightG >= (r[0] as num) && weightG < (r[1] as num)) return r[2] as int;
  }
  return sp.treatmentsPerDay.last[2] as int;
}

// ── Resultado do Cálculo ───────────────────────────────────────────────────

class CalcResult {
  final double biomassKg;
  final double dailyFeedKg;
  final double feedPerTreatmentKg;
  final int treatmentsPerDay;
  final String proteinLevel;
  final String granulometry;
  final int daysToHarvest;
  final bool tempAlert;
  final List<_GrowthStep> growthSimulation;

  CalcResult({
    required this.biomassKg,
    required this.dailyFeedKg,
    required this.feedPerTreatmentKg,
    required this.treatmentsPerDay,
    required this.proteinLevel,
    required this.granulometry,
    required this.daysToHarvest,
    required this.tempAlert,
    required this.growthSimulation,
  });
}

class _GrowthStep {
  final int day;
  final double weightG;
  final String phase;

  _GrowthStep(this.day, this.weightG, this.phase);
}

// ── Tela ───────────────────────────────────────────────────────────────────

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _tempController = TextEditingController();

  FishSpeciesData _selectedSpecies = _species[0]; // Tilápia
  CalcResult? _result;

  CalcResult _calculate({
    required FishSpeciesData species,
    required int quantity,
    required double weightG,
    required double? tempC,
  }) {
    final feedRate = _getFeedRate(species, weightG);
    final biomassKg = (quantity * weightG) / 1000.0;
    final dailyFeedKg = biomassKg * feedRate;
    final treatments = _getTreatments(species, weightG);
    final feedPerTreatment = dailyFeedKg / treatments;
    final protein = _getProtein(species, weightG);
    final granulometry = _getGranulometry(species, weightG);

    // Dias até abate
    final daysToHarvest = weightG >= species.harvestWeightG
        ? 0
        : ((species.harvestWeightG - weightG) / species.dailyGainG).ceil();

    // Simulação de crescimento — amostragem a cada 15 dias
    final List<_GrowthStep> simulation = [];
    double currentWeight = weightG;
    int day = 0;
    while (currentWeight < species.harvestWeightG) {
      String phase;
      if (currentWeight < 30) {
        phase = 'Alevino';
      } else if (currentWeight < 100) {
        phase = 'Juvenil';
      } else if (currentWeight < species.harvestWeightG * 0.6) {
        phase = 'Crescimento';
      } else {
        phase = 'Terminação';
      }
      simulation.add(_GrowthStep(day, currentWeight, phase));
      currentWeight += species.dailyGainG * 15;
      day += 15;
      if (simulation.length > 30) break; // Limite de segurança
    }
    simulation.add(_GrowthStep(day, species.harvestWeightG, 'Abate ✅'));

    return CalcResult(
      biomassKg: biomassKg,
      dailyFeedKg: dailyFeedKg,
      feedPerTreatmentKg: feedPerTreatment,
      treatmentsPerDay: treatments,
      proteinLevel: protein,
      granulometry: granulometry,
      daysToHarvest: daysToHarvest,
      tempAlert: tempC != null && tempC >= 33,
      growthSimulation: simulation,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final weightG = double.tryParse(_weightController.text) ?? 0.0;
    final tempC = double.tryParse(_tempController.text);

    setState(() {
      _result = _calculate(
        species: _selectedSpecies,
        quantity: quantity,
        weightG: weightG,
        tempC: tempC,
      );
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calculadora Zootécnica', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Seção: Parâmetros ─────────────────────────────────────────
              _sectionTitle('Parâmetros do Tanque', isDark),
              const SizedBox(height: 16),

              // Seleção de espécie
              _label('Espécie', isDark),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _species.map((sp) {
                    final isSelected = sp.name == _selectedSpecies.name;
                    return GestureDetector(
                      onTap: () => setState(() { _selectedSpecies = sp; _result = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF13A538) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? null : Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(sp.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(sp.name, style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Quantidade e peso
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de peixes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.set_meal_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso médio (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'g',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperatura
              TextFormField(
                controller: _tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Temperatura da Água (°C) — opcional',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.thermostat_outlined),
                  suffixText: '°C',
                  helperText: '≥ 33°C: alerta de não alimentar',
                  helperStyle: TextStyle(color: Colors.orange.shade700),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Calcular Resultados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              // ── Resultados ────────────────────────────────────────────────
              if (_result != null) ...[
                const SizedBox(height: 32),

                // Alerta de temperatura
                if (_result!.tempAlert) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Temperatura elevada!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                'Não recomendado alimentar os peixes com temperatura ≥ 33°C. Aguarde o resfriamento da água.',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _sectionTitle('Recomendação de Trato — ${_selectedSpecies.emoji} ${_selectedSpecies.name}', isDark),
                const SizedBox(height: 12),

                _resultCard(context, Icons.restaurant, Colors.orange,
                  'Ração diária total', '${_result!.dailyFeedKg.toStringAsFixed(2)} kg/dia', isDark),
                _resultCard(context, Icons.repeat, Colors.blue,
                  'Tratos por dia', '${_result!.treatmentsPerDay} tratos', isDark),
                _resultCard(context, Icons.restaurant_menu, Colors.teal,
                  'Ração por trato', '${_result!.feedPerTreatmentKg.toStringAsFixed(2)} kg/trato', isDark),
                _resultCard(context, Icons.science_outlined, Colors.purple,
                  'Nível de proteína', _result!.proteinLevel, isDark),
                _resultCard(context, Icons.grain, Colors.brown,
                  'Granulometria (ração)', _result!.granulometry, isDark),
                _resultCard(context, Icons.water, Colors.blue.shade700,
                  'Biomassa total', '${_result!.biomassKg.toStringAsFixed(2)} kg', isDark),
                _resultCard(context, Icons.agriculture, Colors.green,
                  'Previsão de abate (${(_selectedSpecies.harvestWeightG / 1000).toStringAsFixed(1)} kg)',
                  _result!.daysToHarvest == 0 ? 'Pronto para abate! 🎉' : 'Aprox. ${_result!.daysToHarvest} dias',
                  isDark),

                // ── Simulação de Crescimento ──────────────────────────────
                const SizedBox(height: 32),
                _sectionTitle('Simulação de Crescimento', isDark),
                const SizedBox(height: 4),
                Text('Evolução do alevino até o abate (a cada 15 dias)',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                const SizedBox(height: 12),

                ..._result!.growthSimulation.map((step) => _buildGrowthRow(step, _selectedSpecies.harvestWeightG, isDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) => Text(
    text,
    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
  );

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey.shade700),
  );

  Widget _resultCard(BuildContext context, IconData icon, Color color, String title, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthRow(_GrowthStep step, double harvestWeightG, bool isDark) {
    final progress = (step.weightG / harvestWeightG).clamp(0.0, 1.0);
    final isHarvest = step.phase.contains('Abate');

    Color phaseColor;
    switch (step.phase) {
      case 'Alevino': phaseColor = Colors.cyan; break;
      case 'Juvenil': phaseColor = Colors.blue; break;
      case 'Crescimento': phaseColor = Colors.orange; break;
      case 'Terminação': phaseColor = Colors.deepOrange; break;
      default: phaseColor = Colors.green; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isHarvest
            ? Colors.green.withOpacity(isDark ? 0.15 : 0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHarvest ? Colors.green.shade300 : (isDark ? const Color(0xFF263350) : Colors.transparent),
          width: isHarvest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(step.phase, style: TextStyle(fontSize: 11, color: phaseColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('Dia ${step.day}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade500)),
              const Spacer(),
              Text(
                step.weightG >= 1000
                    ? '${(step.weightG / 1000).toStringAsFixed(2)} kg'
                    : '${step.weightG.toStringAsFixed(0)} g',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: phaseColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
