# Script PowerShell para gerar APK com nome personalizado

Write-Host "Gerando APK de release..." -ForegroundColor Cyan
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build concluído com sucesso!" -ForegroundColor Green
    Write-Host "Renomeando APK para finagevoz.apk..." -ForegroundColor Cyan
    
    $sourcePath = "build\app\outputs\flutter-apk\app-release.apk"
    $destPath = "build\app\outputs\flutter-apk\finagevoz.apk"
    
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    
    Write-Host "✓ APK gerado: build\app\outputs\flutter-apk\finagevoz.apk" -ForegroundColor Green
    Write-Host "Tamanho: $((Get-Item $destPath).Length / 1MB) MB" -ForegroundColor Yellow
} else {
    Write-Host "✗ Erro ao gerar APK" -ForegroundColor Red
    exit 1
}
