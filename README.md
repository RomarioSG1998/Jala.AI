# AquaGestor (AquaSertão) 🐟

Bem-vindo ao **AquaGestor** (AquaSertão), uma plataforma centralizada desenvolvida para gerenciar e monitorar ecossistemas de piscicultura. O sistema fornece aos produtores um painel em tempo real para acompanhar populações de tanques, parâmetros de qualidade da água e cronogramas de alimentação, visando aumentar a eficiência operacional e a saúde dos peixes.

---

## 📋 Padronização de Processos de Desenvolvimento

Para garantir a estabilidade do ambiente local e de produção, os seguintes fluxos e comandos de execução foram padronizados.

> [!IMPORTANT]  
> **Regra de Execução:** O processo de compilação do APK Android **só deve ser realizado quando explicitamente solicitado pelo usuário**. Para rotinas normais de teste e execução local, siga a política de servidores web descrita abaixo.

---

## 🖥️ 1. Inicialização dos Servidores Locais (Padrão Web)

> [!TIP]  
> Sempre que for solicitado para **subir ou iniciar os servidores**, a opção padrão deve ser a execução dos **servidores web** (Frontend Web + Backend Spring Boot). Isso evita falhas de driver de interface nativa em ambientes Linux (como bugs de snap do Ubuntu).

### 🟢 Iniciando o Backend (Spring Boot)
O backend conecta-se por padrão ao banco de dados PostgreSQL hospedado no Neon. Certifique-se de configurar as variáveis de ambiente necessárias no arquivo `.env`.

Execute o comando a partir do diretório raiz:
```bash
./mvnw spring-boot:run
```

### 🔵 Iniciando o Frontend (Web Server)
O frontend deve ser executado no modo servidor web utilizando a porta `8082`. 

Execute o script auxiliar a partir da raiz ou entre no diretório `frontend_flutter`:
```bash
cd frontend_flutter
./start_frontend.sh
```
* **Acesso local:** Abra o navegador em `http://localhost:8082`
* **Dica de Visualização:** Pressione `F12` no navegador e clique em **Toggle Device Toolbar** (`Ctrl+Shift+M`) para simular a interface mobile de forma responsiva.

---

## 🤖 2. Compilação do APK Android (Apenas sob Demanda)

> [!WARNING]  
> **NÃO** execute este processo de forma automática. Compile o APK apenas quando o usuário solicitar formalmente no chat.

### Requisitos e Configuração do SDK
Caso o ambiente não possua o Android SDK configurado ou atualizado, o script automatizado pode ser usado para instalar as ferramentas necessárias de forma limpa em `~/Android/Sdk`:

```bash
# Executar o script de instalação do Android SDK em modo headless
bash .gemini/antigravity/brain/25169ccb-6698-4509-818d-698b25a18f5e/scratch/install_android_sdk.sh
```

### Comando de Compilação (APK Release)
Para gerar a versão final otimizada para dispositivos Android:

1. Acesse o diretório do frontend:
   ```bash
   cd frontend_flutter
   ```
2. Baixe e atualize as dependências compatíveis com o Flutter 3.38+ (como a versão estável do `file_picker` `^11.0.2`):
   ```bash
   flutter pub get
   ```
3. Execute a compilação:
   ```bash
   flutter build apk --release
   ```
4. O APK gerado estará disponível em:
   `frontend_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

## ⚙️ Configurações e Variáveis de Ambiente
Copie o template `.env.example` para `.env` na raiz do projeto e configure as credenciais de acesso ao banco de dados do Neon:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5432/neondb?sslmode=require
SPRING_DATASOURCE_USERNAME=neondb_owner
SPRING_DATASOURCE_PASSWORD=<password>
```
