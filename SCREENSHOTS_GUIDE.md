# 📸 GUIA RÁPIDO: TIRAR SCREENSHOTS

## 🎯 TELAS NECESSÁRIAS (Mínimo 2, Recomendado 8)

### Lista de Screenshots Recomendados:

1. ✅ **Home Screen** - Dashboard principal
2. ✅ **Agenda - 4 Abas** - Mostrando as abas
3. ✅ **Finanças** - Gráficos e transações
4. ✅ **Aniversários** - Com funcionalidade IA
5. ✅ **Parcelas** - Controle de pagamentos
6. ✅ **Medicamentos** - Lista de remédios
7. ✅ **Comando de Voz** - Interface ativa
8. ✅ **Relatórios** - Gráficos e exportação

---

## 📱 MÉTODO 1: NO DISPOSITIVO (MAIS FÁCIL)

### Como Tirar:
```
Pressionar simultaneamente:
Volume Down + Power

Ou em alguns dispositivos:
Volume Up + Power
```

### Onde Encontrar:
```
Galeria → Screenshots
ou
Arquivos → Pictures → Screenshots
```

### Transferir para PC:
```
1. Conectar USB
2. Abrir pasta do dispositivo
3. Ir para: DCIM/Screenshots
4. Copiar imagens para: E:\antigravity_projetos\FinAgeVoz\play_store_assets\screenshots\
```

---

## 💻 MÉTODO 2: VIA ADB (AUTOMÁTICO)

### Passo a Passo:

#### 1. Criar Pasta para Screenshots
```bash
mkdir play_store_assets
mkdir play_store_assets\screenshots
```

#### 2. Navegar pelas Telas e Capturar

**Screenshot 1: Home Screen**
```bash
# No app: Ir para Home Screen
# No terminal:
adb shell screencap -p /sdcard/screenshot_01_home.png
adb pull /sdcard/screenshot_01_home.png play_store_assets\screenshots\01-home.png
```

**Screenshot 2: Agenda - 4 Abas**
```bash
# No app: Ir para Agenda, mostrar as 4 abas
adb shell screencap -p /sdcard/screenshot_02_agenda.png
adb pull /sdcard/screenshot_02_agenda.png play_store_assets\screenshots\02-agenda.png
```

**Screenshot 3: Finanças**
```bash
# No app: Ir para Finanças, mostrar gráficos
adb shell screencap -p /sdcard/screenshot_03_financas.png
adb pull /sdcard/screenshot_03_financas.png play_store_assets\screenshots\03-financas.png
```

**Screenshot 4: Aniversários**
```bash
# No app: Ir para Agenda → Aba Aniversários
adb shell screencap -p /sdcard/screenshot_04_aniversarios.png
adb pull /sdcard/screenshot_04_aniversarios.png play_store_assets\screenshots\04-aniversarios.png
```

**Screenshot 5: Parcelas**
```bash
# No app: Ir para Agenda → Aba Parcelas
adb shell screencap -p /sdcard/screenshot_05_parcelas.png
adb pull /sdcard/screenshot_05_parcelas.png play_store_assets\screenshots\05-parcelas.png
```

**Screenshot 6: Medicamentos**
```bash
# No app: Ir para Agenda → Aba Medicamentos
adb shell screencap -p /sdcard/screenshot_06_medicamentos.png
adb pull /sdcard/screenshot_06_medicamentos.png play_store_assets\screenshots\06-medicamentos.png
```

**Screenshot 7: Comando de Voz**
```bash
# No app: Ativar comando de voz (botão de microfone)
adb shell screencap -p /sdcard/screenshot_07_voz.png
adb pull /sdcard/screenshot_07_voz.png play_store_assets\screenshots\07-voz.png
```

**Screenshot 8: Relatórios**
```bash
# No app: Ir para Relatórios
adb shell screencap -p /sdcard/screenshot_08_relatorios.png
adb pull /sdcard/screenshot_08_relatorios.png play_store_assets\screenshots\08-relatorios.png
```

---

## 🚀 SCRIPT AUTOMATIZADO

Vou criar um script para facilitar:

### Windows (PowerShell):
```powershell
# Criar pastas
New-Item -ItemType Directory -Force -Path "play_store_assets\screenshots"

# Função para capturar
function Capture-Screen {
    param($number, $name)
    Write-Host "Capturando tela $number - $name"
    Write-Host "Navegue para a tela desejada e pressione ENTER..."
    Read-Host
    
    adb shell screencap -p /sdcard/temp_screenshot.png
    adb pull /sdcard/temp_screenshot.png "play_store_assets\screenshots\$number-$name.png"
    adb shell rm /sdcard/temp_screenshot.png
    
    Write-Host "Screenshot salvo: $number-$name.png`n"
}

