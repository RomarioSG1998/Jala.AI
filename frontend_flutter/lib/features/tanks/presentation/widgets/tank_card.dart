import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_by_tank_provider.dart';

class TankCard extends ConsumerWidget {
  final Tank tank;
  final bool isActive;
  final VoidCallback onTap;

  const TankCard({
    super.key,
    required this.tank,
    required this.isActive,
    required this.onTap,
  });

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        // e.g. 2026-05-25 -> 25/05/2026
        return '${parts[2].split('T')[0]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cores baseadas no estado
    final textColor = isActive ? Colors.black87 : Colors.grey.shade500;
    final subTextColor = isActive ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isActive ? Colors.grey.shade600 : Colors.grey.shade400;
    
    // Real values mapped from database
    final currentStock = tank.fishCapacity - tank.mortalityCount;
    final stock = isActive ? '$currentStock' : '--';
    final avgWeight = isActive ? '${tank.averageWeightG} g' : '--';
    
    // Calculate biomass: (currentStock * avgWeightG) / 1000
    final calculatedBiomass = (currentStock * tank.averageWeightG) / 1000;
    final biomass = isActive ? '${calculatedBiomass.toInt()} kg' : '--';
    
    // Growth target: 1kg (1000g) = 100%
    final growth = isActive ? (tank.averageWeightG / 1000.0).clamp(0.0, 1.0) : 0.0;
    
    // Mortality rate: deaths / capacity
    final mortality = isActive && tank.fishCapacity > 0
        ? (tank.mortalityCount / tank.fishCapacity).clamp(0.0, 1.0)
        : 0.0;
    
    final deaths = isActive ? '${tank.mortalityCount} peixes' : '--';

    // Watch latest water quality reading for this tank
    final wqAsync = ref.watch(waterQualityByTankProvider(tank.id));
    final temp = wqAsync.maybeWhen(
      data: (wq) => wq != null ? '${wq.temperature.toStringAsFixed(1)} °C' : '--',
      orElse: () => '--',
    );
    final ph = wqAsync.maybeWhen(
      data: (wq) => wq != null ? 'pH ${wq.ph.toStringAsFixed(1)}' : '--',
      orElse: () => '--',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Esquerda: Imagem com Tag
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Stack(
                       children: [                         Container(
                          width: 90,
                          height: 140,
                          color: Colors.blue.shade50,
                          child: isActive 
                              ? Image.network(
                                  '/tank_piscicultura.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.water, color: Colors.blue, size: 40),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.water, color: Colors.grey, size: 40),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF13A538) : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'Ativo' : 'Inativo',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Centro: Dados do Lote
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tank.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tank.fishSpecies}  •  $stock peixes',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                          const SizedBox(height: 12),
                          
                          // 3 mini colunas
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _miniMetric(Icons.inventory_2_outlined, 'Estoque', stock, iconColor, textColor),
                              _miniMetric(Icons.monitor_weight_outlined, 'Peso méd.', avgWeight, iconColor, textColor),
                              _miniMetric(Icons.scale_outlined, 'Biomassa', biomass, iconColor, textColor),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          // Barras de Status
                          _progressBar('Crescimento', growth, const Color(0xFF13A538), isActive),
                          const SizedBox(height: 6),
                          _progressBar('Mortalidade', mortality, Colors.red, isActive),
                        ],
                      ),
                    ),
                  ),
                  
                  // Direita: Água e Alertas
                  Container(
                    width: 95,
                    padding: const EdgeInsets.only(top: 12, right: 8, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.device_thermostat, size: 14, color: isActive ? Colors.blue : iconColor),
                            const SizedBox(width: 4),
                            Text(temp, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.water_drop, size: 14, color: isActive ? Colors.blue : iconColor),
                            const SizedBox(width: 4),
                            Text(ph, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 14, color: subTextColor),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: isActive && tank.mortalityCount > 0 ? Colors.red : iconColor),
                            const SizedBox(width: 4),
                            Text(
                              deaths, 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive && tank.mortalityCount > 0 ? Colors.red : textColor),
                            ),
                          ],
                        ),
                        Text('Este mês', style: TextStyle(fontSize: 9, color: subTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Text(
                isActive && tank.nextHarvestDate != null
                    ? 'Próxima despesca: ${_formatDate(tank.nextHarvestDate!)}'
                    : 'Sem previsão de despesca',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: iconColor)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _progressBar(String label, double percent, Color color, bool isActive) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: isActive ? Colors.grey.shade600 : Colors.grey.shade400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(isActive ? color : Colors.grey.shade400),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? '${(percent * 100).toStringAsFixed(1)}%' : '--',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? color : Colors.grey.shade400),
        ),
      ],
    );
  }
}
