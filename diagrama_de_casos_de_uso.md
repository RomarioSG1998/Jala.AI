# Diagrama de Casos de Uso

Abaixo está a representação dos principais casos de uso do sistema AquaGestor.

```mermaid
flowchart LR
    %% Atores
    Produtor(("Produtor (Admin)"))
    Funcionario(("Funcionário"))
    Sistema(("Sistema AquaGestor"))

    %% App
    subgraph AppAquaGestor ["App AquaGestor"]
        UC_Auth([Autenticação e Gestão de Perfil])
        UC_GestaoTanques([Gerenciar Tanques])
        UC_RegistrarAlimentacao([Registrar Alimentação])
        UC_MedirAgua([Monitorar Qualidade da Água])
        UC_Dashboard([Visualizar Dashboard e Relatórios])
        UC_Financas([Gestão Financeira])
        UC_GerenciarEquipe([Gerenciar Equipe e Permissões])
        UC_GerenciarEstoque([Gerenciar Estoque e Fornecedores])
        UC_Assinatura([Gerenciar Plano de Assinatura])
        UC_Notificacoes([Gerar Alertas e Notificações])
    end

    %% Relacionamentos
    Produtor --> UC_Auth
    Produtor --> UC_GestaoTanques
    Produtor --> UC_RegistrarAlimentacao
    Produtor --> UC_MedirAgua
    Produtor --> UC_Dashboard
    Produtor --> UC_Financas
    Produtor --> UC_GerenciarEquipe
    Produtor --> UC_GerenciarEstoque
    Produtor --> UC_Assinatura

    Funcionario --> UC_Auth
    Funcionario --> UC_GestaoTanques
    Funcionario --> UC_RegistrarAlimentacao
    Funcionario --> UC_MedirAgua
    
    Sistema --> UC_Notificacoes
    UC_Notificacoes -. "Envia alertas (ex: pH fora do ideal)" .-> Produtor
```
