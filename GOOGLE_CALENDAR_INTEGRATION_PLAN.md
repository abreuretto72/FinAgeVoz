# Plano de Integração: Agenda do Google (Google Calendar API)

## 📋 Visão Geral

Este documento descreve o plano de implementação para integrar o módulo de Agenda do FinAgeVoz com o Google Calendar, substituindo a atual gestão local de eventos por sincronização bidirecional com a API do Google.

## 🎯 Objetivos

1. **Renomear** módulo de "Agenda" para "Agenda do Google"
2. **Implementar** autenticação OAuth 2.0 com Google
3. **Sincronizar** eventos entre FinAgeVoz e Google Calendar
4. **Mapear** tipos de itens da agenda para eventos do Google

## 📝 Status Atual

### ✅ Fase 1: Renomeação (CONCLUÍDO)
- [x] Atualizar `nav_agenda` em localization.dart para "Agenda do Google"
- [ ] Atualizar títulos de telas relacionadas
- [ ] Atualizar documentação

### 🔄 Fase 2: Planejamento (EM ANDAMENTO)
- [x] Documento de planejamento criado
- [ ] Análise de dependências
- [ ] Definição de escopo detalhado

### ⏳ Fase 3: Implementação (PENDENTE)
- [ ] Configuração OAuth 2.0
- [ ] Integração com Google Calendar API
- [ ] Mapeamento de dados
- [ ] Sincronização bidirecional

## 🔧 Arquitetura Proposta

### 1. Autenticação OAuth 2.0

#### Dependências Necessárias
```yaml
dependencies:
  google_sign_in: ^6.3.0  # JÁ INSTALADO
  googleapis: ^13.2.0      # JÁ INSTALADO
  googleapis_auth: ^1.6.0  # JÁ INSTALADO
```

#### Escopos Necessários
```dart
static const List<String> _scopes = [
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events',
];
```

#### Fluxo de Autenticação
1. Usuário clica em "Conectar com Google"
2. OAuth flow solicita permissões
3. Token armazenado localmente (secure storage)
4. Refresh token gerenciado automaticamente

### 2. Serviço de Sincronização

#### Arquivo: `lib/services/google_calendar_service.dart`

```dart
class GoogleCalendarService {
  final GoogleSignIn _googleSignIn;
  final CalendarApi? _calendarApi;
  
  // Importação (Google → FinAgeVoz)
  Future<List<AgendaItem>> importEvents({
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Exportação (FinAgeVoz → Google)
  Future<void> exportEvent(AgendaItem item);
  
  // Sincronização Bidirecional
  Future<SyncResult> syncCalendar();
  
  // Deletar evento
  Future<void> deleteEvent(String googleEventId);
}
```

### 3. Mapeamento de Dados

#### Compromissos → Google Calendar Events

| FinAgeVoz | Google Calendar |
|-----------|-----------------|
| `titulo` | `summary` |
| `dataInicio` | `start.dateTime` |
| `dataFim` | `end.dateTime` |
| `descricao` | `description` |
| `local` | `location` |
| `recorrencia` | `recurrence` (RRULE) |

#### Aniversários → Eventos Anuais Recorrentes

```dart
Event createBirthdayEvent(AniversarioInfo birthday) {
  return Event(
    summary: 'Aniversário: ${birthday.pessoa}',
    start: EventDateTime(date: birthday.data),
    end: EventDateTime(date: birthday.data),
    recurrence: ['RRULE:FREQ=YEARLY'],
    colorId: '9', // Cor especial para aniversários
  );
}
```

#### Remédios → Eventos Recorrentes (Opcional)

**Decisão Pendente**: Exportar lembretes de remédios?

**Opção A**: Não exportar (manter interno)
- Pros: Simplicidade, privacidade
- Cons: Usuário não vê no calendário principal

**Opção B**: Exportar como eventos recorrentes
- Pros: Visibilidade total
- Cons: Pode poluir o calendário

**Recomendação**: Opção A (manter interno) com toggle opcional

#### Pagamentos → Eventos de Lembrete

```dart
Event createPaymentEvent(PagamentoInfo payment) {
  return Event(
    summary: 'Pagamento: ${payment.descricao}',
    start: EventDateTime(date: payment.dataVencimento),
    end: EventDateTime(date: payment.dataVencimento),
    description: 'Valor: ${payment.valor}',
    colorId: '11', // Cor vermelha para pagamentos
    reminders: EventReminders(
      useDefault: false,
      overrides: [
        EventReminder(method: 'popup', minutes: 1440), // 1 dia antes
      ],
    ),
  );
}
```

### 4. Estratégia de Sincronização

