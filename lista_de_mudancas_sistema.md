# 📋 Lista de Tarefas: Atualizações do App/Sistema de Piscicultura

## 💰 Receitas e Despesas
- [x] **Aba de Receitas**: Alterar a nomenclatura para "Receita / Entrada".
- [x] **Categorias de Receita**: Incluir opções específicas do segmento, como "Venda de Alevino", "Venda de Tilápia", etc.
- [x] **Registro de Clientes**: Criar um campo aberto para digitar o nome do comprador ou permitir a escolha em uma lista suspensa.
- [x] **Detalhes da Venda**: Inserir campos para registrar a espécie do peixe, a quantidade vendida (em kg) e o valor.
- [x] **Lista de Espécies**: Disponibilizar uma lista pronta com as espécies de peixes do Brasil para seleção (mantendo a opção do produtor digitar manualmente).
- [x] **Categorias de Despesa**: Padronizar opções focadas na piscicultura (ex: Compra de Alevinos, Medicamentos, Trabalhador, Combustível, Outros).
- [x] **Registro de Datas**: Garantir que o sistema grave a data exata de cada transação (receita ou despesa).

## 🐟 Biometria e Povoamento
- [x] **Nomenclatura de Peso**: Adicionar o termo "Biometria" junto ao campo de "Peso Médio" (com a unidade em gramas).
- [x] **Data de Povoamento**: Criar um calendário/campo para registrar a data de entrada dos alevinos no tanque.
- [x] **Data da Despesca**: Criar um calendário/campo marcado como opcional para a despesca, pois a retirada pode acontecer em etapas.
- [x] **Histórico de Biometria**: Estruturar a aba para receber atualizações periódicas de peso (ex: a cada 8, 15 ou 30 dias), acompanhando o desenvolvimento da biomassa para cálculo de ração.

## 💧 Qualidade da Água
- [x] **Atualização de Nomenclatura**: Remover o item isolado "Teste de pH" e substituir por "Kit de análise de qualidade de água".
- [x] **Parâmetros de Análise**: Dentro do kit, incluir os campos de registro para:
  - [x] pH
  - [x] Amônia
  - [x] Nitrito
  - [x] Alcalinidade
  - [x] Dureza total
  - [x] Sólidos

## ⚙️ Equipamentos
- [x] **Cadastro de Itens**: Adicionar novos itens de infraestrutura no sistema:
  - [x] Tarrafa
  - [x] Soprador
  - [x] Aerador
- [x] **Especificação de Potência**: Ao selecionar "Aerador", abrir um campo opcional para o usuário registrar a potência do equipamento (ex: 0.5 cavalo, 1 cavalo, 2 cavalos).

## 🛠️ Funcionalidades Principais (A revisar/implementar)
- [x] **Cadastro dos tanques**
  - [x] **Opção de Fechar/Cancelar**: O formulário de cadastro de tanques deve conter opções claras de Cancelar ou Fechar.
- [x] **Cadastro de biometrias**
  - [x] **Opção de Fechar/Cancelar**: O formulário de biometria deve conter opções claras de Cancelar ou Fechar.
- [x] **Controle de povoamento**
  - [x] Data de entrada dos alevinos
  - [x] Quantidade
  - [x] Peso médio inicial
  - [x] Fornecedor
- [x] **Controle de alimentação**
  - [x] Quantidade de ração por dia
  - [x] Tipo de ração
  - [x] Horários de arraçoamento
  - [x] Custo da ração
- [x] **Controle de mortalidade**
  - [x] Registro diário de mortes
  - [x] Causa provável
  - [x] Taxa de mortalidade por lote
- [x] **Controle de biometria**
  - [x] Peso médio dos peixes
  - [x] Crescimento semanal
  - [x] Conversão alimentar
- [x] **Controle financeiro**
  - [x] Gastos com ração
  - [x] Energia
  - [x] Mão de obra
  - [x] Medicamentos
  - [x] Lucro estimado
- [x] **Relatórios**
  - [x] Crescimento dos peixes
  - [x] Mortalidade
  - [x] Consumo de ração
  - [x] Previsão de despesca
- [x] **Alertas**
  - [x] Hora de alimentar
  - [x] Fazer biometria
  - [x] Renovação de água
  - [x] Despesca prevista

## 🚀 Diferenciais para se destacar
- [x] **Calculadora automática**
  - [x] Entrada do produtor:
    - [x] Quantidade de peixes
    - [x] Peso médio
  - [x] Cálculo do app:
    - [x] Quantidade diária de ração
    - [x] Biomassa total
    - [x] Previsão de abate
