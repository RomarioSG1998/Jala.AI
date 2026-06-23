import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MarketplaceCategory { alevinos, racao, equipamentos }

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String seller;
  final MarketplaceCategory category;
  final String imageUrl;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.seller,
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
      description: 'Lote com 1000 alevinos revertidos. Alto ganho de peso.',
      price: 350.0,
      seller: 'Piscicultura Águas Claras',
      category: MarketplaceCategory.alevinos,
      imageUrl: 'https://via.placeholder.com/150/003366/FFFFFF?text=Alevinos',
    ),
    MarketplaceItem(
      id: '2',
      title: 'Ração Inicial 40% Proteína',
      description: 'Saco de 25kg. Ideal para os primeiros 30 dias.',
      price: 120.0,
      seller: 'Agro Rações Nordeste',
      category: MarketplaceCategory.racao,
      imageUrl: 'https://via.placeholder.com/150/13A538/FFFFFF?text=Racao',
    ),
    MarketplaceItem(
      id: '3',
      title: 'Aerador Chafariz 1CV',
      description: 'Equipamento semi-novo, usado por 6 meses. Trifásico.',
      price: 1500.0,
      seller: 'Fazenda São João',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(marketplaceProvider);
    final alevinos = items.where((i) => i.category == MarketplaceCategory.alevinos).toList();
    final racoes = items.where((i) => i.category == MarketplaceCategory.racao).toList();
    final equipamentos = items.where((i) => i.category == MarketplaceCategory.equipamentos).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado Local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(alevinos),
          _buildList(racoes),
          _buildList(equipamentos),
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
        return Card(
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
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
