import 'package:flutter/material.dart';

class TankCard extends StatelessWidget {
  final dynamic tank;
  final bool isActive;
  final VoidCallback onTap;

  const TankCard({
    super.key,
    required this.tank,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cores baseadas no estado
    final textColor = isActive ? Colors.black87 : Colors.grey.shade500;
    final subTextColor = isActive ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isActive ? Colors.grey.shade600 : Colors.grey.shade400;
    
    // Mocks para dados faltantes
    final stock = isActive ? '${tank.fishCapacity}' : '--';
    final avgWeight = isActive ? '450 g' : '--';
    final biomass = isActive ? '${(tank.fishCapacity * 0.45).toInt()} kg' : '--';
    final growth = isActive ? 0.65 : 0.0;
    final mortality = isActive ? 0.012 : 0.0;
    final temp = isActive ? '26.4 °C' : '--';
    final ph = isActive ? 'pH 7.2' : '--';
    final deaths = isActive ? '30 peixes' : '--';

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Esquerda: Imagem com Tag
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 140,
                        color: Colors.blue.shade50,
                        child: isActive 
                            ? Image.network(
                                'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&q=80&w=200&h=280',
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  width: 110,
                  padding: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
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
                          Icon(Icons.warning_amber_rounded, size: 14, color: isActive ? Colors.red : iconColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              deaths, 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.red : textColor),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text('Este mês', style: TextStyle(fontSize: 9, color: subTextColor)),
                    ],
                  ),
                ),
              ],
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
                isActive ? 'Próxima despesca: 20/06/2026' : 'Sem previsão de despesca',
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
          width: 65,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: isActive ? Colors.grey.shade600 : Colors.grey.shade400),
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
