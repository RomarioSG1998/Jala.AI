# Guia de Debug e Resolução de Problemas em Dispositivo Físico

Este guia documenta o método de depuração física e resolução de erros nativos de ciclo de vida e permissões no Android no projeto **AquaGestor**.

---

## 🚀 1. Como Iniciar o Debug no Celular

Para rodar o aplicativo diretamente no celular conectado via USB:

1. Acesse a pasta do frontend:
   ```bash
   cd frontend_flutter
   ```
2. Execute o script de inicialização automática:
   ```bash
   ./debug_device.sh
   ```
   *O script irá detectar o primeiro celular autorizado conectado via ADB e iniciará o `flutter run` automaticamente.*

---

## 🔌 2. Preparação do Aparelho (Caso não seja detectado)

Se o script indicar que nenhum dispositivo foi encontrado:
1. Vá em **Configurações -> Sobre o telefone -> Informações do software** e clique 7 vezes em **Número de compilação** para habilitar o modo desenvolvedor.
2. Acesse **Configurações -> Opções do desenvolvedor** e ative a **Depuração USB**.
3. Conecte o cabo USB, desbloqueie a tela e, no pop-up do celular, marque **Sempre permitir a depuração USB a partir deste computador** e confirme.
4. Garanta que o modo de conexão USB está configurado para **Transferência de Arquivos (MTP)** nas notificações do sistema.

---

## 🧠 3. Resolução de Problemas Comuns (Crashes)

### ⚠️ A. O aplicativo fecha ou reinicia do zero ao abrir a Câmera/Galeria (Activity State Loss)
* **Causa**: Em celulares com pouca memória RAM (como a linha Android Go com 2GB de RAM), o Android destrói a `MainActivity` do Flutter para liberar espaço para o seletor de imagens. Ao retornar, o app reinicia do zero.
* **Solução Rápida (Desenvolvedor)**: Desative a opção **"Não manter atividades"** (Don't keep activities) em *Opções do desenvolvedor* no celular.
* **Solução via Código**: O Flutter fornece o método `ImagePicker().retrieveLostData()` para recuperar arquivos selecionados que foram perdidos após a recriação da atividade.

### ⚠️ B. Falha de Permissão ou SecurityException ao abrir Galeria (Android 13+)
* **Causa**: A permissão `READ_EXTERNAL_STORAGE` é ignorada no Android 13 (API 33+).
* **Solução**: No `AndroidManifest.xml` já estão declaradas as permissões corretas:
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  ```
  O plugin `image_picker` gerencia nativamente a chamada ao seletor moderno.

### ⚠️ C. O aplicativo fecha do nada em Builds de Produção (Release APK)
* **Causa**: O otimizador de código R8 (minification/shrinking) pode remover bindings JNI essenciais usados por plugins nativos (como `image_picker` ou `shared_preferences`).
* **Solução Temporária**: Desativar o shrinking em `android/app/build.gradle.kts` no bloco release:
  ```kotlin
  release {
      isMinifyEnabled = false
      isShrinkResources = false
  }
  ```

---

## 📋 4. Comandos Úteis para Diagnóstico por Terminal

* **Listar dispositivos conectados**:
  ```bash
  adb devices
  ```
* **Visualizar logs nativos do sistema em tempo real (Logcat)**:
  ```bash
  adb logcat -v time
  ```
* **Filtrar logcat apenas por erros ou warnings**:
  ```bash
  adb logcat -v time *:E
  ```
* **Pesquisar ocorrências de encerramento de processo**:
  ```bash
  adb logcat -d | grep -E "ActivityManager|died|kill"
  ```
