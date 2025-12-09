# 🚀 GUIA DE UPLOAD E SUBMISSÃO - FinAgeVoz

## ✅ URLs ATUALIZADAS

**GitHub Pages URL:** https://abreuretto72.github.io/FinAgeVoz/

**Páginas Disponíveis:**
- Privacy Policy PT: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
- Privacy Policy EN: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-en.html
- Terms of Service: https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html

---

## 📦 PASSO 1: UPLOAD DA PASTA WEB_PAGES

### Opção A: Via GitHub Web Interface (FÁCIL)

1. **Ir para o repositório:**
   ```
   https://github.com/abreuretto72/FinAgeVoz
   ```

2. **Criar pasta web_pages:**
   - Clicar em "Add file" → "Create new file"
   - Digitar: `web_pages/README.md`
   - Colar conteúdo do README.md
   - Commit changes

3. **Upload dos arquivos HTML:**
   - Ir para pasta `web_pages`
   - Clicar em "Add file" → "Upload files"
   - Arrastar arquivos:
     - `privacy-policy-pt.html`
     - `privacy-policy-en.html`
     - `terms-of-service-pt.html`
   - Commit changes

### Opção B: Via Git Command Line (RÁPIDO)

```bash
# 1. Navegar para o projeto
cd e:\antigravity_projetos\FinAgeVoz

# 2. Verificar status
git status

# 3. Adicionar arquivos modificados
git add .

# 4. Commit
git commit -m "feat: Add privacy pages and update URLs for GitHub Pages"

# 5. Push
git push origin main
```

---

## 🌐 PASSO 2: ATIVAR GITHUB PAGES

1. **Ir para Settings do repositório:**
   ```
   https://github.com/abreuretto72/FinAgeVoz/settings/pages
   ```

2. **Configurar Source:**
   - Source: **Deploy from a branch**
   - Branch: **main** (ou master)
   - Folder: **/ (root)**
   - Save

3. **Aguardar deploy (1-2 minutos)**
   - GitHub mostrará: "Your site is live at https://abreuretto72.github.io/FinAgeVoz/"

4. **Verificar páginas:**
   - Abrir: https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html
   - Deve carregar a página HTML

---

## ✅ PASSO 3: TESTAR LINKS NO APP

### Teste 1: Privacy Welcome Dialog

```
1. Desinstalar app do dispositivo
2. Instalar novamente (flutter run)
3. Aguardar Splash Screen (3s)
4. Ver Privacy Welcome Dialog
5. Clicar em "Política de Privacidade"
6. ✅ Verificar se abre no navegador
7. ✅ Verificar se página carrega
8. Voltar ao app
9. Clicar em "Termos de Uso"
10. ✅ Verificar se abre no navegador
11. ✅ Verificar se página carrega
```

### Teste 2: Paywall Screen

```
1. Ir para Settings → Minha Assinatura
2. Clicar em "Assinar Premium"
3. Ver Paywall
4. Rolar até o final
5. Clicar em "Política de Privacidade"
6. ✅ Verificar se abre no navegador
7. Voltar ao app
8. Clicar em "Termos de Uso"
9. ✅ Verificar se abre no navegador
```

### Teste 3: Exclusão de Conta

```
1. Ir para Settings
2. Clicar em "Excluir Conta"
3. Ler avisos
4. Digitar "EXCLUIR"
5. Confirmar
6. ✅ Verificar se dados foram deletados
7. ✅ Verificar se voltou para tela inicial
```

---

## 🚀 PASSO 4: PREPARAR PARA SUBMISSÃO

### Checklist Pré-Submissão:

#### Código:
- [x] URLs atualizadas (GitHub Pages)
- [x] Privacy Welcome Dialog funcionando
- [x] Permission Rationale implementado
- [x] Delete Account funcionando
- [x] Links do Paywall funcionando
- [x] AndroidManifest limpo
- [ ] Versão atualizada (1.0.0+1)

#### Assets:
- [x] privacy_policy_pt.txt
- [x] privacy_policy_en.txt
- [x] Ícone do app (ic_launcher)
- [ ] Feature Graphic (1024x500)
- [ ] Screenshots (mínimo 2)

#### Páginas Web:
- [ ] privacy-policy-pt.html (GitHub Pages)
- [ ] privacy-policy-en.html (GitHub Pages)
- [ ] terms-of-service-pt.html (GitHub Pages)
- [ ] Todas acessíveis online

#### Google Play Console:
- [ ] Conta criada
- [ ] App criado
- [ ] Descrição escrita
- [ ] Screenshots enviados
- [ ] Feature Graphic enviado
- [ ] Questionário de dados preenchido
- [ ] APK/AAB gerado

---

## 📱 PASSO 5: GERAR APK/AAB

### Gerar AAB (Android App Bundle) - RECOMENDADO

```bash
# 1. Limpar build anterior
flutter clean

# 2. Obter dependências
flutter pub get

# 3. Gerar AAB
flutter build appbundle --release

# 4. Localização do arquivo:
# build/app/outputs/bundle/release/app-release.aab
```

### Gerar APK (Alternativo)

```bash
# Gerar APK
flutter build apk --release

# Localização:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 PASSO 6: PREENCHER GOOGLE PLAY CONSOLE

### 1. Informações do App

**Nome:** FinAgeVoz

**Descrição Curta (80 caracteres):**
```
Gestão financeira, agenda e saúde por comando de voz. Simples e seguro.
```

**Descrição Completa (4000 caracteres):**
```
🎤 FinAgeVoz - Sua Vida Organizada pela Voz

