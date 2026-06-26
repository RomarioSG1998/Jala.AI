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
| **Banner de anúncio** ("AgroShop Nordeste — cupom AQUA15") | É um widget decorativo fixo. Não há integração com parceiros/loja real. |
| **Checkout / Pagamento** (Cursos e E-books na Biblioteca) | O fluxo de checkout (Pix / Cartão) é uma **simulação**. O `_processPayment` usa um `Future.delayed` de 2s para fingir aprovação — sem gateway de pagamento real. O código Pix é um placeholder fixo. |

---

### ⚠️ Parcialmente Funcionais

| Funcionalidade | Observação |
|---|---|
| **Biblioteca** (Artigos e Manuais) | O conteúdo dos artigos (Manejo da Tilápia, Qualidade da Água, Doenças) está hardcoded no Flutter — funciona bem como referência, mas não é editável remotamente via CMS. |
| **Configurações / Tema dark-light** | Funciona localmente com `SharedPreferences`, mas preferências não sincronizam entre dispositivos. |

---

### 🚀 Novas Funcionalidades Conectadas ao Backend (Production-Ready)

| Funcionalidade | O que foi feito |
|---|---|
| **Relatórios Reais** | Endpoints de agregação implementados no Spring Boot e conectados ao frontend com gráficos reais gerados pelo `fl_chart` (Crescimento, Mortalidade, Consumo e Previsão de Despesca). |
| **Marketplace Persistente** | Endpoint `/announcements` no backend com CRUD completo e isolamento por farmId. Frontend atualizado com busca, publicação real de anúncios e filtros de Estado e Município. |
| **Bloqueio de Plano Gratuito** | Implementado guard no `TankService` que limita a criação de apenas 1 tanque para usuários do plano gratuito, lançando HTTP 402, tratado no Flutter com redirecionamento para a tela `UpgradePlanScreen`. |
| **Alertas e Notificações** | Integrado `flutter_local_notifications` com agendamento local automático para manejo diário de ração (alimentação), biometria quinzenal, qualidade da água e proximidade de despesca. |
| **Calculadora com Histórico** | Lógica de cálculo estendida para registrar e persistir os resultados no banco de dados via `/api/calculator/history` sempre que uma recomendação é computada. |

---

## 📋 Novas Demandas do Cliente — Observações e Ajustes (App de Aquicultura)

> **Como usar:** marque `[x]` quando a tarefa estiver concluída. Use os sub-itens para rastrear detalhes de cada demanda.

---

### 🔴 Alta Prioridade — Bugs e Correções Críticas

- [x] **Corrigir opções de pagamento** _(Aba de Anúncios / Mercado Local)_
  - ~~A tela trava ao clicar no anúncio~~ — adicionado `onTap` com modal de detalhes
  - ~~Não exibe as opções de **Pix** e **Cartão**~~ — modal com Pix (chave copiável) e Cartão implementados

- [x] **Corrigir bug de duplicação nos Relatórios** _(Tanque 1)_
  - ~~O "Tanque 1" aparece duplicado no relatório após atualização do nome~~ — corrigido: fishCapacity agora sincronizado com initialStockingQty
  - Conflito de campos eliminado (Capacidade removida como campo separado)

- [x] **Corrigir conflito Estoque × Povoamento** _(Tanque 2)_
  - ~~Ao editar "Quantidade de Povoamento" para 1.000, o valor aparece duplicado~~ — corrigido
  - ~~Conflito entre campos de **Capacidade** e **Quantidade**~~ — campo Capacidade removido; Qtd. Povoamento é agora a única fonte de verdade

---

### 🟡 Média Prioridade — Novas Funcionalidades e Ajustes de Interface