- [x] **Clima**
  - [x] Mostrar previsão do tempo para a região do produtor.
- [x] **Mercado local**
  - [x] Área para compra e venda de:
    - [x] Alevinos
    - [x] Ração
    - [x] Equipamentos
- [x] **Biblioteca**
  - [x] Manejo da tilápia
  - [x] Qualidade da água
  - [x] Doenças comuns

## 💵 Monetização (Como ganhar dinheiro com o app)
- [x] Plano gratuito (até 1 tanque)
- [x] Plano Pro R$ 19,90/mês
- [x] Anúncios de lojas agropecuárias
- [x] Venda de cursos e e-books

## 📱 Tela Inicial do App
- [x] Dashboard
- [x] Tanques
- [x] Alimentação
- [x] Mortalidade
- [x] Financeiro
- [x] Relatórios
- [x] Dashboard
- [x] Tanques
- [x] Alimentação
- [x] Mortalidade
- [x] Financeiro
- [x] Relatórios
- [x] Marketplace
- [x] Config

---

## 🔍 Análise: Funcional vs. Visual/Simulado

> Legenda: ✅ **Funcional** (integrado ao backend/API real) | 🎭 **Visual** (UI pronta, dados simulados ou sem persistência) | ⚠️ **Parcial** (funciona localmente, mas sem backend integrado)

### ✅ Totalmente Funcionais (Backend Integrado)

| Funcionalidade | Observação |
|---|---|
| Autenticação (Login/Registro) | JWT + Spring Boot, tokens persistidos |
| Cadastro e listagem de tanques | CRUD completo via API REST |
| Controle de qualidade da água | Registros salvos no PostgreSQL |
| Controle de alimentação (tratos) | CRUD com datas e horários reais |
| Controle de mortalidade | Registros com causa e taxa por lote |
| Controle de biometria | Histórico com datas e conversão alimentar |
| Controle de colheitas/despesca | Registros salvos via API |
| Controle de estoque/inventário | CRUD de insumos e equipamentos |
| Controle financeiro (receitas/despesas) | Registros com categorias específicas de piscicultura |
| Fornecedores/Suppliers | Serviço dedicado (supplier-service) |
| Funcionários | Listagem com permissões por role |
| Perfil de usuário | Foto + dados persistidos |
| Previsão do tempo (5 dias) | API Open-Meteo + GPS real do dispositivo |
| Planos SaaS / Admin Panel | Lógica de roles: FARM_OWNER, FIELD_OPERATOR, CLIENT, SAAS_ADMIN |

---

### 🎭 Visual / Simulado (Sem Backend Real)

| Funcionalidade | O que falta |
|---|---|
| **Relatórios** (crescimento, mortalidade, consumo, despesca) | A tela existe com cards bonitos, mas o `onTap` mostra apenas um SnackBar `"em breve!"`. Nenhum dado real é calculado/exibido. Precisa: criar endpoint de agregação no backend e gráficos reais. |
| **Alertas** (alimentar, biometria, renovação, despesca) | Não existe `flutter_local_notifications` nem `firebase_messaging` no projeto. Os alertas não são disparados. Precisa: implementar notificações agendadas. |
| **Marketplace** (Mercado Local) | Os dados são uma lista estática em memória (hardcoded). O botão "Anunciar" adiciona itens apenas localmente (perdidos ao fechar o app). Precisa: endpoint de anúncios no backend + imagens reais. |
| **Banner de anúncio** ("AgroShop Nordeste — cupom AQUA15") | É um widget decorativo fixo. Não há integração com parceiros/loja real. |
| **Checkout / Pagamento** (Cursos e E-books na Biblioteca) | O fluxo de checkout (Pix / Cartão) é uma **simulação**. O `_processPayment` usa um `Future.delayed` de 2s para fingir aprovação — sem gateway de pagamento real. O código Pix é um placeholder fixo. |
| **Plano gratuito / Pro (Monetização)** | A lógica de planos SaaS existe no painel admin, mas não há bloqueio real de funcionalidades para usuários do plano gratuito nem cobrança automatizada. |

---

### ⚠️ Parcialmente Funcionais

| Funcionalidade | Observação |
|---|---|
| **Biblioteca** (Artigos e Manuais) | O conteúdo dos artigos (Manejo da Tilápia, Qualidade da Água, Doenças) está hardcoded no Flutter — funciona bem como referência, mas não é editável remotamente via CMS. |
| **Calculadora automática** | Funciona com lógica local (sem API). Cálculos corretos, mas não salva os resultados no banco. |
| **Configurações / Tema dark-light** | Funciona localmente com `SharedPreferences`, mas preferências não sincronizam entre dispositivos. |