# Capturar todas as telas
Capture-Screen "01" "home"
Capture-Screen "02" "agenda"
Capture-Screen "03" "financas"
Capture-Screen "04" "aniversarios"
Capture-Screen "05" "parcelas"
Capture-Screen "06" "medicamentos"
Capture-Screen "07" "voz"
Capture-Screen "08" "relatorios"

Write-Host "Todas as screenshots foram salvas em: play_store_assets\screenshots\"
```

---

## 📋 CHECKLIST DE SCREENSHOTS

### Antes de Tirar:
- [ ] App rodando no dispositivo
- [ ] Dados de exemplo visíveis (não vazio)
- [ ] Interface limpa (sem erros)
- [ ] Orientação portrait (vertical)

### Telas Obrigatórias (Mínimo 2):
- [ ] Home Screen
- [ ] Agenda (mostrando 4 abas)

### Telas Recomendadas (Total 8):
- [ ] Home Screen
- [ ] Agenda - 4 Abas
- [ ] Finanças - Gráficos
- [ ] Aniversários - IA
- [ ] Parcelas - Controle
- [ ] Medicamentos - Lista
- [ ] Comando de Voz
- [ ] Relatórios

### Depois de Tirar:
- [ ] Verificar qualidade (legível)
- [ ] Verificar tamanho (320-3840px)
- [ ] Renomear arquivos (01-home.png, etc.)
- [ ] Organizar na pasta screenshots/

---

## 📏 ESPECIFICAÇÕES TÉCNICAS

### Requisitos Google Play:
- **Tamanho mínimo:** 320 pixels (lado menor)
- **Tamanho máximo:** 3840 pixels (lado maior)
- **Formato:** PNG ou JPEG
- **Quantidade:** Mínimo 2, máximo 8
- **Orientação:** Portrait recomendado

### Seu Dispositivo (SM A256E):
- **Resolução:** 1080 x 2340 pixels ✅
- **Formato:** PNG ✅
- **Orientação:** Portrait ✅

---

## 🎨 DICAS PARA BOAS SCREENSHOTS

### O Que Mostrar:
- ✅ Dados reais (não lorem ipsum)
- ✅ Interface completa
- ✅ Funcionalidades principais
- ✅ Design profissional

### O Que Evitar:
- ❌ Informações pessoais reais
- ❌ Telas vazias
- ❌ Erros ou bugs
- ❌ Textos cortados

### Preparar Dados de Exemplo:
```
Antes de tirar screenshots:
1. Adicionar algumas transações
2. Criar alguns eventos
3. Cadastrar medicamentos
4. Adicionar aniversários
5. Criar parcelas
```

---

## 📂 ESTRUTURA DE PASTAS

```
FinAgeVoz/
├── play_store_assets/
│   ├── screenshots/
│   │   ├── 01-home.png
│   │   ├── 02-agenda.png
│   │   ├── 03-financas.png
│   │   ├── 04-aniversarios.png
│   │   ├── 05-parcelas.png
│   │   ├── 06-medicamentos.png
│   │   ├── 07-voz.png
│   │   └── 08-relatorios.png
│   └── feature-graphic.png (criar depois)
```

---

## 🎯 PRÓXIMOS PASSOS

### Agora:
1. ✅ Criar pasta screenshots
2. ✅ Navegar pelas telas do app
3. ✅ Tirar screenshots (método 1 ou 2)
4. ✅ Transferir para PC
5. ✅ Organizar na pasta

### Depois:
1. ⏳ Criar Feature Graphic (Canva)
2. ⏳ Upload no Google Play Console
3. ⏳ Submeter

---

## 💡 ATALHO RÁPIDO

Se quiser apenas 2 screenshots (mínimo):

**Screenshot 1: Home**
```bash
# No app: Home Screen
# No terminal:
adb shell screencap -p /sdcard/home.png
adb pull /sdcard/home.png play_store_assets\screenshots\01-home.png
```

**Screenshot 2: Agenda**
```bash
# No app: Agenda (mostrando 4 abas)
# No terminal:
adb shell screencap -p /sdcard/agenda.png
adb pull /sdcard/agenda.png play_store_assets\screenshots\02-agenda.png
```

---

**Escolha o método que preferir e comece a capturar!** 📸
