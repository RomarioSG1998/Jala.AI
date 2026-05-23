# Diagrama de Casos de Uso

Abaixo está a representação dos principais casos de uso do sistema AquaGestor.

```mermaid
usecaseDiagram
    actor Produtor as "Produtor (Admin)"
    actor Funcionario as "Funcionário"
    actor Sistema as "Sistema AquaGestor"

    package "App AquaGestor" {
        
        usecase UC_Auth as "Autenticação e Gestão de Perfil"
        usecase UC_GestaoTanques as "Gerenciar Tanques"
        usecase UC_RegistrarAlimentacao as "Registrar Alimentação"
        usecase UC_MedirAgua as "Monitorar Qualidade da Água"
        usecase UC_Dashboard as "Visualizar Dashboard e Relatórios"
        usecase UC_Financas as "Gestão Financeira (Receitas e Despesas)"
        usecase UC_GerenciarEquipe as "Gerenciar Funcionários e Permissões"
        usecase UC_GerenciarEstoque as "Gerenciar Estoque e Fornecedores"
        usecase UC_Assinatura as "Gerenciar Plano de Assinatura"
        
        usecase UC_Notificacoes as "Gerar Alertas e Notificações"
    }

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
    UC_Notificacoes -.-> Produtor : Envia alertas (ex: pH fora do ideal)
```
