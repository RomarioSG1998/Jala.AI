# Diagrama de Casos de Uso

Abaixo está a representação dos principais casos de uso do sistema AquaSertão (Piscicultura Inteligente), refletindo as restrições de permissões entre o Dono da Fazenda e o Funcionário, além dos módulos globais.

```mermaid
flowchart LR
    %% Atores
    AdminSaaS(("Admin do SaaS\n(Dono do Software)"))
    DonoFazenda(("Dono da Fazenda\n(Admin do Tenant)"))
    Funcionario(("Funcionário\n(Operação de Campo)"))
    Sistema(("Sistema AquaSertão\n(Notificações/IoT)"))

    %% Backoffice SaaS (Visão do dono do negócio)
    subgraph BackofficeSaaS ["Backoffice SaaS (Administração Global)"]
        direction TB
        UC_DashSaaS([Dashboard SaaS - MRR])
        UC_GerenciarClientes([Gerenciar Contas e Tenants])
        UC_FornecedoresGlobais([Homologar Fornecedores Nacionais])
    end

    %% Módulo Nacional (Marketplace B2B)
    subgraph MercadoNacional ["Mercado B2B Nacional"]
        direction TB
        UC_ConsultarFornecedor([Consultar Catálogo de Fornecedores])
    end

    %% App AquaSertão (Visão do Cliente/Produtor)
    subgraph AppAquaSertao ["App AquaSertão Android (Tenant)"]
        direction TB
        
        subgraph ModOperacional ["Módulo Operacional (Campo)"]
            direction TB
            UC_GestaoTanques([Gerenciar Tanques])
            UC_RegistrarAlimentacao([Registrar Alimentação])
            UC_MedirAgua([Monitorar Qualidade da Água])
            UC_Estoque([Lançamentos de Estoque])
        end

        subgraph ModAprovacao ["Workflows de Aprovação"]
            direction TB
            UC_AprovarSolicitacao([Aprovar Lançamentos Suspeitos])
        end
        
        subgraph ModEstrategico ["Módulo Estratégico e Financeiro"]
            direction TB
            UC_Dashboard([Dashboard da Produção])
            UC_Financas([Gestão Financeira e Pagamentos])
            UC_Manutencao([Gerenciar Manutenção e Tarefas])
        end
        
        subgraph ModGeral ["Módulo Geral"]
            direction TB
            UC_Notificacao([Receber Notificações Push])
        end
    end

    %% Conexões do Admin SaaS
    AdminSaaS --> BackofficeSaaS
    BackofficeSaaS --> MercadoNacional

    %% Conexões do Funcionário (Restrito Operacional)
    Funcionario --> ModOperacional
    Funcionario --> ModGeral
    Funcionario -. "Cria Solicitações" .-> ModAprovacao

    %% Conexões do Dono da Fazenda (Acesso Total)
    DonoFazenda --> ModOperacional
    DonoFazenda --> ModEstrategico
    DonoFazenda --> ModAprovacao
    DonoFazenda --> MercadoNacional
    DonoFazenda --> ModGeral
    
    %% Alertas e Integrações do Sistema (Sensores IoT)
    Sistema -. "Push Alerts / Sensores IoT" .-> ModGeral
```
