# Requisitos do Sistema: AquaSertão - Piscicultura Inteligente

## Contexto
O sistema **AquaSertão: Piscicultura Inteligente** é uma aplicação focada na gestão inteligente para piscicultura. O objetivo é auxiliar as fazendas produtoras a terem controle total da produção, organizando os dados de forma que fiquem sempre à mão para decisões mais assertivas.
**Modelo de Negócio (SaaS):** A aplicação será comercializada no modelo *Software as a Service* (SaaS) B2B/B2C, operando sob uma arquitetura Multi-Tenant. O cliente do SaaS (Dono da Fazenda) gerencia sua própria operação de forma isolada no seu Tenant, enquanto o dono da plataforma (Admin SaaS) gerencia o negócio SaaS de forma global.

---

## Arquitetura Tecnológica e Integrações

### 1. Stack Base (Mobile-First)
- **App Primário:** Desenvolvimento focado em um aplicativo nativo para **Android**.
- **Arquitetura Orientada a Serviços (API-First):** O back-end será construído em cima de uma API Restful ou GraphQL. Isso garante que as mesmas regras de negócio possam ser consumidas no futuro por outros aplicativos (iOS, Plataformas Web, etc) sem reescrever o código do servidor.

### 2. Integração com IoT (Internet das Coisas)
- **Visão de Futuro (Fase 2):** A API estará preparada para receber dados brutos ("raw data") advindos de hardware de IoT (sensores físicos instalados diretamente nos tanques), automatizando as coletas de temperatura e qualidade da água.

---

## Requisitos Funcionais (Módulo do Inquilino / Fazenda)

### 3. Gestão de Tanques e Produção (Acesso: Dono e Funcionário)
- O sistema deve listar os tanques, permitindo filtrar por status.
- O sistema deve exibir indicadores: Biomassa atual, Quantidade de peixes, Peso médio, Taxa de sobrevivência.
- O sistema deve permitir o cadastro de novos tanques e histórico de povoamento.

### 4. Gestão de Estoque, Alimentação e Qualidade da Água (Acesso: Dono e Funcionário)
- **Funcionários** têm total permissão para registrar a alimentação e lançar/consumir itens do Estoque.
- **Funcionários** devem registrar medições de água (Temperatura, pH, Oxigênio, Amônia, Nitrito) diariamente.

### 5. Gestão de Manutenção e Tarefas (Acesso: Apenas Dono da Fazenda)
- O **Dono da Fazenda** deve poder registrar e agendar manutenções preventivas ou corretivas em equipamentos (aeradores, redes, bombas), de forma blindada para os funcionários.

### 6. Fluxos de Aprovação (Workflows de Permissão)
- Certas ações sensíveis inseridas pelo funcionário não sobem diretamente para o banco definitivo.
- O sistema deve criar um **"Pedido de Aprovação"** (ex: o funcionário dá baixa numa quantidade altíssima de ração suspeita), aguardando que o Dono da Fazenda aprove a ação antes dela ter efeito sistêmico.

### 7. Gestão Financeira (Acesso: Apenas Dono da Fazenda)
- **Restrição:** Funcionários não podem acessar o módulo financeiro (Pagamentos, Receitas, Lucros).
- O sistema deve calcular Receitas e Despesas categorizadas.

### 8. Central de Notificações (Push)
- O sistema deve disparar notificações PUSH para o App Android contendo alertas urgentes (ex: *Amoníaco do Tanque 3 em nível crítico*).
- Notificações de sistema (vencimento da fatura do SaaS, novas atualizações).

---

## Requisitos Funcionais (Módulo Backoffice e Nível Nacional)

### 9. Módulo Nacional de Fornecedores (Marketplace B2B)
- A base de Fornecedores não pertencerá isoladamente a uma fazenda.
- Haverá um catálogo de fornecedores a nível **Nacional**, onde fazendeiros de todo o país podem consultar fornecedores de ração e alevinos homologados na plataforma, expandindo o AquaSertão para um ecossistema B2B.

### 10. Gestão Global do SaaS (Admin SaaS)
- **Dashboard SaaS:** Painel para o Admin SaaS ver métricas do negócio (MRR, Churn).
- **Gestão de Inquilinos:** Bloquear ou suspender contas.
- **Gestão de Planos:** Configurar valores e limites dos planos.

---

## Requisitos Não Funcionais
- **Arquitetura Multi-Tenant:** Isolamento rigoroso de dados por Fazenda.
- **Integração de Pagamentos:** Gateway de pagamentos para assinaturas.
- **Logs de Auditoria (Audit Trail):** Rastreabilidade de ações críticas (quem excluiu, quem modificou).

---

## Regras de Negócio e Planos de Assinatura (Monetização)
1. **Plano Gratuito:** Até 5 tanques, recursos básicos.
2. **Plano Básico (R$ 29,90/mês):** Até 20 tanques, relatórios avançados.
3. **Plano Profissional (R$ 59,90/mês):** Tanques ilimitados, alertas inteligentes.
4. **Plano Empresarial (R$ 99,90/mês):** Multiusuários, controle de permissões avançado (RBAC) e Fluxos de Aprovação.
