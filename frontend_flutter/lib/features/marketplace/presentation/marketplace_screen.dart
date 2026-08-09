import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:intl/intl.dart';
import '../data/announcement_api_service.dart';
import '../data/marketplace_order_model.dart';
import '../data/supplier_profile_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final _announcementServiceProvider = Provider<AnnouncementApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AnnouncementApiService(dio: dio);
});

class CategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  set value(String? val) => state = val;
}
final _filterCategoryProvider = NotifierProvider<CategoryNotifier, String?>(CategoryNotifier.new);

class LocationNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  set value(String? val) => state = val;
}
final _filterLocationProvider = NotifierProvider<LocationNotifier, String?>(LocationNotifier.new);

class SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  set value(String val) => state = val;
}
final _filterSearchProvider = NotifierProvider<SearchNotifier, String>(SearchNotifier.new);

final announcementsProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  final service = ref.watch(_announcementServiceProvider);
  final category = ref.watch(_filterCategoryProvider);
  final location = ref.watch(_filterLocationProvider);
  return service.fetchAll(category: category, location: location);
});

final myMarketplaceOrdersProvider = FutureProvider<List<MarketplaceOrder>>((ref) async {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final storedFarmId = await tokenStorage.getFarmId();
  final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

  try {
    final response = await dio.get('/api/marketplace/orders/buyer/$farmId');
    if (response.data != null && response.data is List) {
      return (response.data as List).map((json) => MarketplaceOrder.fromJson(json)).toList();
    }
  } catch (e) {
    debugPrint('[MarketplaceOrdersProvider] Erro ao carregar compras: $e');
  }
  return [];
});

final sellerMarketplaceOrdersProvider = FutureProvider<List<MarketplaceOrder>>((ref) async {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final storedFarmId = await tokenStorage.getFarmId();
  final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

  try {
    final response = await dio.get('/api/marketplace/orders/seller/$farmId');
    if (response.data != null && response.data is List) {
      return (response.data as List).map((json) => MarketplaceOrder.fromJson(json)).toList();
    }
  } catch (e) {
    debugPrint('[SellerMarketplaceOrdersProvider] Erro ao carregar vendas: $e');
  }
  return [];
});

