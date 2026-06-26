import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MarketplaceCategory { alevinos, racao, equipamentos }

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String seller;
  final String sellerPhone;
  final String sellerLocation;
  final MarketplaceCategory category;
  final String imageUrl;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.seller,
    this.sellerPhone = '(00) 00000-0000',
    this.sellerLocation = 'Brasil',
    required this.category,
    required this.imageUrl,
  });
}

// Provedor temporário de estado (simulando um banco de dados)
class MarketplaceNotifier extends Notifier<List<MarketplaceItem>> {
  @override
  List<MarketplaceItem> build() {
    return _initialItems;
  }

  static final List<MarketplaceItem> _initialItems = [
    MarketplaceItem(
      id: '1',
      title: 'Alevinos de Tilápia Gift',
      description: 'Lote com 1000 alevinos revertidos. Alto ganho de peso. Origem certificada, saúde garantida.',
      price: 350.0,
      seller: 'Piscicultura Águas Claras',
      sellerPhone: '(87) 99901-2345',
      sellerLocation: 'Petrolina - PE',
      category: MarketplaceCategory.alevinos,
      imageUrl: 'https://via.placeholder.com/150/003366/FFFFFF?text=Alevinos',
    ),
    MarketplaceItem(
      id: '2',
      title: 'Ração Inicial 40% Proteína',
      description: 'Saco de 25kg. Ideal para os primeiros 30 dias. Granulometria 1,0mm.',
      price: 120.0,
      seller: 'Agro Rações Nordeste',
      sellerPhone: '(81) 98765-4321',
      sellerLocation: 'Caruaru - PE',
      category: MarketplaceCategory.racao,
      imageUrl: 'https://via.placeholder.com/150/13A538/FFFFFF?text=Racao',
    ),
    MarketplaceItem(
      id: '3',
      title: 'Aerador Chafariz 1CV',
      description: 'Equipamento semi-novo, usado por 6 meses. Trifásico. Excelente conservação.',
      price: 1500.0,
      seller: 'Fazenda São João',
      sellerPhone: '(83) 99234-5678',
      sellerLocation: 'Sousa - PB',
      category: MarketplaceCategory.equipamentos,
      imageUrl: 'https://via.placeholder.com/150/E65100/FFFFFF?text=Aerador',
    ),
  ];

  void addItem(MarketplaceItem item) {
    state = [...state, item];
  }
}

