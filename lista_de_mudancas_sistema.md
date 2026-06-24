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

Novas demandas do clientes: 📋 Observações e Ajustes do Cliente (App de Aquicultura)
🔴 Alta Prioridade (Bugs e Correções Críticas)

[ ] Corrigir opções de pagamento: Na aba de anúncios (atual Mercado Local), a tela está travada ao clicar no anúncio e não exibe as opções de Pix e Cartão.

[ ] Corrigir bug de duplicação nos Relatórios (Tanque 1): O "Tanque 1" está aparecendo duplicado no relatório após a atualização do nome. O app mostra o mesmo horário de registro (ex: 17:26), mas com níveis de pH diferentes (7.2 e 7.1).

[ ] Corrigir conflito de exibição de Estoque/Povoamento (Tanque 2): Ao editar a "quantidade de povoamento" para 1.000 (em um tanque que já exibe, por exemplo, "Tilápia 1992 peixes" / "Estoque 1992"), o valor preenchido acaba aparecendo duplicado nos campos de capacidade e quantidade.

🟡 Média Prioridade (Novas Funcionalidades e Ajustes na Interface)

[ ] Ajuste nos Campos de Registro do Tanque:

Remover totalmente o campo "Capacidade" (o valor genérico de quanto o tanque suporta está confundindo os usuários com o total efetivamente povoado).

Mover o campo "Quantidade de Povoamento" lá para cima (logo abaixo do nome do tanque e da espécie).

Remover o termo "opcional" da "Quantidade de Povoamento", pois este registro precisa ser obrigatório.

Manter os demais campos como estão: Peso Médio (biometria), Mortalidade, Data do povoamento e Fornecedor (este continua sendo opcional).

[ ] Renomear e estruturar aba de fornecimento: Alterar o nome da aba de "Mercado Local" para "Fornecedor Local".

[ ] Filtro de Localização de Fornecedores: Adicionar uma estrutura de busca/filtro por Estado e Município. A ideia é garantir que um usuário (ex: de São Paulo) possa filtrar e ver apenas os anúncios de sua cidade/estado, sem ter que visualizar a lista geral do país todo misturada.

[ ] Filtros de Lucro/Perda: Na tela de registros (onde ficam todas as despesas e vendas no Lucro líquido / Lucro estimado), adicionar botões para que o usuário filtre os resultados. Ele deve poder identificar qual semana, mês ou ano gerou mais lucro através das opções: Semanal, Mensal e Anual.

[ ] Seleção de Espécie e Quantidade (Calculadora): Adicionar no topo da tela de parâmetros um local para selecionar a espécie (ex: Tilápia, Pacu, Tambaqui) e informar a quantidade de peixes, já que a alimentação varia de acordo com cada espécie.

[ ] Lógica da Calculadora de Ração: Implementar a lógica de cálculo usando o aplicativo "calculadora em APK" do próprio cliente como modelo e guia do que precisa ser feito.

[ ] Parâmetros da Recomendação de Trato: A área de resultados deve estar organizada exibindo:

Quantidade de ração fornecida.

Quantidade de trato por dia.

Quantidade de ração por trato.

Nível de proteína.

Tamanho da ração.

[ ] Regras de Temperatura no Racionamento: O racionamento deve ser obrigatoriamente atrelado à temperatura da água:

Até 31ºC ou 32ºC: Recomendação normal de alimentação.

A partir de 33ºC: O aplicativo deve emitir um alerta recomendando não alimentar os peixes.

[ ] Fluxo de Simulação de Crescimento: O sistema precisa rodar "redondinho" para permitir testes de evolução do peixe, começando da fase de alevino pequeno, aumentando as gramas, até chegar ao peso de abate (1 kg a 1,5 kg).

🟢 Baixa Prioridade / Ideias Futuras

[ ] Melhoria Visual para a Play Store: Antes de lançar o aplicativo oficialmente, trabalhar a identidade visual externa. Criar fotos mais elaboradas, chamativas e cheias de cores para atrair a atenção do usuário na loja de aplicativos.