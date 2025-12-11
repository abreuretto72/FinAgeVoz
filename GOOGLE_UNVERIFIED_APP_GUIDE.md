# Guia: Aviso "Google não verificou este app"

**Data**: 2025-12-11  
**Status**: ✅ Normal para Apps em Desenvolvimento

---

## ⚠️ Mensagem que Aparece

Ao tentar importar da Agenda do Google, você verá:

```
⚠️ O Google não verificou este app

Este app não foi verificado pelo Google ainda.
Prossiga apenas se você confia no desenvolvedor.
```

---

## ✅ Isso é NORMAL!

### Por que aparece?

1. **App em Desenvolvimento**: Ainda não foi publicado na Google Play Store
2. **OAuth não Verificado**: Credenciais de desenvolvimento/teste
3. **Sem Revisão**: Google ainda não revisou o app

### É Seguro Continuar?

**SIM!** Você é o desenvolvedor do app e está testando sua própria funcionalidade.

---

## 📱 Como Proceder (Passo a Passo)

### Tela de Aviso do Google

1. **Aparece o Aviso**
   ```
   ⚠️ O Google não verificou este app
   [Voltar para segurança]
   ```

2. **Clique em "Avançado"** (canto inferior esquerdo)
   ```
   Avançado ▼
   ```

3. **Clique em "Ir para FinAgeVoz (não seguro)"**
   ```
   Ir para FinAgeVoz (não seguro) →
   ```

4. **Autorize as Permissões**
   ```
   FinAgeVoz quer acessar sua Conta do Google
   
   ✓ Ver eventos do calendário
   
   [Cancelar] [Permitir]
   ```

5. **Clique em "Permitir"**

---

## 🔐 Permissões Solicitadas

O app solicita apenas:

- ✅ **Leitura do Calendário** (somente leitura)
- ❌ **NÃO solicita** acesso a emails
- ❌ **NÃO solicita** acesso a contatos
- ❌ **NÃO solicita** outras permissões

---

## 🧪 Após Autorizar

### O que acontece:

1. **Autenticação Completa** ✅
2. **Dialog de Seleção de Período** aparece
3. **Escolha o período** (7, 30, 90 dias ou personalizado)
4. **Importação Automática** dos eventos
5. **Resultado Exibido** com estatísticas

### Exemplo de Resultado:
```
✅ Importação do Google

✅ Eventos importados: 15
⚠️ Ignorados (duplicados): 3
```

---

## 🚀 Para Produção (Futuro)

### Quando Publicar o App

Para remover o aviso permanentemente:

#### 1. Verificação no Google Cloud Console

**Passos**:
1. Acessar [Google Cloud Console](https://console.cloud.google.com)
2. Ir para "OAuth consent screen"
3. Preencher informações do app:
   - Nome do app
   - Logo
   - Política de privacidade
   - Termos de serviço
4. Submeter para verificação
5. Aguardar aprovação (7-14 dias úteis)

**Documentação Necessária**:
- Explicação de uso das permissões
- Vídeo demonstrando o app
- Política de privacidade pública
- Link para download do app

#### 2. Publicação na Play Store

**Após publicar**:
- Google verifica automaticamente
- Aviso desaparece para todos os usuários
- App considerado "verificado"

---

## 📋 Checklist de Verificação

### Para Desenvolvimento (Agora)
- [x] Clicar em "Avançado"
- [x] Clicar em "Ir para FinAgeVoz (não seguro)"
- [x] Autorizar permissões
- [x] Testar importação

### Para Produção (Futuro)
- [ ] Completar OAuth consent screen
- [ ] Adicionar logo do app
- [ ] Publicar política de privacidade
- [ ] Submeter para verificação Google
- [ ] Aguardar aprovação
- [ ] Publicar na Play Store

---

## ❓ FAQ

### P: É seguro clicar em "Avançado"?
**R**: SIM! Você é o desenvolvedor e está testando seu próprio app.

### P: Meus dados estão seguros?
**R**: SIM! O app só acessa o calendário com sua autorização explícita.

### P: Preciso fazer isso toda vez?
**R**: Não. Após autorizar uma vez, o Google lembra da sua escolha.

### P: Como revogar permissões?
**R**: 
1. Ir para [myaccount.google.com/permissions](https://myaccount.google.com/permissions)
2. Encontrar "FinAgeVoz"
3. Clicar em "Remover acesso"

### P: Quando o aviso vai sumir?
**R**: Quando o app for verificado pelo Google (após publicação na Play Store).

---

## 🎯 Resumo

| Situação | Ação | Seguro? |
|----------|------|---------|
| Desenvolvimento | Clicar "Avançado" → "Ir para FinAgeVoz" | ✅ SIM |
| Testes Internos | Clicar "Avançado" → "Ir para FinAgeVoz" | ✅ SIM |
| Produção | Verificar app no Google Cloud | ✅ Necessário |

---

## 📝 Notas Importantes

1. **Aviso é Padrão**: Todos os apps não publicados mostram isso
2. **Não é Erro**: Funcionalidade está correta
3. **Temporário**: Desaparece após verificação
4. **Seguro para Testes**: Pode prosseguir tranquilamente

---

**Desenvolvido por**: Antigravity AI  
**Projeto**: FinAgeVoz  
**Status**: Pronto para Testes
