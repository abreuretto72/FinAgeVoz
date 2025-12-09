# 🌐 ATIVAR GITHUB PAGES - GUIA PASSO A PASSO

## ✅ STATUS ATUAL

**Arquivos enviados:** ✅ SIM (commit 76417c4)  
**Localização:** `web_pages/` na raiz do repositório  
**GitHub Pages:** ⏳ PRECISA SER ATIVADO

---

## 📂 ARQUIVOS NO REPOSITÓRIO

```
FinAgeVoz/
├── web_pages/
│   ├── privacy-policy-pt.html  ✅
│   ├── privacy-policy-en.html  ✅
│   ├── terms-of-service-pt.html  ✅
│   └── README.md  ✅
```

---

## 🔧 COMO ATIVAR GITHUB PAGES

### PASSO 1: Acessar Configurações

1. Abrir navegador
2. Ir para: **https://github.com/abreuretto72/FinAgeVoz**
3. Clicar na aba **"Settings"** (⚙️ Configurações)

### PASSO 2: Ir para Pages

1. No menu lateral esquerdo, rolar até encontrar **"Pages"**
2. Clicar em **"Pages"**

**URL direta:**
```
https://github.com/abreuretto72/FinAgeVoz/settings/pages
```

### PASSO 3: Configurar Source

Na seção **"Build and deployment"**:

1. **Source:** Selecionar **"Deploy from a branch"**
2. **Branch:** Selecionar **"main"** (ou "master")
3. **Folder:** Selecionar **"/ (root)"**
4. Clicar em **"Save"**

### PASSO 4: Aguardar Deploy

Após salvar:
- GitHub mostrará: **"Your site is live at..."**
- Aguardar **1-2 minutos** para o deploy completar
- Uma marca verde ✅ aparecerá quando estiver pronto

---

## 🌐 URLS APÓS ATIVAÇÃO

### URL Base:
```
https://abreuretto72.github.io/FinAgeVoz/
```

### Páginas Específicas:
```
Privacy Policy PT:
https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html

Privacy Policy EN:
https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-en.html

Terms of Service:
https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html
```

---

## ✅ VERIFICAR SE ESTÁ FUNCIONANDO

### Teste 1: Abrir no Navegador
```
1. Aguardar 1-2 minutos após ativar
2. Abrir: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
3. Deve mostrar a página HTML da Política de Privacidade
```

### Teste 2: Verificar Status
```
1. Voltar para Settings → Pages
2. Verificar se aparece:
   "Your site is published at https://abreuretto72.github.io/FinAgeVoz/"
3. Marca verde ✅ indica sucesso
```

---

## ⚠️ PROBLEMAS COMUNS

### Problema 1: Página 404
**Causa:** GitHub Pages ainda não fez deploy  
**Solução:** Aguardar mais 1-2 minutos e tentar novamente

### Problema 2: Página não atualiza
**Causa:** Cache do navegador  
**Solução:** Pressionar Ctrl+F5 (hard refresh)

### Problema 3: "Site not found"
**Causa:** GitHub Pages não foi ativado corretamente  
**Solução:** Verificar configurações em Settings → Pages

---

## 🎯 CHECKLIST

- [ ] Acessar https://github.com/abreuretto72/FinAgeVoz/settings/pages
- [ ] Configurar Source: "Deploy from a branch"
- [ ] Selecionar Branch: "main"
- [ ] Selecionar Folder: "/ (root)"
- [ ] Clicar em "Save"
- [ ] Aguardar 1-2 minutos
- [ ] Testar URL: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
- [ ] Verificar se página carrega corretamente

---

## 📱 APÓS ATIVAR

### Testar no App:

1. **Desinstalar app** do dispositivo
2. **flutter run** para reinstalar
3. Aguardar **Splash Screen** (3s)
4. Ver **Privacy Welcome Dialog**
5. Clicar em **"Política de Privacidade"**
6. ✅ Verificar se abre no navegador
7. ✅ Verificar se página carrega

---

## 🔄 ALTERNATIVA: Criar index.html

Se preferir uma página inicial, crie `index.html` na raiz:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=web_pages/privacy-policy-pt.html">
    <title>FinAgeVoz - Redirecting...</title>
</head>
<body>
    <p>Redirecting to Privacy Policy...</p>
</body>
</html>
```

Então a URL seria:
```
https://abreuretto72.github.io/FinAgeVoz/
```

---

## 📞 SUPORTE

**Se ainda não funcionar:**

1. Verificar se commit foi feito: ✅ (76417c4)
2. Verificar se push foi feito: ✅ (origin/main)
3. Verificar se arquivos estão no GitHub:
   - Ir para: https://github.com/abreuretto72/FinAgeVoz/tree/main/web_pages
   - Deve mostrar os 4 arquivos

4. Aguardar até 5 minutos (primeira vez pode demorar)

---

## 🎉 RESULTADO ESPERADO

Após ativar GitHub Pages e aguardar deploy:

```
✅ https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
   → Mostra página HTML da Política de Privacidade em português

✅ https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-en.html
   → Mostra página HTML da Privacy Policy em inglês

✅ https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html
   → Mostra página HTML dos Termos de Uso em português
```

---

## 📝 RESUMO

1. **Ir para:** https://github.com/abreuretto72/FinAgeVoz/settings/pages
2. **Configurar:** Deploy from branch "main" / folder "root"
3. **Salvar**
4. **Aguardar:** 1-2 minutos
5. **Testar:** https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html

---

**Siga este guia e as páginas estarão online em poucos minutos!** 🚀
