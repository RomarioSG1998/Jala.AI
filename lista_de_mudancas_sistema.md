# 📋 AquaGestor — Status do Sistema

> Última atualização: Junho/2026
> Legenda: ✅ Concluído | 🔄 Em andamento | 📌 Pendente

---

## ✅ FEITO

### 🔐 Autenticação e Usuários
- [x] Login e Registro via JWT + Spring Boot
- [x] Tokens persistidos com `flutter_secure_storage`
- [x] Logout automático ao detectar token expirado (401/403)
- [x] Perfil de usuário: foto + dados persistidos via API
- [x] Roles de acesso: FARM_OWNER, FIELD_OPERATOR, CLIENT, SAAS_ADMIN
- [x] Permissões por módulo por funcionário

### 🐠 Tanques
- [x] CRUD completo de tanques via API REST
- [x] Campo de seleção de espécie (Tilápia, Pacu, Tambaqui, Pirarucu, Pintado)
- [x] Quantidade de Povoamento como campo obrigatório (fonte única de verdade)
- [x] Campo Capacidade removido (eliminado conflito com Quantidade)
- [x] Peso médio (biometria), Mortalidade, Data do Povoamento e Fornecedor
- [x] Opções de Cancelar/Fechar no formulário de cadastro
- [x] Correção: bug de duplicação do Tanque 1 nos relatórios
- [x] Correção: conflito Estoque × Quantidade ao editar povoamento

### 💧 Qualidade da Água
- [x] Registro de parâmetros: pH, Amônia, Nitrito, Alcalinidade, Dureza, Sólidos
- [x] Histórico salvo no PostgreSQL

### 🍽️ Alimentação
- [x] CRUD de tratos com datas e horários reais
- [x] Quantidade de ração por dia, tipo, horários e custo

### 📉 Mortalidade
- [x] Registro diário com causa provável e taxa por lote

### 📏 Biometria
- [x] Histórico com datas, peso médio e conversão alimentar
- [x] Calendário para data de entrada dos alevinos e data de despesca (opcional)
- [x] Opções de Cancelar/Fechar no formulário

### 🌾 Colheita / Despesca
- [x] Registros salvos via API com quantidade (kg) e destino

### 📦 Estoque / Inventário
- [x] CRUD de insumos e equipamentos (incluindo Tarrafa, Soprador, Aerador)
- [x] Campo de potência para Aeradores

### 💰 Financeiro
- [x] Receitas e Despesas com categorias específicas de piscicultura
- [x] Categorias de receita: Venda de Alevino, Venda de Tilápia, etc.
- [x] Categorias de despesa: Ração, Medicamentos, Mão de Obra, Combustível, etc.
- [x] Campo de nome do comprador (livre ou lista suspensa)
- [x] Campos: espécie, quantidade (kg) e valor por venda
- [x] Lista de espécies do Brasil disponível para seleção
- [x] Data exata gravada em cada transação
- [x] Filtros temporais com chips animados:
  - [x] Semanal — últimos 7 dias
  - [x] Mensal — mês corrente
  - [x] Anual — ano corrente
- [x] Saldo e totais calculados por período

### 📊 Relatórios
- [x] Endpoints de agregação no Spring Boot (`/api/reports/*`)
- [x] Gráficos reais com `fl_chart`: Crescimento, Mortalidade, Consumo, Despesca
- [x] Correção: dados duplicados eliminados

### 🔔 Alertas e Notificações
- [x] `flutter_local_notifications` integrado
- [x] Notificação diária de alimentação (arraçoamento)
- [x] Lembrete quinzenal de biometria
- [x] Alerta de renovação de água (a cada 7 dias)
- [x] Alerta de proximidade de despesca (7 dias antes)
- [x] Inicialização automática no boot do app

### 🏪 Marketplace (Fornecedor Local)
- [x] Endpoint `/api/announcements` no backend (CRUD completo, isolado por farmId)
- [x] Publicação real de anúncios via API (sem dados hardcoded)
- [x] Filtro por categoria: Alevinos, Ração, Equipamentos
- [x] Filtro por Estado (UF) e Município em tempo real
- [x] Busca por produto ou vendedor
- [x] Modal de detalhes com opções de Pix (chave copiável) e Cartão
- [x] Aba renomeada de "Mercado Local" para "Fornecedor Local"