final marketplaceProvider = NotifierProvider<MarketplaceNotifier, List<MarketplaceItem>>(() {
  return MarketplaceNotifier();
});

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Filtros de Localização ─────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  String? _selectedUF;
  String? _selectedCity;

  static const _ufs = [
    'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
    'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO'
  ];

  // Cidades por UF (amostra — em produção buscar da API IBGE)
  static const Map<String, List<String>> _citiesByUF = {
    'SP': ['São Paulo','Campinas','Ribeirão Preto','Santos','Sorocaba'],
    'PE': ['Recife','Petrolina','Caruaru','Olinda','Garanhuns'],
    'PB': ['João Pessoa','Campina Grande','Sousa','Patos','Santa Rita'],
    'BA': ['Salvador','Feira de Santana','Vitória da Conquista','Camaçari'],
    'CE': ['Fortaleza','Juazeiro do Norte','Sobral','Crato'],
    'MG': ['Belo Horizonte','Uberlândia','Contagem','Juiz de Fora'],
    'RN': ['Natal','Mossoró','Parnamirim','Caicó'],
    'MA': ['São Luís','Imperatriz','Timon','Caxias'],
    'GO': ['Goiânia','Aparecida de Goiânia','Anápolis','Rio Verde'],
    'AM': ['Manaus','Parintins','Itacoatiara','Manacapuru'],
    'PA': ['Belém','Santarém','Marabá','Castanhal'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<MarketplaceItem> _applyFilters(List<MarketplaceItem> items) {
    return items.where((item) {
      final textMatch = _searchText.isEmpty ||
          item.title.toLowerCase().contains(_searchText) ||
          item.seller.toLowerCase().contains(_searchText) ||
          item.description.toLowerCase().contains(_searchText);

      final ufMatch = _selectedUF == null ||
          item.sellerLocation.toUpperCase().contains(_selectedUF!);

      final cityMatch = _selectedCity == null ||
          item.sellerLocation.toLowerCase().contains(_selectedCity!.toLowerCase());

      return textMatch && ufMatch && cityMatch;
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(marketplaceProvider);
    final alevinos = _applyFilters(items.where((i) => i.category == MarketplaceCategory.alevinos).toList());
    final racoes = _applyFilters(items.where((i) => i.category == MarketplaceCategory.racao).toList());
    final equipamentos = _applyFilters(items.where((i) => i.category == MarketplaceCategory.equipamentos).toList());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedor Local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF13A538),
          tabs: const [
            Tab(text: 'Alevinos', icon: Icon(Icons.set_meal)),
            Tab(text: 'Ração', icon: Icon(Icons.eco)),
            Tab(text: 'Equipamentos', icon: Icon(Icons.build)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Barra de Filtros ──────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF0D1B2A) : Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar produto ou vendedor...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { _searchCtrl.clear(); setState(() => _searchText = ''); },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Dropdowns UF + Cidade
                Row(
                  children: [
                    // UF
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUF,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Estado (UF)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ..._ufs.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))),
                        ],
                        onChanged: (v) => setState(() { _selectedUF = v; _selectedCity = null; }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cidade
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Município',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          ...(_selectedUF != null && _citiesByUF.containsKey(_selectedUF!)
                              ? _citiesByUF[_selectedUF!]!.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                              : []),
                        ],
                        onChanged: _selectedUF == null ? null : (v) => setState(() => _selectedCity = v),
                      ),
                    ),
                  ],
                ),
                // Chip de filtro ativo
                if (_selectedUF != null || _selectedCity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, size: 14, color: Color(0xFF13A538)),
                        const SizedBox(width: 4),
                        Text(
                          'Filtrando: ${_selectedCity ?? ''} ${_selectedUF != null ? '- $_selectedUF' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF13A538), fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() { _selectedUF = null; _selectedCity = null; }),
                          child: const Text('Limpar', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(alevinos),
                _buildList(racoes),
                _buildList(equipamentos),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Anunciar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF13A538),
      ),
    );
  }

  Widget _buildList(List<MarketplaceItem> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Nenhum item anunciado nesta categoria.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return GestureDetector(
          onTap: () => _showItemDetail(context, item),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('R\$ ${item.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF13A538), fontSize: 16)),
                            Text(item.seller, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Modal de Detalhes + Pagamento ──────────────────────────────────────────
  void _showItemDetail(BuildContext context, MarketplaceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // Imagem
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Título e preço
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      'R\$ ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Vendedor e localização
                Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(item.seller, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(item.sellerLocation, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                  ],
                ),
                const SizedBox(height: 16),

                // Descrição
                Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(item.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                // Formas de Pagamento
                const Text('Formas de Pagamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _paymentChip(Icons.pix, 'Pix', Colors.teal)),
                    const SizedBox(width: 12),
                    Expanded(child: _paymentChip(Icons.credit_card, 'Cartão', Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _paymentChip(Icons.money, 'Dinheiro', Colors.green.shade700)),
                    const SizedBox(width: 12),
                    Expanded(child: _paymentChip(Icons.receipt_long_outlined, 'Boleto', Colors.orange)),
                  ],
                ),
                const SizedBox(height: 28),

                // Botões de ação
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pix, color: Colors.white),
                    label: const Text('Pagar com Pix', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showPixModal(ctx, item),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.credit_card, color: Color(0xFF003366)),
                    label: const Text('Pagar com Cartão', style: TextStyle(color: Color(0xFF003366), fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003366), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showCardModal(ctx, item),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.phone_outlined, color: Color(0xFF13A538)),
                    label: Text('Contato: ${item.sellerPhone}', style: const TextStyle(color: Color(0xFF13A538), fontSize: 14)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contato do vendedor: ${item.sellerPhone}')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Modal PIX ──────────────────────────────────────────────────────────────
  void _showPixModal(BuildContext ctx, MarketplaceItem item) {
    const pixKey = '12345678901'; // chave fictícia
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.pix, color: Color(0xFF009688)),
            SizedBox(width: 8),
            Text('Pagamento via Pix', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Valor: R\$ ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
            ),
            const SizedBox(height: 16),
            const Text('Chave Pix do vendedor:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pixKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF009688)),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: pixKey));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Chave Pix copiada!')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Após o pagamento, entre em contato com o vendedor para confirmar o envio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ── Modal Cartão ───────────────────────────────────────────────────────────
  void _showCardModal(BuildContext ctx, MarketplaceItem item) {
    final cardCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.credit_card, color: Color(0xFF003366)),
            SizedBox(width: 8),
            Text('Pagamento com Cartão', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valor: R\$ ${item.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cardCtrl,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: const InputDecoration(
                  labelText: 'Número do Cartão',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nome no Cartão',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Validade (MM/AA)',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cvvCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Em produção, integre com uma gateway de pagamento (ex: Stripe, Mercado Pago).',
                style: TextStyle(fontSize: 11, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Pedido registrado! Aguardando confirmação do vendedor.')),
              );
            },
            child: const Text('Confirmar Pagamento'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    MarketplaceCategory selectedCategory = MarketplaceCategory.alevinos;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Novo Anúncio'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MarketplaceCategory>(
                    value: selectedCategory,
                    items: MarketplaceCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
                  const SizedBox(height: 8),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço (R\$)')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone de Contato')),
                  const SizedBox(height: 8),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Cidade - Estado')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  if (titleCtrl.text.isNotEmpty && price > 0) {
                    ref.read(marketplaceProvider.notifier).addItem(MarketplaceItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      price: price,
                      seller: 'Você (Produtor Local)',
                      sellerPhone: phoneCtrl.text.isEmpty ? '(00) 00000-0000' : phoneCtrl.text,
                      sellerLocation: locationCtrl.text.isEmpty ? 'Brasil' : locationCtrl.text,
                      category: selectedCategory,
                      imageUrl: 'https://via.placeholder.com/150/808080/FFFFFF?text=Novo',
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Publicar'),
              ),
            ],
          );
        }
      ),
    );
  }
}
