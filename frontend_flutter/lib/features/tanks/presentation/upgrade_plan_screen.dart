import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:intl/intl.dart';

/// Shown when the user hits a plan limit (HTTP 402) or accesses plan subscription options.
class UpgradePlanScreen extends ConsumerStatefulWidget {
  final int currentTanks;
  final int maxAllowed;
  final String? initialPlanId;
  final VoidCallback? onUpgrade;

  static Future<void> startDirectStripeCheckout(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _StripeCheckoutDialog(planId: planId),
    );
  }

  const UpgradePlanScreen({
    super.key,
    required this.currentTanks,
    required this.maxAllowed,
    this.initialPlanId,
    this.onUpgrade,
  });

  @override
  ConsumerState<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends ConsumerState<UpgradePlanScreen> {
  bool _isLoading = false;
  String? _loadingPlanId;
  String? _manualCheckoutUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlanId != null && widget.initialPlanId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startStripeCheckout(widget.initialPlanId!);
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Cancelar Assinatura', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tem certeza de que deseja cancelar a renovação da sua assinatura no Stripe?\n\n'
          'Seu acesso continuará garantido até o final do período de cobrança atual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter Assinatura', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Cancelamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final farmId = (await tokenStorage.getFarmId()) ?? '55555555-5555-5555-5555-555555555555';

      await dio.post('/api/billing/cancel-subscription/$farmId');
      ref.invalidate(activeSubscriptionDetailsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assinatura cancelada com sucesso. Seu acesso continuará até o fim do período.'),
            backgroundColor: Colors.deepOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar assinatura: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startStripeCheckout(String planId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingPlanId = planId;
      _manualCheckoutUrl = null;
    });

    try {
      debugPrint('[Stripe] Iniciando criação de sessão de checkout para plano: $planId');
      final dio = ref.read(dioProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final storedFarmId = await tokenStorage.getFarmId();
      final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

      final response = await dio.post(
        '/api/billing/create-checkout-session',
        data: {
          'farmId': farmId,
          'planId': planId,
          'successUrl': 'http://localhost:8082/#/payment-success',
          'cancelUrl': 'http://localhost:8082/#/payment-cancel',
        },
      );

      debugPrint('[Stripe] Resposta recebida: ${response.data}');
      final checkoutUrl = response.data['checkoutUrl'] as String?;

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        setState(() {
          _manualCheckoutUrl = checkoutUrl;
        });

        debugPrint('[Stripe] Redirecionando para URL: $checkoutUrl');
        final uri = Uri.parse(checkoutUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        );

        debugPrint('[Stripe] Resultado do launchUrl: $launched');
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navegador bloqueou abertura automática. Clique no botão verde abaixo para pagar.'),
              backgroundColor: Colors.deepOrange,
            ),
          );
        }
      } else {
        throw Exception('URL de checkout nula ou vazia.');
      }
    } catch (e, stack) {
      debugPrint('[Stripe] Erro no checkout: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar pagamento no Stripe: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingPlanId = null;
        });
      }
    }
  }

  Widget _buildActiveSubscriptionDashboardCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionDetails sub,
    bool isDark,
    NumberFormat currencyFmt,
  ) {
    final isActive = sub.status.toUpperCase() == 'ACTIVE';
    final isCancelled = sub.status.toUpperCase() == 'CANCELLED';

    Color statusColor = Colors.grey;
    String statusText = 'Plano Gratuito';
    IconData statusIcon = Icons.info_outline;

    if (isActive) {
      statusColor = const Color(0xFF13A538);
      statusText = 'Assinatura Ativa (Renovação Automática)';
      statusIcon = Icons.check_circle_rounded;
    } else if (isCancelled) {
      statusColor = Colors.deepOrange;
      statusText = 'Assinatura Cancelada';
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sub.planName,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _subDetailItem(
                  context,
                  Icons.calendar_today_rounded,
                  'Próxima Cobrança / Vencimento',
                  sub.nextBillingDate ?? sub.endDate ?? 'N/A',
                  isDark,
                ),
              ),
              Expanded(
                child: _subDetailItem(
                  context,
                  Icons.payment_rounded,
                  'Forma de Pagamento',
                  sub.cardLast4 != null
                      ? '${sub.cardBrand?.toUpperCase() ?? "Cartão"} •••• ${sub.cardLast4}'
                      : (sub.paymentMethodType ?? 'Stripe Checkout'),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _subDetailItem(
                  context,
                  Icons.attach_money_rounded,
                  'Valor Mensal',
                  sub.priceMonthly > 0 ? '${currencyFmt.format(sub.priceMonthly)}/mês' : 'R\$ 0,00 (Grátis)',
                  isDark,
                ),
              ),
              Expanded(
                child: _subDetailItem(
                  context,
                  Icons.water_drop_rounded,
                  'Recursos Liberados',
                  'Até ${sub.maxTanks} tanques · ${sub.maxUsers} usuários',
                  isDark,
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                label: const Text('Cancelar Assinatura Stripe', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _cancelSubscription,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subDetailItem(BuildContext context, IconData icon, String title, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    if (widget.onUpgrade != null) {
      widget.onUpgrade!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tanks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plansAsync = ref.watch(plansProvider);
    final subAsync = ref.watch(activeSubscriptionDetailsProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade & Assinatura Stripe'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBack(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header Icon ─────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13A538), Color(0xFF0E7A2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13A538).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),

              // ── Title & Subtitle ────────────────────────────────────────────
              const Text(
                'Escolha o Plano Ideal para Sua Piscicultura',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Atualmente você possui ${widget.currentTanks} tanque${widget.currentTanks > 1 ? 's' : ''} cadastrado${widget.currentTanks > 1 ? 's' : ''} (Limite Atual: ${widget.maxAllowed}).\nFaça o upgrade agora via Stripe para liberar mais recursos e tanques!',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Real-Time Stripe Subscription Dashboard ─────────────────────
              subAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (subDetails) => _buildActiveSubscriptionDashboardCard(
                  context,
                  ref,
                  subDetails,
                  isDark,
                  currencyFmt,
                ),
              ),

              // ── Direct Stripe Manual Link Banner (if generated) ──────────────
              if (_manualCheckoutUrl != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13A538).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF13A538), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF13A538)),
                          SizedBox(width: 8),
                          Text(
                            'Sessão de Pagamento Criada com Sucesso!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13A538), fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text(
                          'Ir para Checkout Stripe agora 💳',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13A538),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          launchUrl(
                            Uri.parse(_manualCheckoutUrl!),
                            mode: LaunchMode.platformDefault,
                            webOnlyWindowName: '_self',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // ── Dynamic Plans List ──────────────────────────────────────────
              plansAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Erro ao carregar planos: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (plans) {
                  return Column(
                    children: plans.map((plan) {
                      final isFree = plan.priceMonthly == 0;
                      final isCurrent = plan.maxTanks == widget.maxAllowed;
                      final isThisLoading = _isLoading && _loadingPlanId == plan.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: !isFree
                                ? const Color(0xFF13A538)
                                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                            width: !isFree ? 2 : 1,
                          ),
                          boxShadow: !isFree
                              ? [BoxShadow(color: const Color(0xFF13A538).withOpacity(0.1), blurRadius: 12)]
                              : [],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (plan.name.toLowerCase().contains('pro') || plan.priceMonthly == 59.90) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF13A538).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'RECOMENDADO 🚀',
                                              style: TextStyle(
                                                color: Color(0xFF13A538),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    isFree ? 'Grátis' : '${currencyFmt.format(plan.priceMonthly)}/mês',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: !isFree ? const Color(0xFF13A538) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Chip(
                                    avatar: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                    label: Text('Até ${plan.maxTanks} tanques'),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    avatar: const Icon(Icons.people, size: 16, color: Colors.purple),
                                    label: Text('Até ${plan.maxUsers} usuários'),
                                    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.purple.shade50,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (isFree || _isLoading)
                                      ? null
                                      : () => _startStripeCheckout(plan.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF13A538),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isThisLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          isFree
                                              ? 'Plano Atual (Básico)'
                                              : 'Assinar Plano ${plan.name} via Stripe 💳',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar para Tanques', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _handleBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripeCheckoutDialog extends ConsumerStatefulWidget {
  final String planId;
  const _StripeCheckoutDialog({required this.planId});

  @override
  ConsumerState<_StripeCheckoutDialog> createState() => _StripeCheckoutDialogState();
}

class _StripeCheckoutDialogState extends ConsumerState<_StripeCheckoutDialog> {
  bool _isLoading = true;
  String? _checkoutUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    try {
      final dio = ref.read(dioProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final farmId = (await tokenStorage.getFarmId()) ?? '55555555-5555-5555-5555-555555555555';

      final response = await dio.post(
        '/api/billing/create-checkout-session',
        data: {
          'farmId': farmId,
          'planId': widget.planId,
          'successUrl': 'http://localhost:8082/#/payment-success',
          'cancelUrl': 'http://localhost:8082/#/payment-cancel',
        },
      );

      final url = response.data['checkoutUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _checkoutUrl = url;
          _isLoading = false;
        });

        // Launch immediately
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        );
      } else {
        throw Exception('URL de pagamento nula.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.payment, color: Color(0xFF13A538)),
          const SizedBox(width: 10),
          const Text('Checkout Stripe'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(color: Color(0xFF13A538)),
              const SizedBox(height: 16),
              const Text('Conectando ao Stripe Checkout...', textAlign: TextAlign.center),
            ] else if (_error != null) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text('Erro ao iniciar pagamento:\n$_error', style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
            ] else if (_checkoutUrl != null) ...[
              const Icon(Icons.check_circle_outline, color: Color(0xFF13A538), size: 40),
              const SizedBox(height: 12),
              const Text('Sessão de pagamento pronta!', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text('Ir para Checkout Stripe agora 💳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF13A538), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onPressed: () {
                  launchUrl(
                    Uri.parse(_checkoutUrl!),
                    mode: LaunchMode.platformDefault,
                    webOnlyWindowName: '_self',
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
