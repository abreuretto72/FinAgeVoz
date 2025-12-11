import 'dart:io';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/agenda_models.dart';
import '../services/agenda_repository.dart';

class GoogleCalendarService {
  final AgendaRepository _repo = AgendaRepository();
  
  // Escopos necessários para Google Calendar
  static const List<String> _scopes = [
    calendar.CalendarApi.calendarReadonlyScope,
  ];

  // Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  calendar.CalendarApi? _calendarApi;
  GoogleSignInAccount? _currentUser;

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => _currentUser != null;

  /// Obtém o email do usuário autenticado
  String? get userEmail => _currentUser?.email;

  /// Autentica o usuário com Google
  Future<Map<String, dynamic>> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {
          'success': false,
          'error': 'Autenticação cancelada pelo usuário'
        };
      }

      _currentUser = account;

      // Obtém credenciais de autenticação
      final auth = await account.authentication;
      
      if (auth.accessToken == null) {
        return {
          'success': false,
          'error': 'Falha ao obter token de acesso'
        };
      }

      // Cria cliente HTTP autenticado
      final authHeaders = await account.authHeaders;
      final authenticatedClient = _GoogleAuthClient(authHeaders);

      _calendarApi = calendar.CalendarApi(authenticatedClient);
      
      return {
        'success': true,
        'email': account.email,
      };
    } catch (e) {
      print('Erro na autenticação: $e');
      return {
        'success': false,
        'error': 'Erro ao conectar com Google: $e'
      };
    }
  }

  /// Desconecta o usuário
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  /// Importa eventos do Google Calendar
  Future<Map<String, dynamic>> importEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_calendarApi == null) {
      return {
        'success': false,
        'imported': 0,
        'ignored': 0,
        'error': 'Usuário não autenticado. Faça login primeiro.'
      };
    }

    int imported = 0;
    int ignored = 0;
    List<String> errors = [];

    try {
      // Define período padrão se não especificado
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));

      // Busca eventos do calendário principal
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100, // Limita a 100 eventos por vez
      );

      if (events.items == null || events.items!.isEmpty) {
        return {
          'success': true,
          'imported': 0,
          'ignored': 0,
          'message': 'Nenhum evento encontrado no período selecionado'
        };
      }

      // Obtém eventos existentes para verificar duplicatas
      final existingItems = _repo.getAll();

      // Processa cada evento
      for (var event in events.items!) {
        try {
          // Verifica se já existe
          if (_isDuplicate(event, existingItems)) {
            ignored++;
            continue;
          }

          // Converte e salva
          final agendaItem = _convertToAgendaItem(event);
          if (agendaItem != null) {
            _repo.addItem(agendaItem);
            imported++;
          } else {
            ignored++;
            errors.add('Evento "${event.summary}" ignorado: dados insuficientes');
          }
        } catch (e) {
          print('Erro ao processar evento ${event.summary}: $e');
          ignored++;
          errors.add('Erro ao processar "${event.summary}": $e');
        }
      }

      return {
        'success': true,
        'imported': imported,
        'ignored': ignored,
        'errors': errors,
      };
    } catch (e) {
      print('Erro ao importar eventos: $e');
      return {
        'success': false,
        'imported': imported,
        'ignored': ignored,
        'error': 'Falha ao importar eventos: $e',
        'errors': errors,
      };
    }
  }

  /// Verifica se o evento já existe na agenda interna
  bool _isDuplicate(calendar.Event event, List<AgendaItem> existingItems) {
    // Primeiro verifica por googleEventId
    if (event.id != null) {
      final existsByGoogleId = existingItems.any(
        (item) => item.googleEventId == event.id
      );
      if (existsByGoogleId) return true;
    }

    // Verifica por título e data
    final eventTitle = event.summary ?? '';
    final eventStart = _parseEventDate(event.start);

    if (eventStart == null || eventTitle.isEmpty) return false;

    return existingItems.any((item) {
      // Compara título (case-insensitive)
      final sameTitle = item.titulo.toLowerCase() == eventTitle.toLowerCase();
      
      // Compara data/hora de início
      final sameDate = item.dataInicio != null &&
          item.dataInicio!.year == eventStart.year &&
          item.dataInicio!.month == eventStart.month &&
          item.dataInicio!.day == eventStart.day &&
          item.dataInicio!.hour == eventStart.hour &&
          item.dataInicio!.minute == eventStart.minute;

      return sameTitle && sameDate;
    });
  }

  /// Converte evento do Google Calendar para AgendaItem
  AgendaItem? _convertToAgendaItem(calendar.Event event) {
    final title = event.summary;
    if (title == null || title.isEmpty) {
      return null; // Ignora eventos sem título
    }

    final startDate = _parseEventDate(event.start);
    final endDate = _parseEventDate(event.end);

    if (startDate == null) {
      return null; // Ignora eventos sem data
    }

    // Verifica se é evento de aniversário (recorrência anual)
    final isAnnualRecurring = event.recurrence?.any(
      (rule) => rule.toUpperCase().contains('FREQ=YEARLY')
    ) ?? false;

    if (isAnnualRecurring && title.toLowerCase().contains('aniversário')) {
      // Cria item de aniversário
      final name = title.replaceAll(
        RegExp(r'aniversário:?\s*', caseSensitive: false), 
        ''
      ).trim();
      
      return AgendaItem(
        tipo: AgendaItemType.ANIVERSARIO,
        titulo: name.isNotEmpty ? name : title,
        dataInicio: startDate,
        aniversario: AniversarioInfo(
          nomePessoa: name.isNotEmpty ? name : title,
          dataNascimento: startDate,
          notificarAntes: 1,
          permitirEnvioCartao: false,
        ),
        googleEventId: event.id,
      );
    }

    // Cria compromisso normal
    return AgendaItem(
      tipo: AgendaItemType.COMPROMISSO,
      titulo: title,
      descricao: event.description,
      dataInicio: startDate,
      dataFim: endDate ?? startDate.add(const Duration(hours: 1)),
      status: ItemStatus.PENDENTE,
      recorrencia: _parseRecurrence(event.recurrence),
      googleEventId: event.id,
    );
  }

  /// Parse da data do evento (suporta dateTime e date)
  DateTime? _parseEventDate(calendar.EventDateTime? eventDate) {
    if (eventDate == null) return null;

    if (eventDate.dateTime != null) {
      return eventDate.dateTime!.toLocal();
    }

    if (eventDate.date != null) {
      // Evento de dia inteiro - date já é DateTime
      return eventDate.date!;
    }

    return null;
  }

  /// Parse de regras de recorrência
  RecorrenciaInfo? _parseRecurrence(List<String>? recurrenceRules) {
    if (recurrenceRules == null || recurrenceRules.isEmpty) {
      return null;
    }

    final rule = recurrenceRules.first.toUpperCase();

    String frequencia;
    if (rule.contains('FREQ=DAILY')) {
      frequencia = 'DIARIO';
    } else if (rule.contains('FREQ=WEEKLY')) {
      frequencia = 'SEMANAL';
    } else if (rule.contains('FREQ=MONTHLY')) {
      frequencia = 'MENSAL';
    } else if (rule.contains('FREQ=YEARLY')) {
      frequencia = 'ANUAL';
    } else {
      frequencia = 'CUSTOM';
    }

    return RecorrenciaInfo(
      frequencia: frequencia,
      intervalo: 1,
    );
  }

  /// Lista calendários disponíveis
  Future<List<Map<String, String>>> listCalendars() async {
    if (_calendarApi == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      final calendarList = await _calendarApi!.calendarList.list();
      return (calendarList.items ?? []).map((cal) => {
        'id': cal.id ?? '',
        'name': cal.summary ?? 'Sem nome',
        'description': cal.description ?? '',
      }).toList();
    } catch (e) {
      print('Erro ao listar calendários: $e');
      return [];
    }
  }
}

/// Cliente HTTP autenticado para Google APIs
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
