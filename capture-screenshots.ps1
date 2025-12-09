# Script PowerShell para Capturar Screenshots do FinAgeVoz
# Uso: .\capture-screenshots.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CAPTURA DE SCREENSHOTS - FinAgeVoz" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se ADB está disponível
try {
    $null = adb devices
}
catch {
    Write-Host "ERRO: ADB não encontrado!" -ForegroundColor Red
    Write-Host "Instale o Android SDK Platform Tools" -ForegroundColor Yellow
    exit 1
}

# Criar pasta se não existir
$screenshotsPath = "play_store_assets\screenshots"
if (!(Test-Path $screenshotsPath)) {
    New-Item -ItemType Directory -Force -Path $screenshotsPath | Out-Null
}

Write-Host "Pasta de screenshots: $screenshotsPath" -ForegroundColor Green
Write-Host ""

# Função para capturar screenshot
function Capture-Screen {
    param(
        [string]$number,
        [string]$name,
        [string]$description
    )
    
    Write-Host "[$number/8] $description" -ForegroundColor Yellow
    Write-Host "   Navegue para a tela no dispositivo e pressione ENTER..." -ForegroundColor Gray
    Read-Host
    
    $tempFile = "/sdcard/temp_screenshot_$number.png"
    $outputFile = "$screenshotsPath\$number-$name.png"
    
    Write-Host "   Capturando..." -ForegroundColor Gray
    adb shell screencap -p $tempFile 2>$null
    
    Write-Host "   Transferindo..." -ForegroundColor Gray
    adb pull $tempFile $outputFile 2>$null | Out-Null
    
    Write-Host "   Limpando..." -ForegroundColor Gray
    adb shell rm $tempFile 2>$null
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length / 1MB
        Write-Host "   ✓ Salvo: $outputFile ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
    }
    else {
        Write-Host "   ✗ Erro ao salvar screenshot!" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Instruções iniciais
Write-Host "INSTRUÇÕES:" -ForegroundColor Cyan
Write-Host "1. Certifique-se de que o app está rodando no dispositivo" -ForegroundColor White
Write-Host "2. Para cada tela, navegue até ela no app" -ForegroundColor White
Write-Host "3. Pressione ENTER quando estiver pronto" -ForegroundColor White
Write-Host "4. O script irá capturar e salvar automaticamente" -ForegroundColor White
Write-Host ""
Write-Host "Pressione ENTER para começar..." -ForegroundColor Yellow
Read-Host
Write-Host ""

# Capturar todas as telas
Capture-Screen "01" "home" "Home Screen (Dashboard principal)"
Capture-Screen "02" "agenda" "Agenda (mostrando as 4 abas)"
Capture-Screen "03" "financas" "Finanças (gráficos e transações)"
Capture-Screen "04" "aniversarios" "Aniversários (com funcionalidade IA)"
Capture-Screen "05" "parcelas" "Parcelas (controle de pagamentos)"
Capture-Screen "06" "medicamentos" "Medicamentos (lista de remédios)"
Capture-Screen "07" "voz" "Comando de Voz (interface ativa)"
Capture-Screen "08" "relatorios" "Relatórios (gráficos e exportação)"

# Resumo final
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CAPTURA CONCLUÍDA!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$files = Get-ChildItem -Path $screenshotsPath -Filter "*.png"
Write-Host "Total de screenshots: $($files.Count)" -ForegroundColor Green
Write-Host "Localização: $screenshotsPath" -ForegroundColor Green
Write-Host ""

Write-Host "Arquivos criados:" -ForegroundColor Yellow
foreach ($file in $files) {
    $size = [math]::Round($file.Length / 1MB, 2)
    Write-Host "  • $($file.Name) ($size MB)" -ForegroundColor White
}

Write-Host ""
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "1. Verificar qualidade das screenshots" -ForegroundColor White
Write-Host "2. Criar Feature Graphic (1024x500) no Canva" -ForegroundColor White
Write-Host "3. Upload no Google Play Console" -ForegroundColor White
Write-Host ""
Write-Host "Guia completo: SCREENSHOTS_GUIDE.md" -ForegroundColor Yellow
Write-Host ""
