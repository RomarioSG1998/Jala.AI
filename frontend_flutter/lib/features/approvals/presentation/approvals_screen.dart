import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/approvals/providers/approval_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  String _activeFilter = 'Pendentes'; // Default to show pending requests first
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(approvalNotifierProvider.notifier).refreshRequests();
    });
  }

  ({Color color, IconData icon}) _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'APROVADO':
        return (color: Colors.green, icon: Icons.check_circle_outline);
      case 'REJECTED':
      case 'REJEITADO':
        return (color: Colors.red, icon: Icons.highlight_off);
      default:
        return (color: Colors.orange, icon: Icons.pending_outlined);
    }
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'APROVADO':
        return 'Aprovado';
      case 'REJECTED':
      case 'REJEITADO':
        return 'Rejeitado';
      default:
        return 'Pendente';
    }
  }

  Future<void> _handleAction(String requestId, String status, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar $label'),
        content: Text('Deseja realmente marcar esta solicitação como $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loadingStates[requestId] = true;
    });

    final success = await ref
        .read(approvalNotifierProvider.notifier)
        .resolveRequest(requestId, status);

    setState(() {
      _loadingStates[requestId] = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Solicitação $label com sucesso!'
              : 'Falha ao processar solicitação.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvalsAsync = ref.watch(approvalNotifierProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(approvalNotifierProvider.notifier).refreshRequests(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildFilterBar(),
                  ],
                ),
              ),
              approvalsAsync.when(
                data: (requests) {
                  final filtered = requests.where((req) {
                    // Status filter
                    if (_activeFilter == 'Pendentes') {
                      return req.status.toUpperCase() == 'PENDING';
                    }
                    if (_activeFilter == 'Aprovados') {
                      return req.status.toUpperCase() == 'APPROVED' || req.status.toUpperCase() == 'APROVADO';
                    }
                    if (_activeFilter == 'Rejeitados') {
                      return req.status.toUpperCase() == 'REJECTED' || req.status.toUpperCase() == 'REJEITADO';
                    }
                    return true;
                  }).where((req) {
                    // Search query filter
                    if (searchQuery.isEmpty) return true;
                    final query = searchQuery.toLowerCase();
                    return req.requestedAction.toLowerCase().contains(query) ||
                        req.status.toLowerCase().contains(query) ||
                        _translateStatus(req.status).toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        context,
                        message: searchQuery.isNotEmpty
                            ? 'Nenhuma solicitação para "$searchQuery"'
                            : 'Nenhuma solicitação nesta categoria.',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final req = filtered[index];
                          final style = _statusStyle(req.status);
                          final isPending = req.status.toUpperCase() == 'PENDING';
                          final isLoading = _loadingStates[req.id] ?? false;

                          DateTime date;
                          try {
                            date = DateTime.parse(req.requestDate);
                          } catch (_) {
                            date = DateTime.now();
                          }
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF263350) : Colors.black12,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(style.icon, color: style.color, size: 20),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: style.color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _translateStatus(req.status),
                                              style: TextStyle(
                                                color: style.color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    req.requestedAction,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Solicitado por ID: ${req.requesterId.split('-').first}...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                  if (isPending) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                            foregroundColor: Colors.red,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : () => _handleAction(req.id, 'REJECTED', 'Rejeitar'),
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Rejeitar'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : () => _handleAction(req.id, 'APPROVED', 'Aprovar'),
                                          icon: isLoading
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check, size: 16),
                                          label: const Text('Aprovar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Erro ao carregar solicitações: $err',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF003366),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Central de Aprovações',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Monitore e julgue lançamentos operacionais de campo',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterPill('Pendentes'),
            const SizedBox(width: 8),
            _filterPill('Aprovados'),
            const SizedBox(width: 8),
            _filterPill('Rejeitados'),
            const SizedBox(width: 8),
            _filterPill('Todos'),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String label) {
    final isSelected = _activeFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366))
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.black87),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
