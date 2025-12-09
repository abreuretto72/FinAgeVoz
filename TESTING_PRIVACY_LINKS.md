# 🧪 GUIA DE TESTE - LINK DA POLÍTICA DE PRIVACIDADE

## ✅ APP RODANDO

**Status:** App iniciado com sucesso no dispositivo SM A256E

---

## 🎯 COMO TESTAR O LINK

### Teste 1: Privacy Welcome Dialog (Primeira Execução)

**Passos:**
1. ⏳ **Aguardar Splash Screen** (3 segundos)
   - Você verá o logo animado do FinAgeVoz
   - Gradiente Dark Fintech
   - Loading indicator

2. 👀 **Ver Privacy Welcome Dialog**
   - Se for primeira execução, aparecerá automaticamente
   - Se não aparecer, significa que já foi aceito antes

3. 🔗 **Clicar em "Política de Privacidade"**
   - Link no meio do dialog
   - Deve abrir o navegador

4. ✅ **Verificar se abre:**
   ```
   https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
   ```

5. ✅ **Verificar se a página carrega:**
   - Título: "Política de Privacidade - FinAgeVoz"
   - Conteúdo completo em português
   - Design profissional

---

### Teste 2: Settings → Privacy Policy

**Se o dialog não aparecer (já foi aceito):**

1. 📱 **Ir para Settings**
   - Tela inicial → Menu → Settings
   - Ou botão de configurações

2. 🔍 **Procurar "Política de Privacidade"**
   - Seção "Ajuda e Suporte"
   - Ícone de escudo azul

3. 👆 **Clicar em "Política de Privacidade"**
   - Abre tela interna do app
   - Mostra o conteúdo da política

4. 📄 **Verificar conteúdo:**
   - Texto em português
   - Botão de compartilhar
   - Informações de contato

---

### Teste 3: Paywall Screen

**Testar links no Paywall:**

1. 📱 **Ir para Settings → Minha Assinatura**
   - Ou qualquer tela que mostre o Paywall

2. 📜 **Rolar até o final**
   - Ver links de "Política de Privacidade" e "Termos de Uso"

3. 🔗 **Clicar em "Política de Privacidade"**
   - Deve abrir navegador
   - URL: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html

4. 🔗 **Clicar em "Termos de Uso"**
   - Deve abrir navegador
   - URL: https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html

---

## 🔄 SE O DIALOG NÃO APARECER

### Resetar Aceitação de Privacidade:

**Opção 1: Desinstalar e Reinstalar**
```bash
# No terminal onde o app está rodando:
# Pressionar 'q' para sair
# Depois:
flutter run
```

**Opção 2: Limpar Dados do App**
```
No dispositivo:
1. Configurações → Apps
2. FinAgeVoz
3. Armazenamento
4. Limpar dados
5. Abrir app novamente
```

**Opção 3: Via ADB**
```bash
# Limpar dados do app
adb shell pm clear com.antigravity.finagevoz.fin_age_voz

# Executar app novamente
flutter run
```

---

## ✅ CHECKLIST DE TESTE

### Privacy Welcome Dialog:
- [ ] Splash Screen aparece (3s)
- [ ] Privacy Dialog aparece
- [ ] Link "Política de Privacidade" está visível
- [ ] Clicar no link abre navegador
- [ ] URL correta carrega
- [ ] Página HTML exibe corretamente
- [ ] Link "Termos de Uso" funciona

### Settings → Privacy Policy:
- [ ] Menu Settings acessível
- [ ] Item "Política de Privacidade" visível
- [ ] Clicar abre tela interna
- [ ] Conteúdo em português exibido
- [ ] Botão compartilhar funciona

### Paywall Screen:
- [ ] Paywall acessível
- [ ] Links no rodapé visíveis
- [ ] Link "Política de Privacidade" abre navegador
- [ ] Link "Termos de Uso" abre navegador
- [ ] URLs corretas carregam

---

## 🌐 URLS PARA VERIFICAR

### Devem Abrir no Navegador:

✅ **Privacy Policy PT:**
```
https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
```

✅ **Privacy Policy EN:**
```
https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-en.html
```

✅ **Terms of Service:**
```
https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html
```

---

## 🐛 TROUBLESHOOTING

### Problema: Link não abre navegador

**Possíveis causas:**
1. Permissão de abrir links externos
2. URL mal formatada
3. Navegador padrão não configurado

**Solução:**
```dart
// Verificar no código se url_launcher está funcionando
// Arquivo: lib/widgets/privacy_welcome_dialog.dart
// Linhas 42-58
```

### Problema: Página 404

**Possíveis causas:**
1. GitHub Pages não ativado
2. URL incorreta
3. Arquivo não existe

**Solução:**
1. Verificar: https://github.com/abreuretto72/FinAgeVoz/settings/pages
2. Confirmar que está "Published"
3. Testar URL diretamente no navegador do computador

### Problema: Página não carrega

**Possíveis causas:**
1. Sem internet
2. GitHub Pages offline (raro)
3. Cache do navegador

**Solução:**
1. Verificar conexão
2. Limpar cache do navegador
3. Testar em modo anônimo

---

## 📱 COMANDOS ÚTEIS

### No Terminal do Flutter:

```
r  - Hot reload (recarregar código)
R  - Hot restart (reiniciar app)
q  - Quit (sair)
h  - Help (ajuda)
```

### Para Reiniciar Teste:

```bash
# Parar app
q

# Limpar dados
adb shell pm clear com.antigravity.finagevoz.fin_age_voz

# Executar novamente
flutter run
```

---

## ✅ RESULTADO ESPERADO

### Fluxo Completo de Sucesso:

```
1. App abre
   ↓
2. Splash Screen (3s)
   ↓
3. Privacy Welcome Dialog aparece
   ↓
4. Usuário clica "Política de Privacidade"
   ↓
5. Navegador abre
   ↓
6. Página HTML carrega
   ↓
7. Conteúdo exibido corretamente
   ↓
✅ TESTE PASSOU!
```

---

## 📊 STATUS ATUAL

**App:** ✅ Rodando  
**Dispositivo:** SM A256E  
**URLs:** ✅ Online  
**GitHub Pages:** ✅ Ativo  

**Pronto para testar!** 🧪

---

## 🎯 PRÓXIMA AÇÃO

**AGORA:**
1. Olhar para o dispositivo
2. Aguardar Splash Screen
3. Ver se Privacy Dialog aparece
4. Clicar no link
5. Verificar se abre navegador

**Se não aparecer:**
- Ir para Settings → Política de Privacidade
- Ou limpar dados do app e tentar novamente

---

**Boa sorte com o teste!** 🚀
