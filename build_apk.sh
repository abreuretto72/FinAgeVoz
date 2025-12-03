#!/bin/bash
# Script para gerar APK com nome personalizado

echo "Gerando APK de release..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "Build concluído com sucesso!"
    echo "Renomeando APK para finagevoz.apk..."
    cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/finagevoz.apk
    echo "✓ APK gerado: build/app/outputs/flutter-apk/finagevoz.apk"
else
    echo "✗ Erro ao gerar APK"
    exit 1
fi
