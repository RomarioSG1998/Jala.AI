# Diagrama ER (Entidade-Relacionamento)

Abaixo está o modelo conceitual atualizado para uma arquitetura SaaS robusta, utilizando nomenclaturas explícitas que "denunciam" exatamente o papel de cada entidade no sistema Multi-Tenant.

```mermaid
erDiagram
    %% ==========================================
    %% MÓDULO: NÚCLEO SaaS (CONTAS E ACESSOS GLOBAIS)
    %% ==========================================
    
    %% Usuário Global: A pessoa que faz login, seja ela Dona do SaaS ou Cliente.
    USUARIO_GLOBAL {
        uuid id PK
        string nome
        string email
        string senha
        string tipo_conta "SAAS_ADMIN (Dono do SaaS) ou CLIENTE"
        datetime data_cadastro
    }

    %% ==========================================
    %% MÓDULO: INQUILINOS (O ESPAÇO DE CADA CLIENTE)
    %% ==========================================
    
    %% Tenant Fazenda: O ambiente isolado (Workspace) de uma piscicultura.
    TENANT_FAZENDA {
        uuid id PK
        uuid usuario_dono_id FK
        string nome_fazenda
        string localizacao
    }

    %% Tabela de RBAC: Diz em qual Fazenda o Usuário pode entrar e o que ele é lá dentro.
    VINCULO_USUARIO_FAZENDA {
        uuid usuario_id FK
        uuid fazenda_id FK
        string papel_acesso "DONO_FAZENDA, GERENTE, OPERADOR, VISUALIZADOR"
    }

    %% ==========================================
    %% MÓDULO: ASSINATURAS E FATURAMENTO (BILLING)
    %% ==========================================

    PLANO_SAAS {
        uuid id PK
        string nome "Gratuito, Basico, Profissional, Empresarial"
        float preco_mensal
        int limite_tanques
    }

    ASSINATURA {
        uuid id PK
        uuid fazenda_id FK
        uuid plano_id FK
        string status "Ativa, Cancelada, Inadimplente"
        date data_vencimento
    }

    FATURA_PAGAMENTO {
        uuid id PK
        uuid assinatura_id FK
        float valor
        date data_pagamento
        string status "Pago, Pendente"
    }

    %% ==========================================
    %% MÓDULO: OPERACIONAL E FINANCEIRO DA FAZENDA
    %% ==========================================
    TANQUE {
        uuid id PK
        uuid fazenda_id FK
        string nome
        string especie
        int capacidade_peixes
        float volume_m3
    }

    ALIMENTACAO {
        uuid id PK
        uuid tanque_id FK
        datetime data_hora
        float quantidade_kg
    }

    MEDICAO_AGUA {
        uuid id PK
        uuid tanque_id FK
        datetime data_hora
        float ph
        float temperatura
    }

    MANUTENCAO {
        uuid id PK
        uuid fazenda_id FK
        string equipamento
    }

    TRANSACAO_FINANCEIRA {
        uuid id PK
        uuid fazenda_id FK
        string tipo "Receita, Despesa"
        float valor
    }

    ESTOQUE {
        uuid id PK
        uuid fazenda_id FK
        string item
        float quantidade
    }

    FORNECEDOR {
        uuid id PK
        uuid fazenda_id FK
        string nome
    }

    %% ==========================================
    %% RELACIONAMENTOS (O MOTOR DO SAAS)
    %% ==========================================

    %% Acessos
    USUARIO_GLOBAL ||--o{ TENANT_FAZENDA : "cria / é dono de"
    USUARIO_GLOBAL ||--o{ VINCULO_USUARIO_FAZENDA : "logado possui"
    TENANT_FAZENDA ||--o{ VINCULO_USUARIO_FAZENDA : "concede acesso via"
    
    %% Faturamento
    PLANO_SAAS ||--o{ ASSINATURA : "define regras"
    TENANT_FAZENDA ||--|| ASSINATURA : "paga"
    ASSINATURA ||--o{ FATURA_PAGAMENTO : "gera"

    %% Dados Isolados do Tenant
    TENANT_FAZENDA ||--o{ TANQUE : "possui"
    TENANT_FAZENDA ||--o{ TRANSACAO_FINANCEIRA : "registra"
    TENANT_FAZENDA ||--o{ ESTOQUE : "mantem"
    TENANT_FAZENDA ||--o{ FORNECEDOR : "possui"
    TENANT_FAZENDA ||--o{ MANUTENCAO : "programa"
    
    TANQUE ||--o{ ALIMENTACAO : "recebe"
    TANQUE ||--o{ MEDICAO_AGUA : "monitora"
```
