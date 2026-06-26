import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/announcement_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final _announcementServiceProvider = Provider<AnnouncementApiService>((_) => AnnouncementApiService());

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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) {
      final cats = [null, 'ALEVINOS', 'RACAO', 'EQUIPAMENTOS'];
      ref.read(_filterCategoryProvider.notifier).value = cats[_tabController.index + 1];
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedor Local',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // ── Filtros ──────────────────────────────────────────────────────
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
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
                    onChanged: (v) {
                      setState(() { _selectedUF = v; _selectedCity = null; });
                      ref.read(_filterLocationProvider.notifier).value = v;
                    },
                  ),
                ),
                const SizedBox(width: 8),
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
                    onChanged: _selectedUF == null ? null : (v) {
                      setState(() => _selectedCity = v);
                      ref.read(_filterLocationProvider.notifier).value = v;
                    },
                  ),
                ),
              ]),
              if (_selectedUF != null || _selectedCity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.filter_alt, size: 14, color: Color(0xFF13A538)),
                    const SizedBox(width: 4),
                    Text(
                      'Filtrando: ${_selectedCity ?? ''} ${_selectedUF != null ? '- $_selectedUF' : ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF13A538), fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() { _selectedUF = null; _selectedCity = null; });
                        ref.read(_filterLocationProvider.notifier).value = null;
                      },
                      child: const Text('Limpar', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ]),
                ),
            ]),
          ),
          // ── Lista ────────────────────────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar anúncios\n$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
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
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Anunciar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF13A538),
      ),
    );
  }

  // ── Card list ─────────────────────────────────────────────────────────────
  Widget _buildList(List<AnnouncementModel> list) {
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
                      ? Image.network(item.imageUrl!, width: 80, height: 80, fit: BoxFit.cover,
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
                      Text('R\$ ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold,
                              color: Color(0xFF13A538), fontSize: 16)),
                      Text(item.sellerName,
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
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
      width: 80, height: 80,
      color: d.$2.withOpacity(0.12),
      child: Icon(d.$1, color: d.$2, size: 36),
    );
  }

  // ── Detail modal ──────────────────────────────────────────────────────────
  void _showItemDetail(BuildContext context, AnnouncementModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
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
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                    ? Image.network(item.imageUrl!, width: double.infinity, height: 180, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported, size: 60)))
                    : Container(height: 120, color: Colors.grey.shade100,
                        child: const Icon(Icons.storefront_outlined, size: 60)),
              ),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(item.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Text('R\$ ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: Color(0xFF13A538))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.store_outlined, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(item.sellerName, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(item.sellerLocation, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
              ]),
              const SizedBox(height: 16),
              Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Text(item.description, style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Formas de Pagamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _paymentChip(Icons.pix, 'Pix', Colors.teal)),
                const SizedBox(width: 12),
                Expanded(child: _paymentChip(Icons.credit_card, 'Cartão', Colors.blue)),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.pix, color: Colors.white),
                  label: const Text('Pagar com Pix',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                child: TextButton.icon(
                  icon: const Icon(Icons.phone_outlined, color: Color(0xFF13A538)),
                  label: Text('Contato: ${item.sellerPhone}',
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

  Widget _paymentChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  void _showPixModal(BuildContext ctx, AnnouncementModel item) {
    final pixKey = item.sellerPhone.replaceAll(RegExp(r'\D'), '');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.pix, color: Color(0xFF009688)),
          SizedBox(width: 8),
          Text('Pagamento via Pix', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Valor: R\$ ${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13A538))),
          const SizedBox(height: 16),
          const Text('Chave Pix (telefone do vendedor):', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(pixKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFF009688)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pixKey));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Chave Pix copiada!')));
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Text(
            'Após o pagamento, entre em contato com o vendedor para confirmar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  // ── Add dialog ────────────────────────────────────────────────────────────
  void _showAddDialog(BuildContext context) async {
    final storage = const FlutterSecureStorage();
    final farmId = await storage.read(key: 'farm_id') ?? '';
    final sellerName = await storage.read(key: 'user_name') ?? 'Produtor Local';

    if (!mounted) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String selectedCategory = 'ALEVINOS';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          title: const Text('Novo Anúncio'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['ALEVINOS', 'RACAO', 'EQUIPAMENTOS']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setS(() => selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Preço (R\$)', prefixText: 'R\$ ')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone de contato')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Cidade - Estado', hintText: 'Ex: Petrolina - PE')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF13A538), foregroundColor: Colors.white),
              onPressed: saving ? null : () async {
                final price = double.tryParse(priceCtrl.text);
                if (titleCtrl.text.isEmpty || price == null) return;
                setS(() => saving = true);
                try {
                  final model = AnnouncementModel(
                    id: '',
                    farmId: farmId,
                    category: selectedCategory,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    price: price,
                    sellerName: sellerName,
                    sellerPhone: phoneCtrl.text.trim().isEmpty ? '(00) 00000-0000' : phoneCtrl.text.trim(),
                    sellerLocation: locationCtrl.text.trim().isEmpty ? 'Brasil' : locationCtrl.text.trim(),
                    active: true,
                  );
                  await ref.read(_announcementServiceProvider).create(model);
                  ref.invalidate(announcementsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Anúncio publicado com sucesso!')));
                  }
                } catch (e) {
                  setS(() => saving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao publicar: $e')));
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
