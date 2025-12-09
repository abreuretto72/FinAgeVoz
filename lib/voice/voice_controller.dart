import 'package:fin_age_voz/services/ai_service.dart';
import 'package:fin_age_voz/services/voice_service.dart';
import '../services/agenda_repository.dart';
import '../models/agenda_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';

/// Controller that orchestrates Voice -> AI -> Action flow.
class VoiceController {
  final VoiceService _voiceService;
  final AIService _aiService;
  final AgendaRepository _agendaRepo;
  final VoidCallback? onProcessingStart;
  final VoidCallback? onProcessingEnd;
  final Function(AgendaItem)? onNavigateToForm;
  
  VoiceController({
    VoiceService? voiceService,
    AIService? aiService,
    AgendaRepository? agendaRepo,
    this.onProcessingStart,
    this.onProcessingEnd,
    this.onNavigateToForm,
  })  : _voiceService = voiceService ?? VoiceService(),
        _aiService = aiService ?? AIService(),
        _agendaRepo = agendaRepo ?? AgendaRepository();

  String t(String key) {
    return AppLocalizations.t(key, DatabaseService().getLanguage());
  }

  Future<void> processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    onProcessingStart?.call();

    try {
      // 1. Intent & Entity Extraction (via AI)
      final result = await _aiService.processCommand(text);
      print('AI Process Result: $result');

      final intent = result['intent'];

      if (intent == 'ADD_AGENDA_ITEM') {
        await handleAgendaItem(result['agenda_item']);
      } else if (intent == 'QUERY') {
        await handleQuery(result['query']);
      } else if (intent == 'UNKNOWN') {
         await _voiceService.speak(t('voice_not_understood'));
      } else {
         await _voiceService.speak("${t('voice_cmd_received')}$intent");
      }

    } catch (e) {
      print('Voice processing error: $e');
      await _voiceService.speak(t('voice_process_error'));
    } finally {
      onProcessingEnd?.call();
    }
  }

  Future<void> handleQuery(Map<String, dynamic>? queryData) async {
    if (queryData == null) {
      await _voiceService.speak(t('voice_search_error'));
      return;
    }

    final domain = (queryData['domain'] as String?)?.toUpperCase() ?? 'AGENDA';
    final keywords = queryData['keywords'] as String?;
    final dateStr = queryData['date'] as String?;
    
    // AGENDA SEARCH
    if (domain == 'AGENDA') {
       DateTime? date;
       if (dateStr != null) {
         try { date = DateTime.parse(dateStr); } catch (_) {}
       }
       
       print("DEBUG searching: keywords=$keywords, date=$date");
       final results = _agendaRepo.search(texto: keywords, data: date);
       
       if (results.isEmpty) {
         String msg = t('voice_search_empty');
         if (keywords != null) msg += "${t('voice_search_about')}$keywords";
         if (date != null) msg += t('voice_search_date');
         msg += ".";
         await _voiceService.speak(msg);
       } else {
         final count = results.length;
         String msg = count == 1 ? t('voice_found_one') : "${t('voice_found_many')}$count${t('voice_found_many_suffix')}";
         
         // Describe first item
         final first = results.first;
         final dateFormatted = first.dataInicio != null 
             ? DateFormat('dd/MM').format(first.dataInicio!) 
             : "";
         final timeFormatted = first.horarioInicio ?? "";
         
         msg += " ${first.titulo}";
         if (dateFormatted.isNotEmpty) msg += "${t('voice_day')}$dateFormatted";
         if (timeFormatted.isNotEmpty) msg += "${t('voice_at')}$timeFormatted";
         msg += ".";
         
         await _voiceService.speak(msg);
       }
    } else {
      await _voiceService.speak("${t('voice_search_unknown_domain')}$domain.");
    }
  }

  Future<void> handleAgendaItem(Map<String, dynamic>? data) async {
    if (data == null) return;

    try {
      final typeStr = (data['type'] as String).toUpperCase();
      final title = data['title'] as String;
      
      // Parse Types
      AgendaItemType type = AgendaItemType.values.firstWhere(
         (e) => e.toString().split('.').last == typeStr, 
         orElse: () => AgendaItemType.COMPROMISSO
      );

      // Parse Dates
      DateTime? date;
      if (data['date'] != null) {
        try { date = DateTime.parse(data['date']); } catch (_) {}
      }

      // Check Recurrence
      RecorrenciaInfo? recurrence;
      if (data['recurrence'] != null) {
         final recMap = data['recurrence'];
         if (recMap is Map) {
             recurrence = RecorrenciaInfo(
               frequencia: recMap['frequencia'] ?? 'DIARIO',
               intervalo: recMap['intervalo'] as int?,
               diasDaSemana: (recMap['diasDaSemana'] as List?)?.cast<int>(),
             );
         }
      }

      // Create Item
      final item = AgendaItem(
         tipo: type,
         titulo: title,
         descricao: data['description'],
         dataInicio: date,
         horarioInicio: data['time'],
         recorrencia: recurrence,
         status: ItemStatus.PENDENTE,
      );

      // Specifics
      if (type == AgendaItemType.PAGAMENTO) {
         item.pagamento = PagamentoInfo(
           valor: (data['payment_value'] as num?)?.toDouble() ?? 0.0,
           status: 'PENDENTE',
           dataVencimento: date ?? DateTime.now(),
         );
      } else if (type == AgendaItemType.REMEDIO) {
         item.remedio = RemedioInfo(
           nome: title,
           dosagem: data['medicine_dosage'] ?? '',
           frequenciaTipo: recurrence?.frequencia ?? 'HORAS',
           intervalo: recurrence?.intervalo ?? 8,
           inicioTratamento: date ?? DateTime.now(),
         );
      } else if (type == AgendaItemType.ANIVERSARIO) {
         // Create Draft for Form
         String name = data['person_name'] ?? title;
         
         // Clean generic names
         if (name.toLowerCase() == 'aniversário' || 
             name.toLowerCase() == 'novo aniversário' || 
             name.toLowerCase() == 'adicionar aniversário') {
             name = "";
         } else if (name.isNotEmpty) {
             // Capitalize
             name = name[0].toUpperCase() + name.substring(1);
         }
         
         item.aniversario = AniversarioInfo(
           nomePessoa: name,
           parentesco: null, // OBRIGATÓRIO SER NULL PARA FORÇAR USUÁRIO A PREENCHER
           notificarAntes: 1,
         );
         
         if (item.recorrencia == null) {
            item.recorrencia = RecorrenciaInfo(frequencia: 'ANUAL');
         }
         
         // Update title
         item.titulo = name.isNotEmpty ? "Aniversário de $name" : "Novo Aniversário";

         // Trigger Navigation & Stop
         await _voiceService.speak(t('voice_confirm_birthday'));
         onNavigateToForm?.call(item);
         return; 
      }

      await _agendaRepo.addItem(item);
      
      // Feedback
      String feedback = "$title${t('voice_scheduled')}";
      if (recurrence != null) {
         feedback += t('voice_recurrency');
      }
      await _voiceService.speak(feedback);

    } catch (e) {
      print("Item creation error: $e");
      await _voiceService.speak(t('voice_create_error'));
    }
  }
}
