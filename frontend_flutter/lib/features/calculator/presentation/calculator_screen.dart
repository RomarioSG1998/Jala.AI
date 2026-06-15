import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();

  double _biomass = 0.0; // kg
  double _dailyFeed = 0.0; // kg
  int _daysToHarvest = 0; // days

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final averageWeightGrams = double.tryParse(_weightController.text) ?? 0.0;

    if (quantity <= 0 || averageWeightGrams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira valores válidos maiores que zero.')),
      );
      return;
    }

    setState(() {
      // 1. Cálculo da Biomassa Total (em kg)
      _biomass = (quantity * averageWeightGrams) / 1000.0;

      // 2. Cálculo da Quantidade diária de ração (simplificado para Tilápia)
      double feedRate = 0.03; // Default 3%
      if (averageWeightGrams < 10) {
        feedRate = 0.10; // 10%
      } else if (averageWeightGrams < 50) {
        feedRate = 0.06; // 6%
      } else if (averageWeightGrams < 150) {
        feedRate = 0.04; // 4%
      } else if (averageWeightGrams < 300) {
        feedRate = 0.03; // 3%
      } else if (averageWeightGrams < 600) {
        feedRate = 0.02; // 2%
      } else {
        feedRate = 0.015; // 1.5%
      }
      
      _dailyFeed = _biomass * feedRate;

      // 3. Previsão de abate (Estimativa simples para alcançar 800g)
      const targetWeight = 800.0;
      if (averageWeightGrams >= targetWeight) {
        _daysToHarvest = 0;
      } else {
        // Assume ganho de peso médio de 3.5g por dia
        final weightDiff = targetWeight - averageWeightGrams;
        _daysToHarvest = (weightDiff / 3.5).ceil();
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightController.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parâmetros do Tanque',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de peixes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Obrigatório';
                      if (int.tryParse(val) == null) return 'Apenas números inteiros';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso médio (gramas)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      suffixText: 'g',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Obrigatório';
                      if (double.tryParse(val) == null) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13A538),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Calcular Resultados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_biomass > 0) ...[
              Text(
                'Resultados Estimados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              _buildResultCard(
                context,
                title: 'Quantidade diária de ração',
                value: '${_dailyFeed.toStringAsFixed(2)} kg/dia',
                icon: Icons.restaurant,
                color: Colors.orange,
              ),
              _buildResultCard(
                context,
                title: 'Biomassa total',
                value: '${_biomass.toStringAsFixed(2)} kg',
                icon: Icons.water,
                color: Colors.blue,
              ),
              _buildResultCard(
                context,
                title: 'Previsão de abate (800g)',
                value: _daysToHarvest == 0 ? 'Pronto para abate!' : 'Aprox. $_daysToHarvest dias',
                icon: Icons.agriculture,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 24,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