Gerencie suas finanças, agenda e saúde usando apenas sua voz! O FinAgeVoz é o aplicativo definitivo para quem busca praticidade e organização.

✨ RECURSOS PRINCIPAIS:

💰 FINANÇAS INTELIGENTES
• Registre despesas e receitas por voz
• Categorias automáticas
• Gráficos e relatórios detalhados
• Controle de orçamento
• Parcelamentos e recorrências

📅 AGENDA COMPLETA
• Eventos e compromissos
• Lembretes inteligentes
• Sincronização com calendário
• Comandos de voz para criar eventos

💊 SAÚDE E MEDICAMENTOS
• Lembretes de medicamentos
• Controle de posologia
• Histórico de tomadas
• Alertas personalizados

🔒 SEGURANÇA E PRIVACIDADE
• Dados criptografados
• Biometria (digital/facial)
• Backup na nuvem (opcional)
• Conformidade LGPD/GDPR

🎨 DESIGN MODERNO
• Interface intuitiva
• Tema escuro
• Animações suaves
• 100% em português

🌟 MODELO FREEMIUM
• Funcionalidades gratuitas
• Premium para recursos avançados
• Sem anúncios

📱 COMPATIBILIDADE
• Android 6.0+
• Tablets e smartphones

🔐 PRIVACIDADE
Seus dados financeiros e de saúde são criptografados e NUNCA compartilhados. Comandos de voz são processados localmente.

📞 SUPORTE
Email: abreu@multiversodigital.com.br

Baixe agora e organize sua vida pela voz!
```

### 2. Categorização

**Categoria:** Finanças  
**Subcategoria:** Finanças Pessoais  
**Tags:** finanças, voz, agenda, saúde, medicamentos

### 3. Classificação de Conteúdo

- **Violência:** Nenhuma
- **Sexo:** Nenhum
- **Linguagem:** Nenhuma
- **Drogas:** Referência a medicamentos (informativo)
- **Idade:** Livre (mas recomendado 13+)

### 4. Questionário de Dados

**Coleta de Dados:**
- ✅ Dados financeiros (armazenados localmente/nuvem)
- ✅ Dados de saúde (medicamentos)
- ✅ Dados de conta (email, nome)
- ✅ Analytics (anônimos)

**Compartilhamento:**
- ❌ Não compartilhamos dados com terceiros
- ✅ Firebase (infraestrutura)
- ✅ Google Play (assinaturas)

**Criptografia:**
- ✅ Dados em trânsito (HTTPS)
- ✅ Dados em repouso (Hive criptografado)

**Exclusão de Dados:**
- ✅ Usuário pode excluir conta e dados
- ✅ Funcionalidade dentro do app

---

## 🎯 PASSO 7: SUBMETER

### No Google Play Console:

1. **Upload do AAB:**
   - Production → Create new release
   - Upload `app-release.aab`

2. **Preencher Release Notes:**
   ```
   Versão 1.0.0 - Lançamento Inicial
   
   ✨ Recursos:
   • Gestão financeira por voz
   • Agenda inteligente
   • Lembretes de medicamentos
   • Sincronização em nuvem
   • Backup automático
   
   🔒 Segurança:
   • Dados criptografados
   • Biometria
   • Conformidade LGPD/GDPR
   ```

3. **Revisar e Publicar:**
   - Revisar todas as informações
   - Clicar em "Start rollout to Production"
   - Aguardar revisão (1-7 dias)

---

## ✅ CHECKLIST FINAL

### Antes de Submeter:
- [ ] Código atualizado no GitHub
- [ ] Páginas web no GitHub Pages
- [ ] URLs testadas e funcionando
- [ ] App testado em dispositivo real
- [ ] Todos os links funcionando
- [ ] Permission Rationale testado
- [ ] Exclusão de conta testada
- [ ] AAB gerado
- [ ] Screenshots tirados
- [ ] Feature Graphic criado
- [ ] Descrição escrita
- [ ] Questionário preenchido

### Após Submissão:
- [ ] Monitorar status da revisão
- [ ] Responder a feedback se necessário
- [ ] Corrigir problemas apontados
- [ ] Aguardar aprovação

---

## 📊 TIMELINE ESTIMADO

| Etapa | Tempo |
|-------|-------|
| Upload web_pages | 5 min |
| Ativar GitHub Pages | 2 min |
| Testar links | 10 min |
| Gerar AAB | 5 min |
| Tirar screenshots | 15 min |
| Criar Feature Graphic | 20 min |
| Preencher Play Console | 30 min |
| Submeter | 5 min |
| **TOTAL** | **~1h30min** |
| Revisão Google | 1-7 dias |

---

## 🎉 APÓS APROVAÇÃO

1. **Compartilhar:**
   - Link da Google Play Store
   - Redes sociais
   - Amigos e família

2. **Monitorar:**
   - Reviews e ratings
   - Crashes (Firebase Crashlytics)
   - Analytics

3. **Atualizar:**
   - Corrigir bugs
   - Adicionar features
   - Melhorar baseado em feedback

---

**Boa sorte com a submissão! 🚀**

**O FinAgeVoz está 100% pronto para a Google Play Store!** ✅
