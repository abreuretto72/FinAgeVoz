# Mudança de Título e Plano de Integração Google Calendar

## ✅ Fase 1: Renomeação (CONCLUÍDO)

### Mudanças Aplicadas

**Arquivo**: `lib/utils/localization.dart`

```dart
// ANTES
'nav_agenda': "Agenda",

// DEPOIS  
'nav_agenda': "Agenda do Google",
```

### Locais Afetados
- ✅ Barra de navegação inferior (BottomNavigationBar)
- ✅ Menu lateral (Drawer)
- ✅ Títulos de telas
- ✅ Referências em código

### Status
- ✅ **Hot Reload Aplicado**: 22 bibliotecas recarregadas
- ✅ **Título Atualizado**: Visível na interface
- ✅ **Sem Erros**: Compilação bem-sucedida

## 📋 Fase 2: Integração Google Calendar (PLANEJAMENTO)

### Documento Criado
**`GOOGLE_CALENDAR_INTEGRATION_PLAN.md`**

Este documento contém:
- 📐 Arquitetura proposta
- 🔐 Estratégia de autenticação OAuth 2.0
- 🔄 Mapeamento de dados (AgendaItem ↔ Google Event)
- 📊 Fluxo de sincronização bidirecional
- 🧪 Casos de teste
- 📅 Cronograma estimado (8-10 semanas)
- ⚠️ Análise de riscos

### Escopo da Integração

#### Itens a Sincronizar ✅
1. **Compromissos** → Eventos do Google Calendar
   - Eventos únicos
   - Eventos recorrentes
   - Com data/hora de início e fim

2. **Aniversários** → Eventos anuais recorrentes
   - Recorrência anual automática
   - Cor especial no calendário

#### Itens Internos (Não Sincronizar) ⚠️
1. **Remédios** → Gerenciamento interno
   - Lembretes de dosagem
   - Horários específicos
   - *Opcional*: Exportar como eventos recorrentes

2. **Pagamentos** → Decisão pendente
   - *Opção A*: Manter interno
   - *Opção B*: Exportar como lembretes

### Dependências Necessárias

```yaml
# JÁ INSTALADAS ✅
google_sign_in: ^6.3.0
googleapis: ^13.2.0
googleapis_auth: ^1.6.0

# A ADICIONAR
flutter_secure_storage: ^9.0.0  # Para tokens OAuth
```

### Arquitetura Proposta

```
Google Calendar (Nuvem)
         ↓
    OAuth 2.0
         ↓
GoogleCalendarService
         ↓
   Mapeamento de Dados
         ↓
  AgendaRepository
         ↓
     Agenda UI
```

### Próximos Passos

#### Imediatos
1. ✅ Renomear para "Agenda do Google"
2. 📝 Criar plano detalhado (concluído)
3. 🔧 Configurar OAuth 2.0 no Google Cloud Console
4. 👨‍💻 Criar branch separada para desenvolvimento

#### Desenvolvimento (Ordem)
1. **Semana 1-2**: Autenticação OAuth 2.0
2. **Semana 3-4**: Importação de eventos
3. **Semana 5-6**: Exportação de eventos
4. **Semana 7-8**: Sincronização bidirecional
5. **Semana 9-10**: Polimento e testes

## 🎯 Decisões Pendentes

### 1. Remédios no Google Calendar?
**Pergunta**: Exportar lembretes de remédios para o Google Calendar?

**Opção A** (Recomendada): Não exportar
- ✅ Mantém privacidade
- ✅ Evita poluição do calendário
- ❌ Usuário não vê no calendário principal

**Opção B**: Exportar como eventos recorrentes
- ✅ Visibilidade total
- ✅ Lembretes nativos do Google
- ❌ Pode poluir calendário
- ❌ Informações médicas sensíveis

**Sugestão**: Toggle opcional nas configurações

### 2. Pagamentos no Google Calendar?
**Pergunta**: Exportar lembretes de pagamento?

**Opção A**: Manter interno
- ✅ Informações financeiras privadas
- ❌ Sem lembrete no calendário principal

**Opção B**: Exportar com cor especial
- ✅ Lembrete visual
- ✅ Integração com notificações do Google
- ⚠️ Requer cuidado com privacidade

**Sugestão**: Exportar apenas vencimentos, sem valores

## ⚠️ Considerações Importantes

### Complexidade
Esta é uma **refatoração significativa** que envolve:
- Autenticação OAuth 2.0
- Integração com API externa
- Sincronização bidirecional
- Resolução de conflitos
- Gestão de tokens
- Tratamento de erros de rede

### Recomendações
1. **Desenvolvimento Incremental**: Implementar feature por feature
2. **Branch Separada**: Não impactar desenvolvimento principal
3. **Testes Contínuos**: Validar cada etapa
4. **Documentação**: Manter atualizada
5. **Feedback do Usuário**: Beta testing antes de release

### Impacto no Usuário
- ✅ **Positivo**: Sincronização automática com Google
- ✅ **Positivo**: Acesso multiplataforma
- ⚠️ **Atenção**: Requer conta Google
- ⚠️ **Atenção**: Permissões de calendário necessárias

## 📊 Status Atual

| Fase | Status | Progresso |
|------|--------|-----------|
| 1. Renomeação | ✅ Concluído | 100% |
| 2. Planejamento | ✅ Concluído | 100% |
| 3. OAuth Setup | ⏳ Pendente | 0% |
| 4. Importação | ⏳ Pendente | 0% |
| 5. Exportação | ⏳ Pendente | 0% |
| 6. Sincronização | ⏳ Pendente | 0% |
| 7. Testes | ⏳ Pendente | 0% |

## 🚀 Conclusão

A **Fase 1** (renomeação) foi concluída com sucesso. O aplicativo agora exibe "Agenda do Google" em todos os lugares relevantes.

A **Fase 2** (integração) é um projeto complexo que requer:
- ⏰ **Tempo**: 8-10 semanas de desenvolvimento
- 👥 **Recursos**: Desenvolvedor dedicado
- 🧪 **Testes**: Extensivos antes de release
- 📝 **Documentação**: Completa para manutenção

**Recomendação**: Tratar como **projeto separado** com milestone próprio.

---

**Data**: 2025-12-11  
**Status Fase 1**: ✅ CONCLUÍDO  
**Status Fase 2**: 📝 PLANEJAMENTO  
**Hot Reload**: ✅ 22 de 2824 bibliotecas
