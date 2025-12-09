# 🎨 GUIA: CRIAR FEATURE GRAPHIC E SCREENSHOTS

## 📐 FEATURE GRAPHIC (1024x500) - OBRIGATÓRIO

### Opção 1: Canva (RECOMENDADO - Grátis e Fácil)

#### Passo a Passo:

1. **Acessar Canva:**
   ```
   https://www.canva.com/
   ```

2. **Criar Design Personalizado:**
   - Clicar em "Create a design"
   - Custom dimensions: **1024 x 500 pixels**
   - Clicar em "Create new design"

3. **Configurar Background:**
   - Clicar em "Elements" → "Gradients"
   - Ou usar cores sólidas:
     - Background: `#0F2027` (Deep Blue)
     - Adicionar gradiente para `#2C5364` (Teal Blue)
   - Aplicar gradiente diagonal (TopLeft → BottomRight)

4. **Adicionar Texto Principal:**
   - Clicar em "Text" → "Add a heading"
   - Texto: **"FinAgeVoz"**
   - Fonte: **Poppins Bold** ou **Montserrat Bold**
   - Tamanho: **80-100px**
   - Cor: **Branco (#FFFFFF)**
   - Posição: Centro-superior

5. **Adicionar Slogan:**
   - Texto: **"Sua vida organizada pela voz"**
   - Fonte: **Poppins Regular** ou **Source Sans Pro**
   - Tamanho: **28-32px**
   - Cor: **Branco 80% opacidade**
   - Posição: Abaixo do título

6. **Adicionar Ícones:**
   - Clicar em "Elements" → Buscar:
     - "wallet icon" (Carteira)
     - "calendar icon" (Agenda)
     - "pill icon" ou "medicine icon" (Remédio)
   - Cor dos ícones: **#00E5FF** (Cyan)
   - Tamanho: **60-80px** cada
   - Posição: Linha horizontal na parte inferior
   - Espaçamento igual entre eles

7. **Adicionar Labels dos Ícones:**
   - Abaixo de cada ícone:
     - "Finanças"
     - "Agenda"
     - "Saúde"
   - Fonte: **Poppins Regular**
   - Tamanho: **18-20px**
   - Cor: **Branco**

8. **Adicionar Ícone de Microfone:**
   - Buscar: "microphone icon"
   - Cor: **#00E5FF** (Cyan)
   - Tamanho: **40-50px**
   - Posição: Canto superior direito
   - Adicionar efeito de glow (opcional)

9. **Efeitos Finais:**
   - Adicionar sombras sutis nos textos
   - Adicionar glow nos ícones (Effects → Glow)
   - Ajustar espaçamento

10. **Download:**
    - Clicar em "Share" → "Download"
    - Formato: **PNG**
    - Qualidade: **Alta**
    - Nome: `feature-graphic.png`

---

### Opção 2: Photopea (Grátis, Online, Similar ao Photoshop)

#### Passo a Passo:

1. **Acessar Photopea:**
   ```
   https://www.photopea.com/
   ```

2. **Novo Projeto:**
   - File → New
   - Width: **1024 px**
   - Height: **500 px**
   - Resolution: **72 DPI**
   - Background: Transparent

3. **Criar Gradiente:**
   - Selecionar Gradient Tool (G)
   - Cores: `#0F2027` → `#2C5364`
   - Tipo: Linear
   - Direção: Diagonal (TopLeft → BottomRight)
   - Aplicar no canvas

4. **Adicionar Texto:**
   - Text Tool (T)
   - Fonte: Poppins Bold (ou similar)
   - Tamanho: 80-100px
   - Cor: Branco
   - Texto: "FinAgeVoz"
   - Posicionar no centro-superior

5. **Adicionar Ícones:**
   - Baixar ícones SVG de:
     - https://www.flaticon.com/
     - https://fontawesome.com/icons
   - Importar: File → Open & Place
   - Colorir: #00E5FF
   - Posicionar na parte inferior

6. **Exportar:**
   - File → Export as → PNG
   - Nome: `feature-graphic.png`

---

### Opção 3: Template Pronto (Mais Rápido)

Use este template como base:

```
┌────────────────────────────────────────────────────────────┐
│                                                  🎤        │
│                                                            │
│                    FinAgeVoz                               │
│           Sua vida organizada pela voz                     │
│                                                            │
│                                                            │
│      💰              📅              💊                    │
│   Finanças         Agenda          Saúde                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Cores:**
- Background: Gradiente #0F2027 → #2C5364
- Texto: Branco (#FFFFFF)
- Ícones: Cyan (#00E5FF)

---

## 📸 SCREENSHOTS (Mínimo 2, Recomendado 8)

### Como Tirar Screenshots:

#### No Dispositivo Android:
1. Abrir o app
2. Navegar para a tela desejada
3. Pressionar: **Volume Down + Power** simultaneamente
4. Screenshot salvo em: `Pictures/Screenshots/`

#### Via ADB (Computador):
```bash
# Tirar screenshot
adb shell screencap -p /sdcard/screenshot.png

# Baixar para computador
adb pull /sdcard/screenshot.png screenshot.png
```

---

### Screenshots Recomendados:

#### 1. **Home Screen** (Dashboard)
- Mostra: Resumo financeiro, próximos eventos
- Destaque: Interface principal

#### 2. **Agenda - 4 Abas**
- Mostra: As 4 abas (Eventos, Aniversários, Parcelas, Medicamentos)
- Destaque: Organização em abas

#### 3. **Finanças - Gráficos**
- Mostra: Gráfico de gastos por categoria
- Destaque: Visualização de dados

#### 4. **Aniversários com IA**
- Mostra: Lista de aniversários com botão "Enviar Mensagem IA"
- Destaque: Funcionalidade exclusiva

#### 5. **Controle de Parcelas**
- Mostra: Lista de parcelas (pagas, pendentes, atrasadas)
- Destaque: Gestão de pagamentos

#### 6. **Medicamentos**
- Mostra: Lista de medicamentos com horários
- Destaque: Gestão de saúde

#### 7. **Comando de Voz**
- Mostra: Interface de voz ativa
- Destaque: Controle por voz

#### 8. **Relatórios**
- Mostra: Relatórios e exportação
- Destaque: Análises detalhadas

---

### Editar Screenshots (Opcional):

#### Adicionar Moldura de Dispositivo:

**Ferramenta Online:**
```
https://mockuphone.com/
```

1. Upload screenshot
2. Escolher modelo de dispositivo (Samsung, etc.)
3. Download com moldura

#### Adicionar Texto Descritivo:

Use Canva ou Photopea para adicionar:
- Título da funcionalidade
- Breve descrição
- Setas apontando recursos

---

## 📏 ESPECIFICAÇÕES TÉCNICAS

### Feature Graphic:
- **Tamanho:** 1024 x 500 pixels
- **Formato:** PNG ou JPEG
- **Tamanho máximo:** 1 MB
- **Obrigatório:** SIM

### Screenshots:
- **Tamanho mínimo:** 320 pixels (lado menor)
- **Tamanho máximo:** 3840 pixels (lado maior)
- **Formato:** PNG ou JPEG
- **Quantidade:** Mínimo 2, máximo 8
- **Orientação:** Portrait (vertical) recomendado

### Ícone do App:
- **Tamanho:** 512 x 512 pixels
- **Formato:** PNG (32-bit)
- **Já existe em:** `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

---

## 🎨 PALETA DE CORES DO APP

Use estas cores para manter consistência:

```
Deep Blue:     #0F2027
Medium Gray:   #203A43
Teal Blue:     #2C5364
Cyan Neon:     #00E5FF
Teal:          #00BCD4
White:         #FFFFFF
Dark BG:       #121212
```

---

## 📝 TEXTOS PARA SCREENSHOTS (Opcional)

Se quiser adicionar descrições nas screenshots:

1. **Home:** "Dashboard completo com resumo financeiro"
2. **Agenda:** "4 abas especializadas para cada área"
3. **Finanças:** "Gráficos detalhados de gastos"
4. **Aniversários:** "Mensagens automáticas por IA"
5. **Parcelas:** "Controle de pagamentos com avisos"
6. **Medicamentos:** "Nunca esqueça seus remédios"
7. **Voz:** "Controle total por comando de voz"
8. **Relatórios:** "Exportação e análises completas"

---

## 🚀 CHECKLIST FINAL

### Feature Graphic:
- [ ] Criado em 1024x500
- [ ] Gradiente Dark Fintech
- [ ] Logo "FinAgeVoz"
- [ ] Slogan
- [ ] 3 ícones (Finanças, Agenda, Saúde)
- [ ] Ícone de microfone
- [ ] Salvo como PNG
- [ ] Tamanho < 1 MB

### Screenshots:
- [ ] Mínimo 2 screenshots tirados
- [ ] Telas principais capturadas
- [ ] Imagens claras e legíveis
- [ ] Formato PNG ou JPEG
- [ ] Tamanho adequado (320-3840px)

---

## 📂 ORGANIZAÇÃO DOS ARQUIVOS

Crie uma pasta para os assets:

```
FinAgeVoz/
├── play_store_assets/
│   ├── feature-graphic.png (1024x500)
│   ├── screenshots/
│   │   ├── 01-home.png
│   │   ├── 02-agenda.png
│   │   ├── 03-financas.png
│   │   ├── 04-aniversarios.png
│   │   ├── 05-parcelas.png
│   │   ├── 06-medicamentos.png
│   │   ├── 07-voz.png
│   │   └── 08-relatorios.png
│   └── icon-512.png (se precisar)
```

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ Criar Feature Graphic (Canva recomendado)
2. ✅ Tirar screenshots do app (mínimo 2)
3. ✅ Organizar arquivos na pasta
4. ✅ Fazer upload no Google Play Console
5. ✅ Preencher descrições (usar `GOOGLE_PLAY_DESCRIPTIONS.md`)
6. ✅ Submeter para revisão

---

## 💡 DICAS PROFISSIONAIS

### Feature Graphic:
- Mantenha simples e legível
- Use cores do app (consistência)
- Destaque o diferencial (comando de voz)
- Evite muito texto
- Teste em diferentes tamanhos

### Screenshots:
- Use dados reais (não lorem ipsum)
- Mostre funcionalidades principais
- Evite informações pessoais
- Mantenha interface limpa
- Ordem lógica (do geral ao específico)

---

## 🔗 RECURSOS ÚTEIS

### Ícones Grátis:
- Font Awesome: https://fontawesome.com/icons
- Flaticon: https://www.flaticon.com/
- Material Icons: https://fonts.google.com/icons

### Fontes Grátis:
- Google Fonts: https://fonts.google.com/
- Poppins: https://fonts.google.com/specimen/Poppins
- Source Sans Pro: https://fonts.google.com/specimen/Source+Sans+Pro

### Ferramentas:
- Canva: https://www.canva.com/
- Photopea: https://www.photopea.com/
- MockUPhone: https://mockuphone.com/

---

**Siga este guia para criar assets profissionais para a Google Play Store!** 🎨🚀

**Tempo estimado:** 30-45 minutos para criar tudo.
