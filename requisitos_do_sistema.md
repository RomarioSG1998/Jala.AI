# Requisitos do Sistema: AquaGestor

## Contexto
O sistema **AquaGestor** é uma aplicação focada na gestão inteligente para piscicultura. O objetivo é auxiliar os produtores a terem controle total da produção, organizando os dados de forma que fiquem sempre à mão para decisões mais assertivas, resultando em mais produtividade e menos desperdício. O aplicativo terá foco em dispositivos móveis (disponível no Google Play e App Store).

---

## Requisitos Funcionais

### 1. Gestão de Tanques
- O sistema deve listar os tanques, permitindo filtrar por "Todos", "Ativos" e "Inativos".
- O sistema deve exibir no card do tanque: Foto, Nome, Espécie (ex: Tilápia), Quantidade de peixes, Biomassa (kg) e Status.
- O sistema deve permitir o cadastro de novos tanques informando: Foto, Nome, Espécie, Capacidade (peixes), Volume (m³), Tipo de tanque, Data de povoamento e Observações.
- O sistema deve apresentar os detalhes do tanque, contendo uma "Visão Geral" com indicadores como: Biomassa atual (com gráfico indicando a meta), Quantidade de peixes, Peso médio, Taxa de sobrevivência (%) e Conversão alimentar.

### 2. Gestão de Alimentação
- O sistema deve permitir registrar a alimentação fornecida aos tanques.
- O formulário de "Nova alimentação" deve solicitar: Tanque, Data, Horário, Quantidade (kg), Tipo de ração (ex: Proteína 32%) e Observações.
- O sistema deve manter e exibir o histórico de alimentação diária, bem como totalizar a ração fornecida no dia.

### 3. Monitoramento da Qualidade da Água
- O sistema deve permitir o registro de medições dos parâmetros da água por tanque.
- O formulário de "Nova medição" deve capturar: Temperatura (ºC), pH, Oxigênio dissolvido (mg/L), Amônia - NH3 (mg/L) e Nitrito - NO2 (mg/L).
- O sistema deve exibir os valores ideais de cada parâmetro na tela de acompanhamento e destacar (com ícones/cores) se as medições estão dentro ou fora do ideal.

### 4. Dashboard e Relatórios
- O sistema deve exibir uma tela de Início (Dashboard) contendo o resumo da produção: quantidade de tanques ativos, total de peixes, biomassa total e taxa de sobrevivência geral.
- O sistema deve possuir atalhos (Ações rápidas) no dashboard: Alimentar, Qualidade da água, Adicionar registro, Relatórios.
- O sistema deve gerar relatórios de Crescimento de biomassa em formato de gráfico de linhas, com filtros de tempo (7 dias, 30 dias, 90 dias, Personalizado).
- O sistema deve calcular o resumo do período selecionado, mostrando: Biomassa inicial, Biomassa final, Ganho de biomassa e Conversão alimentar.

### 5. Gestão Financeira
- O sistema deve possuir um módulo de Finanças que exibe o balanço do mês: Receitas, Despesas e Lucro estimado.
- As despesas devem ser categorizadas e exibidas em percentual (ex: Ração, Alevinos, Mão de obra, Energia, Outros).

### 6. Configurações Adicionais e Cadastros (Menu Mais)
- O sistema deve permitir o gerenciamento de: Perfil da conta, Informações da Propriedade, Funcionários (equipe), Fornecedores, Estoque (rações e insumos), Manutenção (equipamentos e tarefas).
- O sistema deve prover Notificações e Alertas para o usuário.

---

## Requisitos Não Funcionais
- O sistema deve ser um aplicativo móvel com interface amigável (Dark Mode predominante).
- O sistema deve fornecer armazenamento na nuvem e sincronização de dados (disponível nos planos premium).
- O sistema deve ser seguro e garantir a privacidade dos dados do usuário.

---

## Regras de Negócio e Planos de Assinatura (Monetização)

O modelo de negócio adota o formato *Freemium*, limitando os recursos com base em planos de assinatura:

1. **Plano Gratuito**
   - Até 5 tanques, controle básico de produção, registro de alimentação, monitoramento de água, relatórios básicos, suporte básico.
2. **Plano Básico (R$ 29,90/mês)**
   - Até 20 tanques, relatórios avançados, histórico expandido, exportação de dados, suporte prioritário.
3. **Plano Profissional (R$ 59,90/mês)**
   - Tanques ilimitados, dashboard avançado, análises e recomendações, alertas inteligentes, backup e sincronização, suporte premium.
4. **Plano Empresarial (R$ 99,90/mês)**
   - Gestão para empresas, multiusuários e permissões, múltiplas unidades, integração via API, relatórios personalizados, consultoria, suporte dedicado.

**Outras Fontes de Receita Previstas:**
- **Marketplace e Parcerias:** Venda de insumos/equipamentos com comissão.
- **Serviços Adicionais:** Contratação avulsa de consultoria técnica, análise laboratorial, projeto de expansão e treinamentos.
- **Publicidade e Insights:** Publicidade segmentada e relatórios com dados agregados/anônimos para a indústria.

---

## Glossário
- **Biomassa:** Peso total dos peixes vivos dentro de um tanque.
- **Conversão Alimentar:** Índice de eficiência que mede quantos quilos de ração foram necessários para o peixe ganhar 1kg de peso.
- **Alevinos:** Filhotes de peixes recém-saídos do ovo ou da fase larval, usados para o povoamento do tanque.
- **Povoamento:** Ato de introduzir os alevinos ou peixes jovens em um tanque para início do cultivo.
