import 'package:flutter/material.dart';

/// Shown when the user tries to create a tank and hits the plan limit (HTTP 402).
class UpgradePlanScreen extends StatelessWidget {
  final int currentTanks;
  final int maxAllowed;
  final VoidCallback? onUpgrade;

  const UpgradePlanScreen({
    super.key,
    required this.currentTanks,
    required this.maxAllowed,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ────────────────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13A538), Color(0xFF0E7A2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF13A538).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 28),

              // ── Title ────────────────────────────────────────────────────────
              const Text(
                'Limite do Plano Gratuito',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Você já possui $currentTanks tanque${currentTanks > 1 ? 's' : ''} cadastrado${currentTanks > 1 ? 's' : ''} e o plano gratuito permite apenas $maxAllowed.',
                style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── Plan comparison ──────────────────────────────────────────────
              _PlanCard(
                title: 'Plano Gratuito',
                price: 'R\$ 0/mês',
                features: const [
                  '1 tanque',
                  'Dashboard completo',
                  'Controle financeiro',
                  'Previsão do tempo',
                ],
                isCurrent: true,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _PlanCard(
                title: 'Plano Pro 🚀',
                price: 'R\$ 19,90/mês',
                features: const [
                  'Tanques ilimitados',
                  'Relatórios com gráficos reais',
                  'Alertas e notificações',
                  'Marketplace de anúncios',
                  'Suporte prioritário',
                ],
                isCurrent: false,
                isDark: isDark,
                highlighted: true,
              ),
              const SizedBox(height: 32),

              // ── CTA ──────────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: const Text(
                    'Fazer Upgrade para Pro',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13A538),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                    shadowColor: const Color(0xFF13A538).withOpacity(0.4),
                  ),
                  onPressed: onUpgrade ?? () {
                    // TODO: navigate to payment flow / external link
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve: link de assinatura Pro!')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool isDark;
  final bool highlighted;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.isCurrent,
    required this.isDark,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? const Color(0xFF13A538) : Colors.grey.withOpacity(0.3);
    final bgColor = highlighted
        ? const Color(0xFF13A538).withOpacity(0.06)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: highlighted ? 2 : 1),
        boxShadow: highlighted
            ? [BoxShadow(color: const Color(0xFF13A538).withOpacity(0.15), blurRadius: 16)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,
                  color: highlighted ? const Color(0xFF13A538) : null)),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Atual', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
              color: highlighted ? const Color(0xFF13A538) : Colors.grey)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.check_circle, size: 16,
                  color: highlighted ? const Color(0xFF13A538) : Colors.grey),
              const SizedBox(width: 8),
              Text(f, style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87)),
            ]),
          )),
        ],
      ),
    );
  }
}