- [x] **Ajuste nos Campos de Registro do Tanque**
  - ~~Remover totalmente o campo **"Capacidade"**~~ — removido ✅
  - ~~Mover **"Quantidade de Povoamento"** para logo abaixo do Nome do Tanque e da Espécie~~ — reposicionado ✅
  - ~~Remover o rótulo **"opcional"** da Quantidade de Povoamento → campo deve ser **obrigatório**~~ — tornado obrigatório com validação ✅
  - Manter os demais campos: Peso Médio (biometria), Mortalidade, Data do Povoamento e Fornecedor _(Fornecedor continua opcional)_ ✅

- [x] **Renomear aba de fornecimento**
  - ~~Alterar **"Mercado Local"** → **"Fornecedor Local"**~~ — renomeado no AppBar ✅

- [x] **Filtro de Localização de Fornecedores**
  - ~~Adicionar busca/filtro por **Estado** e **Município**~~ — dropdown de UF + cidade implementados ✅
  - ~~Usuário de SP deve ver apenas anúncios de sua cidade/estado~~ — filtragem em tempo real aplicada ✅

- [x] **Filtros de Lucro/Perda** _(Tela de Registros Financeiros)_
  - ~~Adicionar botões de filtro temporal:~~ — implementado com chips animados ✅
    - [x] **Semanal** — últimos 7 dias ✅
    - [x] **Mensal** — mês corrente ✅
    - [x] **Anual** — ano corrente ✅
  - ~~Objetivo: identificar qual período gerou mais lucro~~ — saldo e totais calculados por período ✅

- [x] **Seleção de Espécie e Quantidade na Calculadora**
  - ~~Adicionar no topo da tela de parâmetros:~~ — implementado ✅
    - [x] Campo de seleção de **espécie** (Tilápia, Pacu, Tambaqui, Pirarucu, Pintado) ✅
    - [x] Campo para **quantidade de peixes** ✅
  - ~~A alimentação varia por espécie — esses dados são essenciais para o cálculo~~ ✅

- [ ] **Lógica da Calculadora de Ração**
  - [ ] Implementar usando o APK do cliente como modelo e referência — fórmulas por espécie e faixa de peso (ainda não dissecamos a fundo o apk do cliente)
  - [ ] Validar fórmulas e fluxo com o cliente antes de finalizar (faremos isso em vídeo chamada)

- [x] **Parâmetros exibidos na Recomendação de Trato** _(área de resultados)_
  - [x] Quantidade de ração fornecida ✅
  - [x] Quantidade de tratos por dia ✅
  - [x] Quantidade de ração por trato ✅
  - [x] Nível de proteína ✅
  - [x] Tamanho da ração (granulometria) ✅

- [x] **Regras de Temperatura no Racionamento**
  - [x] **≤ 31°C / 32°C** → Recomendação normal de alimentação ✅
  - [x] **≥ 33°C** → Exibir alerta: _"Não recomendado alimentar os peixes nesta temperatura"_ ✅

- [x] **Fluxo de Simulação de Crescimento**
  - ~~O sistema deve simular a evolução completa do peixe:~~ — implementado ✅
    - Início: fase de **alevino pequeno** ✅
    - Evolução: aumento gradual de gramas (juvenil → crescimento → terminação) ✅
    - Fim: peso de **abate** por espécie ✅
  - ~~Deve rodar sem erros para validar o ciclo completo de produção~~ ✅

---

### 🟢 Baixa Prioridade — Ideias Futuras

- [x] **Melhoria Visual para a Play Store**
  - ~~Criar prints e artes mais elaboradas, chamativas e coloridas~~ — 5 assets em `play_store_assets/` ✅
  - `feature_graphic_1024x500.png` — Banner principal da loja ✅
  - `icon_512x512.png` — Ícone (peixe estilizado + gráfico de crescimento) ✅
  - `screenshot_01_tanques.png` — Tela de Tanques com mockup realista ✅
  - `screenshot_02_calculadora.png` — Calculadora com resultados e simulação ✅
  - `screenshot_03_financas.png` — Finanças com filtros e saldo em destaque ✅
  - ~~Objetivo: aumentar conversão na página da loja antes do lançamento oficial~~ ✅