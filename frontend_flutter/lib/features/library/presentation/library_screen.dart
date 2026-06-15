import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/library/providers/library_provider.dart';

class LibraryArticle {
  final String title;
  final String subtitle;
  final String content;
  final IconData icon;
  final Color color;

  LibraryArticle({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.color,
  });
}

class LibraryProduct {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double price;
  final IconData icon;
  final Color color;
  final String content;

  LibraryProduct({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final List<LibraryArticle> _articles = [
    LibraryArticle(
      title: 'Manejo da Tilápia',
      subtitle: 'Técnicas essenciais de criação',
      icon: Icons.water,
      color: Colors.blue,
      content: '''
# Guia Básico de Manejo da Tilápia

1. **Aclimatação dos Alevinos**: Nunca jogue os alevinos direto no tanque. Deixe os sacos plásticos boiando na água do tanque por 15 a 20 minutos para equalizar a temperatura.
2. **Frequência de Alimentação**: 
   - Alevinos: 4 a 6 vezes ao dia.
   - Juvenis: 3 a 4 vezes ao dia.
   - Adultos: 2 vezes ao dia.
3. **Biometria**: Realize a biometria a cada 15 a 30 dias para ajustar a taxa de arraçoamento e acompanhar o crescimento do lote.
      ''',
    ),
    LibraryArticle(
      title: 'Qualidade da Água',
      subtitle: 'Parâmetros ideais para o tanque',
      icon: Icons.science,
      color: Colors.teal,
      content: '''
# Parâmetros de Qualidade da Água

A água é o bem mais precioso na piscicultura. Mantenha os seguintes parâmetros controlados:

- **Oxigênio Dissolvido**: Acima de 4 mg/L. (Abaixo de 3 mg/L os peixes param de comer).
- **Temperatura**: Ideal entre 27°C e 30°C. Abaixo de 22°C o metabolismo cai drasticamente.
- **pH**: Ideal entre 6,5 e 8,5. Variações bruscas causam mortalidade.
- **Amônia Tóxica**: Deve ser mantida o mais próximo de ZERO possível (Abaixo de 0,1 mg/L). Faça renovação de água caso os níveis subam.
      ''',
    ),
    LibraryArticle(
      title: 'Doenças Comuns',
      subtitle: 'Sintomas e tratamentos preventivos',
      icon: Icons.medication,
      color: Colors.red,
      content: '''
# Principais Doenças em Tilápias

1. **Estreptococose (Olho saltado e nado em espiral)**
   - *Causa*: Bactéria Streptococcus, comum no verão com água muito quente e rica em matéria orgânica.
   - *Prevenção*: Reduza a quantidade de ração e aumente a aeração e renovação da água.

2. **Íctio (Doença dos pontos brancos)**
   - *Causa*: Parasita comum em quedas bruscas de temperatura (inverno).
   - *Prevenção*: Uso de sal grosso na água (1 a 3 kg por 1000 litros) como preventivo durante frentes frias.

3. **Fungos (Manchas de algodão pelo corpo)**
   - *Causa*: Manuseio incorreto durante a biometria ou predadores machucando o peixe.
   - *Prevenção*: Sempre molhe as mãos e os puçás antes de tocar nos peixes.
      ''',
    ),
  ];

  static final List<LibraryProduct> _products = [
    LibraryProduct(
      id: 'ebook_tilapia_pro',
      title: 'E-book: Segredos da Tilápia de Alto Rendimento',
      subtitle: 'Como maximizar peso e conversão alimentar',
      description: 'Aprenda as estratégias nutricionais avançadas utilizadas pelas grandes pisciculturas para acelerar o ciclo de engorda da Tilápia GIFT.',
      price: 29.90,
      icon: Icons.auto_stories,
      color: Colors.amber.shade700,
      content: '''
# Segredos da Tilápia de Alto Rendimento (Conteúdo Completo)

## 1. A Curva de Crescimento Acelerado
Para obter o máximo rendimento da tilápia, é preciso entender as fases do ciclo biológico. Dividimos a engorda em três fases principais: inicial, recria e terminação.

## 2. Otimização do FCA (Fator de Conversão Alimentar)
O FCA ideal deve ficar abaixo de 1.3. Para alcançar isso:
- Alimente apenas nos horários de maior temperatura (e oxigenação elevada).
- Evite desperdício de ração usando comedouros adequados.
- Realize o controle semanal de biometria para reajustar as porções.

## 3. Manejo Sanitário de Alta Performance
Use probióticos na ração para melhorar a flora intestinal do peixe e reduzir a incidência de infecções bacterianas intestinais.
      ''',
    ),
    LibraryProduct(
      id: 'course_nutricao',
      title: 'Curso: Nutrição e Arraçoamento Inteligente',
      subtitle: 'Vídeo-aulas e planilhas de cálculo',
      description: 'Aprenda a criar sua própria estratégia de arraçoamento baseada em temperatura e oxigênio, economizando até 20% em gastos com ração.',
      price: 89.90,
      icon: Icons.play_circle_filled,
      color: Colors.purple,
      content: '''
# Curso de Nutrição Inteligente (Conteúdo Completo)

## Módulo 1: A Fisiologia Digestiva da Tilápia
Aprenda como as enzimas digestivas funcionam de acordo com as variações de temperatura da água.

## Módulo 2: Planilha de Arraçoamento Dinâmico
Baixe e utilize a planilha para calcular a quantidade exata de ração baseando-se na biomassa total estimada e no oxigênio dissolvido registrado.

## Módulo 3: Práticas de Campo e Ajustes
Veja os vídeos práticos demonstrando o comportamento de saciedade e como evitar a superalimentação que degrada os parâmetros de água.
      ''',
    ),
    LibraryProduct(
      id: 'ebook_qualidade_agua',
      title: 'E-book: Controle Avançado de Qualidade da Água',
      subtitle: 'Fórmulas e estratégias de aeração',
      description: 'Um guia prático com fórmulas para cálculo de oxigenação e dimensionamento correto de aeradores chafariz ou propulsores.',
      price: 19.90,
      icon: Icons.menu_book,
      color: Colors.teal.shade700,
      content: '''
# Controle Avançado de Qualidade da Água (Conteúdo Completo)

## 1. Oxigênio e Taxa de Transferência
Como calcular a eficiência do seu aerador chafariz de acordo com a salinidade e temperatura local.

## 2. Gestão do Ciclo do Nitrogênio
Descubra como acelerar o crescimento de bactérias nitrificantes benéficas usando fontes de carbono baratas (melaço de cana) na proporção C:N correta.

## 3. Solução de Emergências
O que fazer em caso de queda rápida de oxigênio durante a madrugada: uso emergencial de peróxido de hidrogênio e circulação mecânica de água limpa.
      ''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showArticle(BuildContext context, LibraryArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: article.color.withOpacity(0.2),
                    child: Icon(article.icon, color: article.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      article.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  article.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _readProduct(BuildContext context, LibraryProduct product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: product.color.withOpacity(0.2),
                    child: Icon(product.icon, color: product.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      product.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  product.content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckout(BuildContext context, LibraryProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutModal(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchased = ref.watch(purchasedProductsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Biblioteca do Produtor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF13A538),
          tabs: const [
            Tab(text: 'Artigos & Manuais', icon: Icon(Icons.menu_book)),
            Tab(text: 'Cursos & E-books', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Articles
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: article.color.withOpacity(isDark ? 0.2 : 0.1),
                    radius: 28,
                    child: Icon(article.icon, color: article.color, size: 30),
                  ),
                  title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(article.subtitle),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showArticle(context, article),
                ),
              );
            },
          ),
          
          // Tab 2: Premium Courses & E-books
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final isUnlocked = purchased.contains(product.id);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: product.color.withOpacity(0.15),
                            radius: 24,
                            child: Icon(product.icon, color: product.color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  product.subtitle,
                                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isUnlocked
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.lock_open, color: Colors.green, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Adquirido',
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  'R\$ ${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: product.color,
                                  ),
                                ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isUnlocked) {
                                _readProduct(context, product);
                              } else {
                                _showCheckout(context, product);
                              }
                            },
                            icon: Icon(
                              isUnlocked ? Icons.menu_book : Icons.shopping_bag,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              isUnlocked ? 'Ler Conteúdo' : 'Adquirir',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnlocked ? Colors.green : const Color(0xFF003366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckoutModal extends ConsumerStatefulWidget {
  final LibraryProduct product;
  const _CheckoutModal({required this.product});

  @override
  ConsumerState<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<_CheckoutModal> {
  int _paymentMethod = 0; // 0 = Pix, 1 = Cartão
  bool _loading = false;
  bool _success = false;

  final _cardController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_paymentMethod == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
        ref.read(purchasedProductsProvider.notifier).purchase(widget.product.id);
        
        Future.delayed(const Duration(seconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_success) {
      return Container(
        height: 380,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 40,
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pagamento Confirmado!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'O produto "${widget.product.title}" já está disponível para leitura na sua biblioteca.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Começar a Ler', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 520,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF003366)),
                    SizedBox(height: 16),
                    Text('Processando pagamento...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detalhes da Compra',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: widget.product.color.withOpacity(0.15),
                      child: Icon(widget.product.icon, color: widget.product.color),
                    ),
                    title: Text(widget.product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Acesso vitalício ao conteúdo'),
                    trailing: Text(
                      'R\$ ${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Forma de Pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.pix, size: 16),
                          label: const Text('Pix (Instantâneo)'),
                          selected: _paymentMethod == 0,
                          onSelected: (val) {
                            if (val) setState(() => _paymentMethod = 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.credit_card, size: 16),
                          label: const Text('Cartão'),
                          selected: _paymentMethod == 1,
                          onSelected: (val) {
                            if (val) setState(() => _paymentMethod = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _paymentMethod == 0 ? _buildPixPayment() : _buildCardPayment(),
                  ),
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13A538),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _paymentMethod == 0 ? 'Confirmar Pagamento Pix' : 'Pagar R\$ ${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPixPayment() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2, size: 60, color: Color(0xFF003366)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Código Pix Copia e Cola', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '00020126580014br.gov.bcb.pix0136e3558b...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copiar código Pix',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código Pix copiado!'), duration: Duration(seconds: 1)),
                  );
                },
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Clique no botão abaixo para simular a liquidação imediata do Pix.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCardPayment() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _cardController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número do Cartão',
              hintText: '4532 1122 3344 5566',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: (v) => (v == null || v.length < 16) ? 'Número inválido' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Impresso no Cartão',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  hintText: 'MM/AA',
                  decoration: const InputDecoration(labelText: 'Validade'),
                  validator: (v) => (v == null || !v.contains('/')) ? 'Inválido' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  validator: (v) => (v == null || v.length < 3) ? 'Inválido' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