#### Sincronização Incremental
```dart
class SyncStrategy {
  // Última sincronização
  DateTime? lastSyncTime;
  
  // Sincronizar apenas mudanças desde última sync
  Future<void> incrementalSync() async {
    final events = await _calendarApi.events.list(
      'primary',
      updatedMin: lastSyncTime?.toIso8601String(),
    );
    
    // Processar apenas eventos modificados
    for (var event in events.items ?? []) {
      await _processEvent(event);
    }
    
    lastSyncTime = DateTime.now();
  }
}
```

#### Resolução de Conflitos
1. **Google tem prioridade**: Se evento modificado em ambos, Google vence
2. **Timestamp**: Usar `updated` do Google Calendar
3. **Soft delete**: Marcar como deletado, não remover

### 5. UI/UX

#### Tela de Configuração de Sincronização

```dart
class GoogleCalendarSettingsScreen extends StatefulWidget {
  // Conectar/Desconectar conta Google
  // Escolher calendário (se múltiplos)
  // Configurar frequência de sync
  // Escolher quais tipos exportar (Compromissos, Aniversários, etc)
}
```

#### Indicadores Visuais
- Badge "Sincronizado" em itens vindos do Google
- Ícone do Google Calendar em eventos sincronizados
- Status de sincronização na AppBar

## 📊 Fluxo de Dados

```
┌─────────────────┐
│  Google Calendar│
│     (Nuvem)     │
└────────┬────────┘
         │
         │ OAuth 2.0
         │ Calendar API
         │
┌────────▼────────┐
│ CalendarService │
│   (Middleware)  │
└────────┬────────┘
         │
         │ Mapeamento
         │
┌────────▼────────┐
│ AgendaRepository│
│   (Local DB)    │
└────────┬────────┘
         │
┌────────▼────────┐
│   Agenda UI     │
└─────────────────┘
```

## 🔐 Segurança e Privacidade

### Armazenamento de Tokens
```dart
// Usar flutter_secure_storage
final storage = FlutterSecureStorage();
await storage.write(key: 'google_refresh_token', value: token);
```

### Permissões Mínimas
- Solicitar apenas escopos necessários
- Explicar claramente o uso dos dados
- Permitir desconexão a qualquer momento

### Política de Privacidade
- Atualizar para mencionar integração com Google
- Explicar que dados são sincronizados
- Informar sobre armazenamento de tokens

## 🧪 Testes

### Casos de Teste

1. **Autenticação**
   - [ ] Login bem-sucedido
   - [ ] Falha de autenticação
   - [ ] Refresh token expirado
   - [ ] Revogação de permissões

2. **Importação**
   - [ ] Importar eventos únicos
   - [ ] Importar eventos recorrentes
   - [ ] Importar eventos de dia inteiro
   - [ ] Lidar com eventos deletados

3. **Exportação**
   - [ ] Exportar compromisso simples
   - [ ] Exportar compromisso recorrente
   - [ ] Exportar aniversário
   - [ ] Atualizar evento existente

4. **Sincronização**
   - [ ] Sync inicial (muitos eventos)
   - [ ] Sync incremental
   - [ ] Resolução de conflitos
   - [ ] Sync offline (queue)

## 📅 Cronograma Estimado

### Semana 1-2: Preparação
- Configurar OAuth 2.0
- Criar GoogleCalendarService básico
- Implementar autenticação

### Semana 3-4: Importação
- Implementar importação de eventos
- Mapear para AgendaItem
- Testar com diferentes tipos de eventos

### Semana 5-6: Exportação
- Implementar exportação
- Criar eventos no Google Calendar
- Testar sincronização unidirecional

### Semana 7-8: Sincronização Bidirecional
- Implementar detecção de mudanças
- Resolução de conflitos
- Testes de integração

### Semana 9-10: Polimento
- UI/UX
- Tratamento de erros
- Documentação
- Testes finais

## ⚠️ Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Quota API excedida | Alto | Implementar cache, limitar requests |
| Token expirado | Médio | Auto-refresh, fallback gracioso |
| Conflitos de dados | Médio | Estratégia clara de resolução |
| Perda de conexão | Baixo | Queue de operações offline |

## 🚀 Próximos Passos Imediatos

1. ✅ **Renomear para "Agenda do Google"** (Concluído)
2. **Criar branch separada** para desenvolvimento
3. **Configurar OAuth 2.0** no Google Cloud Console
4. **Implementar autenticação** básica
5. **Prototipar** importação de 1 evento

## 📚 Recursos

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/v3/reference)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [googleapis package](https://pub.dev/packages/googleapis)
- [google_sign_in package](https://pub.dev/packages/google_sign_in)

---

**Nota**: Esta é uma refatoração significativa que deve ser tratada como um **projeto separado** devido à complexidade. Recomenda-se desenvolvimento incremental com testes contínuos.

**Status**: 📝 Planejamento  
**Prioridade**: 🔴 Alta  
**Complexidade**: 🔴🔴🔴 Muito Alta  
**Tempo Estimado**: 8-10 semanas
