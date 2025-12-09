# 📄 Páginas Web - Privacy Policy e Terms of Service

## 📦 Arquivos Criados

Este diretório contém as páginas HTML para:

1. **Privacy Policy (Política de Privacidade)**
   - `privacy-policy-pt.html` - Versão em Português
   - `privacy-policy-en.html` - Versão em English

2. **Terms of Service (Termos de Uso)**
   - `terms-of-service-pt.html` - Versão em Português

---

## 🌐 Como Hospedar (3 Opções)

### Opção 1: GitHub Pages (GRÁTIS - RECOMENDADO)

#### Passo a Passo:

1. **Criar Repositório no GitHub**
   ```bash
   # Criar novo repositório chamado "finagevoz-legal"
   # Ou usar um existente
   ```

2. **Fazer Upload dos Arquivos**
   ```bash
   git init
   git add web_pages/*
   git commit -m "Add privacy policy and terms of service"
   git branch -M main
   git remote add origin https://github.com/SEU_USUARIO/finagevoz-legal.git
   git push -u origin main
   ```

3. **Ativar GitHub Pages**
   - Ir para Settings → Pages
   - Source: Deploy from a branch
   - Branch: main → /root
   - Save

4. **URLs Resultantes:**
   ```
   https://SEU_USUARIO.github.io/finagevoz-legal/web_pages/privacy-policy-pt.html
   https://SEU_USUARIO.github.io/finagevoz-legal/web_pages/privacy-policy-en.html
   https://SEU_USUARIO.github.io/finagevoz-legal/web_pages/terms-of-service-pt.html
   ```

5. **Atualizar URLs no App:**
   - `privacy_welcome_dialog.dart` (linhas 32 e 40)
   - `paywall_screen.dart` (linhas 226 e 238)

---

### Opção 2: Firebase Hosting (GRÁTIS)

#### Passo a Passo:

1. **Instalar Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login no Firebase**
   ```bash
   firebase login
   ```

3. **Inicializar Projeto**
   ```bash
   cd web_pages
   firebase init hosting
   # Selecionar projeto existente ou criar novo
   # Public directory: . (ponto)
   # Configure as SPA: No
   # Set up automatic builds: No
   ```

4. **Deploy**
   ```bash
   firebase deploy --only hosting
   ```

5. **URLs Resultantes:**
   ```
   https://SEU_PROJETO.web.app/privacy-policy-pt.html
   https://SEU_PROJETO.web.app/privacy-policy-en.html
   https://SEU_PROJETO.web.app/terms-of-service-pt.html
   ```

---

### Opção 3: Domínio Próprio

Se você tem um domínio (ex: finagevoz.com):

1. **Fazer upload via FTP/cPanel**
   - Copiar arquivos para pasta `public_html/legal/`

2. **URLs Resultantes:**
   ```
   https://finagevoz.com/legal/privacy-policy-pt.html
   https://finagevoz.com/legal/privacy-policy-en.html
   https://finagevoz.com/legal/terms-of-service-pt.html
   ```

---

## ✅ Checklist Pós-Hospedagem

Após hospedar as páginas, você precisa:

### 1. Atualizar URLs no Privacy Welcome Dialog

**Arquivo:** `lib/widgets/privacy_welcome_dialog.dart`

```dart
// Linha 32
Future<void> _openPrivacyPolicy() async {
  final url = Uri.parse('https://SEU_URL/privacy-policy-pt.html'); // ✅ ATUALIZAR
  // ...
}

// Linha 40
Future<void> _openTermsOfService() async {
  final url = Uri.parse('https://SEU_URL/terms-of-service-pt.html'); // ✅ ATUALIZAR
  // ...
}
```

### 2. Atualizar URLs no Paywall Screen

**Arquivo:** `lib/screens/subscription/paywall_screen.dart`

```dart
// Linha 226
final url = Uri.parse('https://SEU_URL/privacy-policy-pt.html'); // ✅ ATUALIZAR

// Linha 238
final url = Uri.parse('https://SEU_URL/terms-of-service-pt.html'); // ✅ ATUALIZAR
```

### 3. Testar Links

```
1. Abrir app
2. Ir para Privacy Welcome Dialog
3. Clicar em "Política de Privacidade"
4. Verificar se abre no navegador
5. Clicar em "Termos de Uso"
6. Verificar se abre no navegador
7. Ir para Paywall
8. Testar links lá também
```

---

## 📱 Suporte a Múltiplos Idiomas

### Detecção Automática de Idioma

Você pode criar uma página de redirecionamento que detecta o idioma:

**Arquivo:** `index.html` (criar na raiz)

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Redirecting...</title>
    <script>
        // Detectar idioma do navegador
        const lang = navigator.language || navigator.userLanguage;
        
        // Redirecionar para versão apropriada
        if (lang.startsWith('pt')) {
            window.location.href = 'privacy-policy-pt.html';
        } else {
            window.location.href = 'privacy-policy-en.html';
        }
    </script>
</head>
<body>
    <p>Redirecting...</p>
</body>
</html>
```

Então usar URL: `https://SEU_URL/index.html`

---

## 🎨 Personalização

### Alterar Cores

Edite o CSS nas páginas HTML:

```css
/* Cor principal (atualmente cyan) */
h1, h2 {
    color: #00E5FF; /* ✅ Alterar aqui */
}

header {
    border-bottom: 3px solid #00E5FF; /* ✅ E aqui */
}
```

### Adicionar Logo

```html
<!-- Adicionar no <header> -->
<img src="logo.png" alt="FinAgeVoz Logo" style="width: 100px; margin-bottom: 20px;">
```

---

## 📊 Estatísticas

| Arquivo | Tamanho | Idioma |
|---------|---------|--------|
| privacy-policy-pt.html | ~8 KB | Português |
| privacy-policy-en.html | ~7 KB | English |
| terms-of-service-pt.html | ~10 KB | Português |

---

## ✅ Conformidade

Estas páginas atendem aos requisitos de:

- ✅ Google Play Store
- ✅ Apple App Store
- ✅ RGPD/GDPR (Europa)
- ✅ LGPD (Brasil)
- ✅ COPPA (EUA - Crianças)

---

## 🔄 Atualizações Futuras

Quando precisar atualizar as políticas:

1. Editar arquivos HTML
2. Atualizar data em "Last updated"
3. Fazer commit e push (GitHub Pages)
4. Ou fazer novo deploy (Firebase)
5. Notificar usuários sobre mudanças significativas

---

## 📞 Suporte

Para dúvidas sobre hospedagem:

- **GitHub Pages:** https://pages.github.com/
- **Firebase Hosting:** https://firebase.google.com/docs/hosting
- **Email:** abreu@multiversodigital.com.br

---

**Criado em:** 2025-12-09  
**Versão:** 1.0  
**Status:** ✅ Pronto para hospedagem
