#!/bin/bash

# AquaGestor - Script de Inicialização de Debug em Dispositivo Físico

echo "=============================================="
echo "   AquaGestor - Device Debug Launcher        "
echo "=============================================="

# Verificar se o ADB está instalado
if ! command -v adb &> /dev/null; then
    echo "Erro: ADB (Android Debug Bridge) não está instalado ou não está no PATH."
    echo "Instale via: sudo apt install android-tools-adb"
    exit 1
fi

echo "Verificando dispositivos conectados..."
devices=$(adb devices | grep -v "List of devices" | grep "device" | awk '{print $1}')

if [ -z "$devices" ]; then
    echo ""
    echo "❌ Nenhum dispositivo Android autorizado foi detectado."
    echo ""
    echo "Por favor, verifique os passos abaixo:"
    echo "1. Conecte o celular ao computador usando um cabo USB de dados."
    echo "2. Ative as 'Opções do Desenvolvedor' no aparelho."
    echo "3. Ative a 'Depuração USB'."
    echo "4. Desbloqueie a tela do celular e aceite a permissão de depuração na janela pop-up."
    echo "5. Mude a conexão USB para 'Transferência de Arquivos / MTP' se necessário."
    echo ""
    exit 1
fi

# Selecionar o primeiro dispositivo disponível
target_device=$(echo "$devices" | head -n 1)

echo "✅ Dispositivo detectado com sucesso: $target_device"
echo "Iniciando 'flutter run' no dispositivo..."
echo "=============================================="

flutter run -d "$target_device"