final mySupplierProfileProvider = FutureProvider<SupplierProfile?>((ref) async {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final storedFarmId = await tokenStorage.getFarmId();
  final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

  try {
    final response = await dio.get('/api/marketplace/suppliers/farm/$farmId');
    if (response.data != null && response.data is Map<String, dynamic>) {
      return SupplierProfile.fromJson(response.data);
    }
  } catch (e) {
    debugPrint('[MySupplierProfileProvider] Nenhum perfil de fornecedor cadastrado ainda.');
  }
  return null;
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  static const _ufs = [
    'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
    'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO'
  ];

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

  String? _selectedUF;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index < 3) {
        final cats = ['ALEVINOS', 'RACAO', 'EQUIPAMENTOS'];
        ref.read(_filterCategoryProvider.notifier).value = cats[_tabController.index];
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AnnouncementModel> _applySearch(List<AnnouncementModel> items) {
    final q = ref.read(_filterSearchProvider).toLowerCase();
    if (q.isEmpty) return items;
    return items.where((i) =>
      i.title.toLowerCase().contains(q) ||
      i.sellerName.toLowerCase().contains(q) ||
      i.description.toLowerCase().contains(q)
    ).toList();
  }

  List<AnnouncementModel> _forCategory(List<AnnouncementModel> items, String cat) {
    return _applySearch(items.where((i) => i.category == cat).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(announcementsProvider);
    final buyerOrdersAsync = ref.watch(myMarketplaceOrdersProvider);
    final sellerOrdersAsync = ref.watch(sellerMarketplaceOrdersProvider);
    final supplierProfileAsync = ref.watch(mySupplierProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado B2B AquaGestor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          supplierProfileAsync.when(
            data: (profile) => profile != null
                ? TextButton.icon(
                    icon: const Icon(Icons.verified_user, color: Colors.white, size: 18),
                    label: Text(profile.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _showSupplierRegistrationDialog(context, profile: profile),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.storefront, color: Colors.white, size: 18),
                    label: const Text('Seja Fornecedor Credenciado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _showSupplierRegistrationDialog(context),
                  ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF13A538),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Alevinos', icon: Icon(Icons.set_meal)),
            Tab(text: 'Ração', icon: Icon(Icons.eco)),
            Tab(text: 'Equipamentos', icon: Icon(Icons.build)),
            Tab(text: 'Minhas Compras & Custódia', icon: Icon(Icons.shopping_bag_rounded)),
            Tab(text: 'Painel do Fornecedor (Vendas)', icon: Icon(Icons.store_rounded)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search & Filter header (only for categories tabs 0..2) ──────
          if (_tabController.index < 3)
            Container(
              color: isDark ? const Color(0xFF0D1B2A) : Colors.grey.shade50,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref.read(_filterSearchProvider.notifier).value = v,
                  decoration: InputDecoration(
                    hintText: 'Buscar produto ou vendedor...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(_filterSearchProvider.notifier).value = '';
                            })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUF,
                      hint: const Text('Estado (UF)', style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _ufs.map((uf) => DropdownMenuItem(value: uf, child: Text(uf, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (uf) {
                        setState(() {
                          _selectedUF = uf;
                          _selectedCity = null;
                        });
                        ref.read(_filterLocationProvider.notifier).value = uf;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text('Cidade', style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: (_selectedUF != null && _citiesByUF.containsKey(_selectedUF))
                          ? _citiesByUF[_selectedUF]!.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList()
                          : [],
                      onChanged: _selectedUF == null ? null : (city) {
                        setState(() => _selectedCity = city);
                        if (city != null && _selectedUF != null) {
                          ref.read(_filterLocationProvider.notifier).value = '$city - $_selectedUF';
                        }
                      },
                    ),
                  ),
                  if (_selectedUF != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off, size: 20, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _selectedUF = null;
                          _selectedCity = null;
                        });
                        ref.read(_filterLocationProvider.notifier).value = null;
                      },
                    ),
                  ],
                ]),
              ]),
            ),

          // ── Main Body Views ──────────────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar anúncios: $e', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(announcementsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (items) => TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_forCategory(items, 'ALEVINOS')),
                  _buildList(_forCategory(items, 'RACAO')),
                  _buildList(_forCategory(items, 'EQUIPAMENTOS')),
                  _buildMyOrdersTab(buyerOrdersAsync, isDark),
                  _buildSupplierSalesTab(sellerOrdersAsync, supplierProfileAsync, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Anunciar Produto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF13A538),
      ),
    );
  }

  // ── Card list ─────────────────────────────────────────────────────────────
  Widget _buildList(List<AnnouncementModel> list) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.storefront_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum anúncio nesta categoria.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final item = list[i];
        return GestureDetector(
          onTap: () => _showItemDetail(context, item),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                      ? Image.network(item.imageUrl!, width: 85, height: 85, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(item.category))
                      : _imagePlaceholder(item.category),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(item.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${currencyFmt.format(item.price)} / ${item.unitMeasure}',
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  color: Color(0xFF13A538), fontSize: 15)),
                          if (item.stockQuantity > 0)
                            Text('Estoque: ${item.stockQuantity} ${item.unitMeasure}s', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(item.sellerName, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder(String category) {
    final data = {
      'ALEVINOS': (Icons.set_meal, const Color(0xFF003366)),
      'RACAO': (Icons.eco, const Color(0xFF13A538)),
      'EQUIPAMENTOS': (Icons.build, Colors.orange),
    };
    final d = data[category] ?? (Icons.storefront, Colors.grey);
    return Container(
      width: 85, height: 85, color: d.$2.withOpacity(0.12),
      child: Icon(d.$1, color: d.$2, size: 36),
    );
  }

  // ── Detail modal ──────────────────────────────────────────────────────────
  void _showItemDetail(BuildContext context, AnnouncementModel item) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                    ? Image.network(item.imageUrl!, width: double.infinity, height: 200, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported, size: 60)))
                    : Container(height: 140, color: Colors.grey.shade100,
                        child: const Icon(Icons.storefront_outlined, size: 60)),
              ),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(item.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFmt.format(item.price),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                            color: Color(0xFF13A538))),
                    Text('por ${item.unitMeasure}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.verified_user_outlined, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text('Fornecedor: ${item.sellerName}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(item.sellerLocation, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
              ]),
              const SizedBox(height: 16),

              // Escrow Guarantee Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF13A538).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF13A538)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Color(0xFF13A538), size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Garantia de Custódia AquaGestor: Seu pagamento fica retido em segurança até você confirmar o recebimento do produto!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (item.specifications != null && item.specifications!.isNotEmpty) ...[
                const Text('Ficha Técnica & Especificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(item.specifications!, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
                const SizedBox(height: 16),
              ],

              if (item.deliveryTerms != null && item.deliveryTerms!.isNotEmpty) ...[
                const Text('Prazo & Condições de Entrega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.deliveryTerms!, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Text(item.description, style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Comprar com Pagamento Seguro em Custódia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 18),
                    label: const Text('Comprar via Pix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showPixComingSoonDialog(context, item);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.credit_card, color: Colors.white, size: 18),
                    label: const Text('Comprar via Cartão', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEscrowCheckoutModal(context, item, 'CARD');
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.phone_outlined, color: Color(0xFF13A538)),
                  label: Text('Contato com Vendedor: ${item.sellerPhone}',
                      style: const TextStyle(color: Color(0xFF13A538), fontSize: 14)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.sellerPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Telefone copiado: ${item.sellerPhone}')),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showPixComingSoonDialog(BuildContext ctx, AnnouncementModel item) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.pix_rounded, color: Color(0xFF009688), size: 28),
            SizedBox(width: 10),
            Text('Pagamento via Pix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O método de pagamento via Pix está em fase de homologação final e estará disponível em breve.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Para concluir seu pedido com total segurança e garantia de custódia pelo AquaGestor, utilize a opção de pagamento por Cartão.',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Entendido', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.credit_card, color: Colors.white, size: 18),
            label: const Text('Pagar com Cartão', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showEscrowCheckoutModal(context, item, 'CARD');
            },
          ),
        ],
      ),
    );
  }

  // ── Escrow Checkout Modal ─────────────────────────────────────────────────
  void _showEscrowCheckoutModal(BuildContext ctx, AnnouncementModel item, String paymentMethod) async {
    if (paymentMethod == 'PIX') {
      _showPixComingSoonDialog(ctx, item);
      return;
    }
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => _EscrowCheckoutDialog(
        item: item,
        paymentMethod: paymentMethod,
        onOrderCreated: () {
          ref.invalidate(myMarketplaceOrdersProvider);
          setState(() {
            _tabController.index = 3; // Switch to Minhas Compras tab
          });
        },
      ),
    );
  }

  // ── My Buyer Orders Tab ───────────────────────────────────────────────────
  Widget _buildMyOrdersTab(AsyncValue<List<MarketplaceOrder>> ordersAsync, bool isDark) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
      error: (e, _) => Center(child: Text('Erro ao carregar pedidos: $e', style: const TextStyle(color: Colors.red))),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.grey),
                SizedBox(height: 12),
                Text('Você ainda não realizou compras no Mercado Local.', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Compre com garantia de custódia e libere o valor após a entrega.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myMarketplaceOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              final isHeld = order.status.toUpperCase() == 'PAID_HELD';
              final isReleased = order.status.toUpperCase() == 'DELIVERED_RELEASED';

              Color statusColor = Colors.orange;
              String statusText = 'Aguardando Pagamento';
              IconData statusIcon = Icons.hourglass_top;

              if (isHeld) {
                statusColor = Colors.teal;
                statusText = '🔒 Retido em Custódia pelo AquaGestor';
                statusIcon = Icons.verified_user_rounded;
              } else if (isReleased) {
                statusColor = const Color(0xFF13A538);
                statusText = '✅ Entrega Confirmada & Dinheiro Liberado';
                statusIcon = Icons.check_circle_rounded;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order.announcementTitle,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            currencyFmt.format(order.totalAmount),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qtde: ${order.quantity} · Unitário: ${currencyFmt.format(order.unitPrice)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Vendedor: ${order.sellerName}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),

                      if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Entrega: ${order.deliveryAddress}${order.deliveryCity != null ? " - " + order.deliveryCity! : ""}${order.deliveryState != null ? "/" + order.deliveryState! : ""}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Status Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isHeld) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_box_outlined, color: Colors.white),
                            label: const Text(
                              'Confirmar Recebimento do Produto',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF13A538),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _confirmOrderDelivery(context, order),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Supplier Sales & Deliveries Tab ───────────────────────────────────────
  Widget _buildSupplierSalesTab(
    AsyncValue<List<MarketplaceOrder>> salesAsync,
    AsyncValue<SupplierProfile?> profileAsync,
    bool isDark,
  ) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      children: [
        // Supplier Header Banner
        profileAsync.when(
          data: (profile) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: profile != null ? const Color(0xFF003366) : Colors.orange.shade800,
            ),
            child: Row(
              children: [
                Icon(profile != null ? Icons.verified_user : Icons.storefront, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile != null ? profile.companyName : 'Fornecedor Não Credenciado',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        profile != null
                            ? 'CNPJ/CPF: ${profile.documentNumber ?? "Em verificação"} · Chave Pix: ${profile.pixKey ?? "Não informada"}'
                            : 'Cadastre sua empresa e chave Pix para receber os repasses das suas vendas.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(profile != null ? Icons.edit : Icons.how_to_reg, size: 16, color: Colors.black87),
                  label: Text(profile != null ? 'Editar' : 'Credenciar', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => _showSupplierRegistrationDialog(context, profile: profile),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),

        // Sales Orders List
        Expanded(
          child: salesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
            error: (e, _) => Center(child: Text('Erro ao carregar vendas: $e', style: const TextStyle(color: Colors.red))),
            data: (sales) {
              if (sales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.storefront_outlined, size: 52, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Sua empresa ainda não possui vendas registradas.', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Anuncie seus alevinos, rações e equipamentos para produtores da região.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(sellerMarketplaceOrdersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, i) {
                    final sale = sales[i];
                    final isHeld = sale.status.toUpperCase() == 'PAID_HELD';
                    final isReleased = sale.status.toUpperCase() == 'DELIVERED_RELEASED';

                    Color statusColor = Colors.orange;
                    String statusText = 'Aguardando Pagamento do Comprador';
                    IconData statusIcon = Icons.hourglass_top;

                    if (isHeld) {
                      statusColor = Colors.teal;
                      statusText = '🔒 Dinheiro Retido em Custódia (Aguardando Sua Entrega)';
                      statusIcon = Icons.verified_user_rounded;
                    } else if (isReleased) {
                      statusColor = const Color(0xFF13A538);
                      statusText = '✅ Entrega Concluída & Dinheiro Repassado ao Fornecedor';
                      statusIcon = Icons.check_circle_rounded;
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    sale.announcementTitle,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  currencyFmt.format(sale.totalAmount),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qtde Pedida: ${sale.quantity} unidades · Unitário: ${currencyFmt.format(sale.unitPrice)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Buyer info container
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Comprador: ${sale.buyerName ?? "Produtor Local"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  if (sale.buyerPhone != null && sale.buyerPhone!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('Contato: ${sale.buyerPhone}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ],
                                  if (sale.deliveryAddress != null && sale.deliveryAddress!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Endereço para Entrega: ${sale.deliveryAddress}${sale.deliveryCity != null ? " - " + sale.deliveryCity! : ""}${sale.deliveryState != null ? "/" + sale.deliveryState! : ""}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (sale.deliveryNotes != null && sale.deliveryNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Obs do Comprador: ${sale.deliveryNotes}', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Status Badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isHeld && sale.buyerPhone != null && sale.buyerPhone!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF13A538)),
                                  label: Text('Alinhar Entrega com ${sale.buyerName ?? "Comprador"}', style: const TextStyle(color: Color(0xFF13A538), fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF13A538)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: sale.buyerPhone!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Telefone do comprador copiado: ${sale.buyerPhone}')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmOrderDelivery(BuildContext context, MarketplaceOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF13A538), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Confirmar Entrega', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(
          'Deseja confirmar que você recebeu o produto "${order.announcementTitle}"?\n\n'
          'Ao confirmar, o valor de R\$ ${order.totalAmount.toStringAsFixed(2)} mantido em custódia será liberado ao fornecedor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13A538),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar & Liberar Dinheiro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final dio = ref.read(dioProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final storedFarmId = await tokenStorage.getFarmId();
      final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

      await dio.post('/api/marketplace/orders/${order.id}/confirm-delivery?farmId=$farmId');
      ref.invalidate(myMarketplaceOrdersProvider);
      ref.invalidate(sellerMarketplaceOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrega confirmada com sucesso! O valor foi liberado ao fornecedor.'),
            backgroundColor: Color(0xFF13A538),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao confirmar entrega: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Supplier Registration Modal ───────────────────────────────────────────
  void _showSupplierRegistrationDialog(BuildContext context, {SupplierProfile? profile}) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final farmId = (await tokenStorage.getFarmId()) ?? '55555555-5555-5555-5555-555555555555';

    final companyCtrl = TextEditingController(text: profile?.companyName ?? '');
    final docCtrl = TextEditingController(text: profile?.documentNumber ?? '');
    final ieCtrl = TextEditingController(text: profile?.stateRegistration ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    final emailCtrl = TextEditingController(text: profile?.email ?? '');
    final addressCtrl = TextEditingController(text: profile?.address ?? '');
    final cityCtrl = TextEditingController(text: profile?.city ?? '');
    final stateCtrl = TextEditingController(text: profile?.state ?? 'PE');
    final pixCtrl = TextEditingController(text: profile?.pixKey ?? '');
    String pixType = profile?.pixKeyType ?? 'CPF_CNPJ';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF003366)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile != null ? 'Editar Perfil do Fornecedor' : 'Credenciamento de Fornecedor',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(labelText: 'Razão Social / Nome Fantasia da Empresa *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: docCtrl,
                          decoration: const InputDecoration(labelText: 'CNPJ ou CPF *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: ieCtrl,
                          decoration: const InputDecoration(labelText: 'Inscrição Estadual (IE)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Telefone / WhatsApp *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-mail Comercial', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Endereço da Empresa / Galpão', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: stateCtrl,
                          decoration: const InputDecoration(labelText: 'UF', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Chave Pix para Recebimento das Vendas Liberadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: pixType,
                          decoration: const InputDecoration(labelText: 'Tipo de Chave', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'CPF_CNPJ', child: Text('CNPJ/CPF')),
                            DropdownMenuItem(value: 'PHONE', child: Text('Telefone')),
                            DropdownMenuItem(value: 'EMAIL', child: Text('E-mail')),
                            DropdownMenuItem(value: 'RANDOM', child: Text('Chave Aleatória')),
                          ],
                          onChanged: (v) => setS(() => pixType = v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: pixCtrl,
                          decoration: const InputDecoration(labelText: 'Chave Pix *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366)),
              onPressed: saving ? null : () async {
                if (companyCtrl.text.trim().isEmpty || docCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha Razão Social e CNPJ/CPF.')));
                  return;
                }

                setS(() => saving = true);
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/api/marketplace/suppliers/register', data: {
                    'farmId': farmId,
                    'companyName': companyCtrl.text.trim(),
                    'documentNumber': docCtrl.text.trim(),
                    'stateRegistration': ieCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'state': stateCtrl.text.trim(),
                    'pixKey': pixCtrl.text.trim(),
                    'pixKeyType': pixType,
                  });

                  ref.invalidate(mySupplierProfileProvider);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Perfil de fornecedor cadastrado com sucesso!')));
                } catch (e) {
                  setS(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar Credenciamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rich Product Upload Dialog ────────────────────────────────────────────
  void _showAddDialog(BuildContext context) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final farmId = (await tokenStorage.getFarmId()) ?? '';
    final storage = const FlutterSecureStorage();
    final sellerName = await storage.read(key: 'user_name') ?? 'Produtor Local';

    if (!mounted) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '100');
    final minOrderCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'Milheiro');
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Petrolina - PE');
    final imageCtrl = TextEditingController();
    final deliveryTermsCtrl = TextEditingController(text: 'Entrega própria em até 48h');
    final specsCtrl = TextEditingController();
    String selectedCategory = 'ALEVINOS';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart, color: Color(0xFF13A538)),
              SizedBox(width: 10),
              Expanded(
                child: Text('Novo Anúncio Profissional', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['ALEVINOS', 'RACAO', 'EQUIPAMENTOS']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título do Anúncio *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Preço (R\$) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unidade (ex: Milheiro, Saco 25kg, Kg) *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Estoque Atual *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: minOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pedido Mínimo *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Link da Foto do Produto (URL HTTPS)', border: OutlineInputBorder(), hintText: 'https://exemplo.com/foto.jpg'),
                ),
                const SizedBox(height: 10),
                TextField(controller: deliveryTermsCtrl, decoration: const InputDecoration(labelText: 'Prazos & Condições de Entrega', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição Breve', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: specsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Ficha Técnica / Especificações Detalhadas', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefone Vendedor', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Localização (Cidade - UF)', border: OutlineInputBorder()))),
                  ],
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF13A538)),
              onPressed: saving ? null : () async {
                final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                if (titleCtrl.text.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha título e preço válido.')));
                  return;
                }
                setS(() => saving = true);
                try {
                  final service = ref.read(_announcementServiceProvider);
                  await service.create(AnnouncementModel(
                    id: '',
                    farmId: farmId,
                    category: selectedCategory,
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    price: price,
                    sellerName: sellerName,
                    sellerPhone: phoneCtrl.text,
                    sellerLocation: locationCtrl.text,
                    imageUrl: imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null,
                    stockQuantity: int.tryParse(stockCtrl.text) ?? 100,
                    unitMeasure: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'Unidade',
                    minOrderQuantity: int.tryParse(minOrderCtrl.text) ?? 1,
                    deliveryTerms: deliveryTermsCtrl.text.trim(),
                    specifications: specsCtrl.text.trim(),
                    active: true,
                  ));
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ref.invalidate(announcementsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anúncio cadastrado com sucesso!')));
                } catch (e) {
                  setS(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')));
                }
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar Anúncio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowCheckoutDialog extends ConsumerStatefulWidget {
  final AnnouncementModel item;
  final String paymentMethod;
  final VoidCallback onOrderCreated;

  const _EscrowCheckoutDialog({
    required this.item,
    required this.paymentMethod,
    required this.onOrderCreated,
  });

  @override
  ConsumerState<_EscrowCheckoutDialog> createState() => _EscrowCheckoutDialogState();
}

class _EscrowCheckoutDialogState extends ConsumerState<_EscrowCheckoutDialog> {
  int _step = 1; // 1: Delivery Form & Quantity, 2: Stripe Payment QR Code
  int _quantity = 1;
  bool _isLoading = false;
  MarketplaceOrder? _order;
  String? _error;

  final _buyerNameCtrl = TextEditingController();
  final _buyerPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'PE');
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredUserData();
    _quantity = widget.item.minOrderQuantity > 0 ? widget.item.minOrderQuantity : 1;
  }

  Future<void> _loadStoredUserData() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'user_name') ?? 'Produtor Comprador';
    if (mounted) {
      setState(() {
        _buyerNameCtrl.text = name;
      });
    }
  }

  @override
  void dispose() {
    _buyerNameCtrl.dispose();
    _buyerPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrderAndCreatePayment() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o endereço completo para entrega.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final tokenStorage = ref.read(tokenStorageProvider);
      final storedFarmId = await tokenStorage.getFarmId();
      final farmId = storedFarmId ?? '55555555-5555-5555-5555-555555555555';

      final response = await dio.post(
        '/api/marketplace/orders/create-checkout',
        data: {
          'announcementId': widget.item.id,
          'buyerFarmId': farmId,
          'quantity': _quantity,
          'paymentMethod': widget.paymentMethod,
          'buyerName': _buyerNameCtrl.text.trim(),
          'buyerPhone': _buyerPhoneCtrl.text.trim(),
          'deliveryAddress': _addressCtrl.text.trim(),
          'deliveryCity': _cityCtrl.text.trim(),
          'deliveryState': _stateCtrl.text.trim(),
          'deliveryNotes': _notesCtrl.text.trim(),
        },
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _order = MarketplaceOrder.fromJson(response.data);
          _isLoading = false;
          _step = 2;
        });
        widget.onOrderCreated();
      } else {
        throw Exception('Resposta do servidor vazia.');
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
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final unitPrice = widget.item.price;
    final totalPrice = unitPrice * _quantity;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF13A538)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _step == 1 ? 'Endereço & Quantidade' : 'Pagamento em Custódia',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step == 1) ...[
                // Product Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Color(0xFF13A538)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Preço Unitário: ${currencyFmt.format(unitPrice)} por ${widget.item.unitMeasure}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity Selector
                const Text('Quantidade Desejada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: _quantity > widget.item.minOrderQuantity ? const Color(0xFF13A538) : Colors.grey),
                        onPressed: _quantity > widget.item.minOrderQuantity ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity ${widget.item.unitMeasure}s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF13A538)),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a Pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      currencyFmt.format(totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF13A538)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Delivery Address & Contact Fields
                const Text('Informações de Entrega & Contato', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _buyerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo do Comprador',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _buyerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone para Contato (WhatsApp)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endereço Completo (Rua/Estrada, Nº, Bairro/Gleba)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'UF',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ponto de Referência / Observações para Entregador',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ] else if (_isLoading) ...[
                const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
                const SizedBox(height: 16),
                const Center(child: Text('Gerando pedido e chave Pix em custódia...', textAlign: TextAlign.center)),
              ] else if (_error != null) ...[
                const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40)),
                const SizedBox(height: 12),
                Center(child: Text('Erro ao gerar pedido:\n$_error', style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center)),
              ] else if (_order != null) ...[
                Center(
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    currencyFmt.format(_order!.totalAmount),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF13A538)),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seu pagamento fica retido em custódia pelo AquaGestor. O fornecedor só receberá após você confirmar a entrega.',
                          style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.paymentMethod == 'PIX' && _order!.pixCopyPaste != null) ...[
                  const SizedBox(height: 16),
                  if (_order!.pixQrCode != null && _order!.pixQrCode!.startsWith('http'))
                    Center(child: Image.network(_order!.pixQrCode!, width: 180, height: 180, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 100)))
                  else
                    const Center(child: Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF009688))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _order!.pixCopyPaste!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF009688), size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _order!.pixCopyPaste!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chave Pix Copia e Cola copiada!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_step == 1) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock, color: Colors.white, size: 16),
            label: const Text('Gerar Pagamento Seguro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13A538),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _submitOrderAndCreatePayment,
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido / Ver Minhas Compras'),
          ),
        ],
      ],
    );
  }
}