### 🧮 Calculadora Zootécnica
- [x] Seleção de espécie e quantidade de peixes
- [x] Cálculo de biomassa total
- [x] Recomendação de trato: quantidade de ração, tratos/dia, ração/trato
- [x] Nível de proteína e granulometria por espécie e faixa de peso
- [x] Regra de temperatura:
  - [x] ≤ 32°C → alimentação normal
  - [x] ≥ 33°C → alerta de suspensão do arraçoamento
- [x] Simulação de crescimento do ciclo completo (alevino → abate)
- [x] Persistência do histórico no banco via `POST /api/calculator/history`

### 💳 Monetização SaaS
- [x] Plano gratuito: até 1 tanque (guard ativo no `TankService`)
- [x] HTTP 402 lançado ao atingir o limite de plano
- [x] Flutter redireciona automaticamente para `UpgradePlanScreen`
- [x] Tela de upgrade com comparativo Gratuito vs Pro (R$ 19,90/mês)
- [x] Plano Pro: tanques ilimitados, relatórios, alertas, marketplace

### 🌦️ Clima
- [x] Previsão do 5 dias com API Open-Meteo
- [x] Geolocalização real do dispositivo (GPS + fallback por IP)
- [x] Banner do dashboard como atalho para a tela de previsão

### 📚 Biblioteca
- [x] Artigos: Manejo da Tilápia, Qualidade da Água, Doenças Comuns
- [x] Cursos e E-books com fluxo de checkout simulado (Pix / Cartão)

### 🎨 Play Store / Visual
- [x] 5 assets criados em `play_store_assets/`:
  - [x] `feature_graphic_1024x500.png` — Banner principal
  - [x] `icon_512x512.png` — Ícone (peixe + gráfico de crescimento)
  - [x] `screenshot_01_tanques.png`
  - [x] `screenshot_02_calculadora.png`
  - [x] `screenshot_03_financas.png`

### 🗄️ Banco de Dados
- [x] Migração V12 aplicada: `marketplace_schema.announcement` e `ops_schema.calculator_history`
- [x] Flyway validando e aplicando migrações automaticamente no boot

### 🌐 Gateway de API e Integração E2E
- [x] Roteamento de todos os serviços de frontend (Calculadora, Relatórios, Marketplace) unificado via API Gateway (porta 8085)
- [x] Injeção de dependência centralizada usando o `dioProvider` para comunicação e cabeçalhos de autenticação automáticos
- [x] Persistência segura do `farm_id` no `FlutterSecureStorage` adicionada ao DTO de resposta de autenticação do backend e atualizada nos providers de auth do frontend
- [x] Correção de compatibilidade SQL no repositório de marketplace do backend, migrando filtros opcionais dinâmicos para filtragem robusta em memória Java
- [x] Bateria de testes de integração ponta a ponta (`test_integration.py`) executando e passando com sucesso (Login -> Calculadora -> Histórico -> Relatório -> Marketplace)

---

## 🔄 FAZENDO

### 🧮 Fórmulas da Calculadora de Ração
- [x] Dissecar o APK do cliente para extrair as fórmulas exatas por espécie e faixa de peso (Fórmulas exatas para Tilápia, Tambaqui, Carpa, Pacu e Pirarucu migradas com sucesso para o backend e integradas ao frontend via API REST!)
- [ ] Videoconferência com o cliente para validar as fórmulas e o fluxo da calculadora antes de finalizar

---

## 📌 A FAZER

### 💳 Gateway de Pagamento
- [ ] Integrar Mercado Pago ou EFI Bank (Pix/Cartão real) na `UpgradePlanScreen`
- [ ] Criar endpoint `POST /api/billing/webhook` para receber confirmações de pagamento
- [ ] Atualizar status da `Subscription` automaticamente via webhook

### 🖼️ Upload de Imagens no Marketplace
- [ ] Criar endpoint Multipart no Spring Boot (`StorageController`)
- [ ] Integrar `ImagePicker` no Flutter para seleção de imagem real
- [ ] Substituir `imageUrl` (string estática) por upload de binário

### 📲 Notificações Push Remotas (FCM)
- [ ] Finalizar configuração da conta de serviço no Firebase Console
- [ ] Integrar `firebase_messaging` no Flutter
- [ ] Criar endpoint no backend para enviar push via FCM

### 📝 Biblioteca via CMS
- [ ] Tornar os artigos editáveis remotamente (atualmente hardcoded no Flutter)
- [ ] Criar endpoint de conteúdo no backend ou integrar CMS externo (ex: Strapi)

### ⚙️ Sincronização de Configurações
- [ ] Sincronizar preferências de tema (dark/light) entre dispositivos via backend
- [ ] Atualmente funciona apenas localmente com `SharedPreferences`