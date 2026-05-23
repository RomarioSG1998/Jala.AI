# Requisitos do Sistema: AquaGestor

## Contexto
O sistema **AquaGestor** é uma aplicação focada na gestão inteligente para piscicultura. O objetivo é auxiliar as fazendas produtoras a terem controle total da produção, organizando os dados de forma que fiquem sempre à mão para decisões mais assertivas.
**Modelo de Negócio (SaaS):** A aplicação será comercializada no modelo *Software as a Service* (SaaS) B2B/B2C, operando sob uma arquitetura Multi-Tenant. O cliente do SaaS (Dono da Fazenda) gerencia sua própria operação de forma isolada no seu Tenant, enquanto o dono da plataforma (Admin SaaS) gerencia o negócio SaaS de forma global.

---

## Requisitos Funcionais (Módulo do Inquilino / Fazenda)

### 1. Gestão de Tanques e Produção
- O sistema deve listar os tanques, permitindo filtrar por status.
- O sistema deve exibir indicadores: Biomassa atual (vs meta), Quantidade de peixes, Peso médio, Taxa de sobrevivência e Conversão alimentar.
- O sistema deve permitir o cadastro de novos tanques (Espécie, Capacidade, Volume m³, Tipo, Data de povoamento).

### 2. Gestão de Alimentação e Qualidade da Água
- O sistema deve registrar a alimentação (Data, Horário, Qtd kg, Tipo de ração).
- O sistema deve registrar medições de água (Temperatura, pH, Oxigênio, Amônia, Nitrito) e alertar caso fujam dos limites ideais.

### 3. Dashboard e Relatórios (Cliente)
- O sistema deve exibir um dashboard com o resumo da produção do Tenant atual.
- O sistema deve gerar gráficos de crescimento de biomassa e relatórios de eficiência.

### 4. Gestão Financeira e Administrativa
- O sistema deve calcular Receitas, Despesas categorizadas (Ração, Alevinos, Energia) e Lucro estimado da Fazenda.
- O sistema deve permitir gerenciar os dados da Fazenda, Estoque, Fornecedores e Manutenção (equipamentos e tarefas).

### 5. Gestão de Vínculos e Permissões (RBAC do Inquilino)
- O sistema (nos planos maiores) deve permitir ao Dono da Fazenda convidar contas de Usuários Globais para seu Tenant.
- O Dono da Fazenda deve poder definir o papel de acesso do funcionário (ex: Visualizador, Operador de Campo, Gerente Financeiro).

---

## Requisitos Funcionais (Módulo Backoffice SaaS - Dono do Software)

### 6. Gestão Global do SaaS (Admin SaaS)
- **Dashboard SaaS:** O sistema deve prover um painel para o Admin SaaS ver métricas do negócio: MRR (Receita Mensal Recorrente), Churn (cancelamentos), novos usuários e total de Tenants (Fazendas) ativos.
- **Gestão de Inquilinos:** O Admin SaaS deve poder visualizar, bloquear ou suspender contas de clientes que violem termos de uso ou por inadimplência.
- **Gestão de Planos e Cobrança:** O Admin SaaS deve poder configurar os planos (valores e limites) e acompanhar faturas e status de integração com o gateway de pagamento.
- **Suporte e Atendimento:** O backoffice deve permitir que a equipe do SaaS visualize dados básicos do cliente para prestar suporte (sem ferir a privacidade dos dados operacionais da Fazenda).

---

## Requisitos Não Funcionais
- **Arquitetura Multi-Tenant:** Os dados de cada `TENANT_FAZENDA` devem ser logicamente isolados para garantir privacidade absoluta.
- **Integração de Pagamentos:** O sistema deve integrar-se a um Gateway de Pagamentos para gerenciar o faturamento recorrente (assinaturas automáticas, PIX/Boleto, inadimplência).
- **Onboarding Self-Service:** O usuário final deve ser capaz de criar uma `USUARIO_GLOBAL`, criar seu `TENANT_FAZENDA`, escolher o plano e pagar de forma 100% autônoma.
- **Logs de Auditoria (Audit Trail):** O sistema deve registrar ações críticas garantindo rastreabilidade.

---

## Regras de Negócio e Planos de Assinatura (Monetização)

O modelo de negócio adota o formato *Freemium* e *Subscription*:

1. **Plano Gratuito:** Até 5 tanques, recursos básicos.
2. **Plano Básico (R$ 29,90/mês):** Até 20 tanques, relatórios avançados.
3. **Plano Profissional (R$ 59,90/mês):** Tanques ilimitados, alertas inteligentes.
4. **Plano Empresarial (R$ 99,90/mês):** Multiusuários, controle de permissões avançado (RBAC).

**Outras Fontes de Receita Previstas:**
- **Marketplace e Parcerias:** Comissão sobre venda de insumos.
- **Publicidade e Insights:** Venda de dados agregados anônimos para a indústria do setor.
