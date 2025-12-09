# 🌍 GUIA DE SCREENSHOTS MULTILÍNGUES

Como o FinAgeVoz suporta **Português** e **Inglês**, é altamente recomendado enviar screenshots em ambos os idiomas para o Google Play. Isso aumenta o alcance global do app.

---

## 📸 PARTE 1: SCREENSHOTS EM PORTUGUÊS (PT-BR)

**Passo 1:** Certifique-se de que seu celular está em Português.
**Passo 2:** Siga o guia `SCREENSHOTS_GUIDE.md` para capturar as telas.
**Passo 3:** Salve na pasta: `play_store_assets/screenshots/pt-br/`

*Crie a pasta se não existir:*
```powershell
New-Item -ItemType Directory -Force -Path "play_store_assets\screenshots\pt-br"
```

---

## 📸 PARTE 2: SCREENSHOTS EM INGLÊS (EN-US)

**Passo 1: Mudar idioma do celular**
1. Vá em Configurações do Android
2. Procure por "Idioma e Entrada" ou "Language Management"
3. Adicione "English (United States)" e mova para o topo da lista
4. O celular vai mudar para Inglês (pode levar alguns segundos)

**Passo 2: Abrir FinAgeVoz**
- O app deve detectar automaticamente o idioma e mostrar textos em Inglês.
- O diálogo "Configuração Inicial" pode aparecer novamente ou as configs podem resetar visualmente, mas seus dados permanecem.

**Passo 3: Capturar as mesmas telas**
- Home Screen (verifique se está "Finance", "Agenda", etc.)
- Agenda Tabs
- Finance
- Settings (verifique "Language: English")

**Passo 4: Salvar na pasta EN-US**
Salve em: `play_store_assets/screenshots/en-us/`

*Crie a pasta:*
```powershell
New-Item -ItemType Directory -Force -Path "play_store_assets\screenshots\en-us"
```

---

## 📤 COMO SUBIR NA GOOGLE PLAY STORE

1. No Console, vá em **Main Store Listing**.
2. Em **Graphics**, você verá seções por idioma ou uma seção "Default".
3. Se você adicionou traduções na loja (Manage Translations):
   - Selecione **Portuguese (Brazil)** -> Suba os prints da pasta `pt-br`.
   - Selecione **English (United States)** -> Suba os prints da pasta `en-us`.
4. Se não adicionou traduções, suba os prints em **Inglês** como Default (padrão internacional) e adicione o Português como idioma específico.

---

## 🌟 DICA PRO

- Mantenha os mesmos nomes de arquivo (ex: `01-home.png`) em ambas as pastas para facilitar o upload.
- Não misture idiomas na mesma lista de screenshots da loja.

---

**Arquivos de Descrição:**
- Português: `GOOGLE_PLAY_DESCRIPTIONS.md`
- Inglês: `GOOGLE_PLAY_DESCRIPTIONS_EN.md`

**Pronto para globalizar seu app!** 🌎🚀
