import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

class SupplierDevScreen extends ConsumerWidget {
  const SupplierDevScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1329) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: isDark ? 8 : 2,
                color: isDark ? const Color(0xFF1C2541) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated or Pulsing Icon container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF38BDF8).withOpacity(0.1) 
                              : const Color(0xFF003366).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Heading
                      Text(
                        'Módulo em Desenvolvimento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'Olá! O AquaGestor está preparando uma experiência completa para a gestão de fornecedores.\n\nEste módulo está em fase de desenvolvimento e logo você poderá gerenciar suas propostas, acompanhar pedidos e visualizar estatísticas de vendas diretamente por aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ref.read(authNotifierProvider.notifier).logout();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Sair da Conta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
