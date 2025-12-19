import 'package:fin_age_voz/services/ai_service.dart';
import 'package:fin_age_voz/services/voice_service.dart';
import 'package:fin_age_voz/services/bi_service.dart'; // Add Import
import '../services/agenda_repository.dart';
import '../models/agenda_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';

import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../utils/installment_helper.dart';

/// Controller that orchestrates Voice -> AI -> Action flow.
class VoiceController {
  final VoiceService _voiceService;
  final AIService _aiService;
  final AgendaRepository _agendaRepo;
  final BIService _biService; // Add Field
  final DatabaseService _dbService = DatabaseService(); // Initialize DB Service
  final VoidCallback? onProcessingStart;
  final VoidCallback? onProcessingEnd;
  final Function(AgendaItem)? onNavigateToForm;
  
  // State for conversational queries
  AgendaItemType? _pendingQueryType;
  String? _pendingQueryKeywords;
  
  VoiceController({
    VoiceService? voiceService,
    AIService? aiService,
    AgendaRepository? agendaRepo,
    BIService? biService,
    this.onProcessingStart,
    this.onProcessingEnd,
    this.onNavigateToForm,
  })  : _voiceService = voiceService ?? VoiceService(),
        _aiService = aiService ?? AIService(),
        _agendaRepo = agendaRepo ?? AgendaRepository(),
        _biService = biService ?? BIService(); // Initialize

  String t(String key) {
    return AppLocalizations.t(key, _dbService.getLanguage()); // Use instance
  }

  Future<void> processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    onProcessingStart?.call();

    try {
      // PRE-PROCESSING: Local greeting detection (fallback before AI)
      final textLower = text.toLowerCase().trim();
      final greetings = ['bom dia', 'boa tarde', 'boa noite', 'olá', 'oi', 'hey'];
      
      if (greetings.any((g) => textLower == g || textLower.startsWith('$g '))) {
        // Direct greeting detected - generate briefing
        await _handleGreeting(textLower);
        onProcessingEnd?.call();
        return;
      }

      // 1. Intent & Entity Extraction (via AI)
      final result = await _aiService.processCommand(text);
      print('AI Process Result: $result');

      final intent = result['intent'];

      if (intent == 'ADD_TRANSACTION') {
        await handleTransaction(result['transaction']);
      } else if (intent == 'ADD_AGENDA_ITEM') {
        await handleAgendaItem(result['agenda_item']);
      } else if (intent == 'QUERY') {
        await handleQuery(result['query']);
      } else if (intent == 'CHAT' || intent == 'GREETING') { // Handle Conversational intents
         final message = result['message'] ?? result['response'] ?? t('voice_cmd_received');
         await _voiceService.speak(message);
      } else if (intent == 'UNKNOWN') {
         // Fallback: If AI returned a 'message' even with UNKNOWN intent (common in weak models), speak it.
         if (result['message'] != null) {
            await _voiceService.speak(result['message']);
         } else {
            await _voiceService.speak(t('voice_not_understood'));
         }
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

  Future<void> handleTransaction(Map<String, dynamic>? data) async {
    if (data == null) return;
    
    try {
       await _dbService.init(); // Ensure initialized
       
       final description = data['description'] ?? "Transação por Voz";
       final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
       final isExpense = data['isExpense'] == true;
       // isPaid defaults: 
       // If explicitly provided in JSON, use it.
       // Else if expense -> default true (conservative, usually past expense) - BUT prompt says default depends on date.
       // Let's rely on JSON 'isPaid' if present.
       // If absent, check date: Future -> false, Past/Today -> true.
       
       DateTime date;
       if (data['date'] != null) {
          try { date = DateTime.parse(data['date']); } catch (_) { date = DateTime.now(); }
       } else {
          date = DateTime.now();
       }

       bool isPaid;
       if (data['isPaid'] != null) {
          isPaid = data['isPaid'] == true;
       } else {
           // Fallback logic
           final now = DateTime.now();
           final isFuture = date.isAfter(now) && !DateUtils.isSameDay(date, now);
           isPaid = !isFuture;
       }
       
       // Categories
       final category = data['category'] ?? (isExpense ? 'Outras Despesas' : 'Outras Receitas');
       final subcategory = data['subcategory'];
       
       // Installments / Recurrence
       int installments = (data['installments'] as int?) ?? 1;
       final recurrence = data['recurrence'] as String?;
       
       // If recurrence is MONTHLY and installments is 1, maybe it implies infinite?
       if (recurrence == 'MONTHLY' && installments == 1) {
           installments = 12; // Default to 1 year for monthly recurrence without count
       }
       
       if (installments > 1) {
           // Create Installments
           final firstDate = date; // AI Date is start date
           // For Income (Aluguel), start date is M0. For Expense (Card), usually M+1.
           // However, if user said "Aluguel dia 10", and it is day 10, they expect it to be 1st installment.
           // InstallmentHelper.createInstallments logic:
           // If downPayment=0, it generates installments starting from firstInstallmentDate?
           // No, createInstallments generates installments starting from firstInstallmentDate as M0?
           // Let's check InstallmentHelper logic again.
           // Loop i=0; date = firstDate + i months.
           // So yes, first installment is AT firstInstallmentDate.
           
           final items = InstallmentHelper.createInstallments(
              description: description,
              totalAmount: null, // Allow installmentValue to drive total
              installmentValue: amount, // Assuming "Amount" spoken is per installment (e.g. "Aluguel de 3000")
              installments: installments,
              firstInstallmentDate: firstDate,
              category: category,
              subcategory: subcategory,
              isExpense: isExpense,
              downPayment: (data['downPayment'] as num?)?.toDouble() ?? 0.0,
           );
           
           for (var t in items) {
               await _dbService.addTransaction(t);
           }
           
           await _voiceService.speak("Agendado ${isExpense ? 'pagamento' : 'recebimento'} de $installments parcelas de $amount reais.");
           
       } else {
           // Single Transaction
           final t = Transaction(
              id: const Uuid().v4(),
              description: description,
              amount: amount,
              isExpense: isExpense,
              date: date,
              category: category,
              subcategory: subcategory,
              isPaid: isPaid,
              paymentDate: isPaid ? date : null,
           );
           
           await _dbService.addTransaction(t);
           
           final type = isExpense ? "Despesa" : "Receita";
           final status = isPaid ? "registrada" : "agendada";
           await _voiceService.speak("$type de $amount reais $status com sucesso.");
       }
       
    } catch (e) {
       print("Transaction creation error: $e");
       await _voiceService.speak("Erro ao criar transação.");
    }
  }

  Future<void> handleQuery(Map<String, dynamic>? queryData) async {
    if (queryData == null) {
      await _voiceService.speak(t('voice_search_error'));
      return;
    }

    final domain = (queryData['domain'] as String?)?.toUpperCase() ?? 'AGENDA';
    String? keywords = queryData['keywords'] as String?;
    // parse date
    final dateStr = queryData['date'] as String?;
    final granularity = (queryData['granularity'] as String?)?.toUpperCase();
    final typeStr = (queryData['type'] as String?)?.toUpperCase();
    
    // FINANCE BI QUERY
    if (domain == 'FINANCE') {
       try {
         final response = await _biService.processQuery(queryData);
         await _voiceService.speak(response);
       } catch (e) {
         print("BI Error: $e");
         await _voiceService.speak("Desculpe, tive um erro ao calcular isso.");
       }
       return;
    }
    
    // AGENDA SEARCH
    if (domain == 'AGENDA') {
       DateTime? date;
       if (dateStr != null) {
         try { date = DateTime.parse(dateStr); } catch (_) {}
       }
       
       AgendaItemType? type;
       if (typeStr != null) {
          try {
             type = AgendaItemType.values.firstWhere(
               (e) => e.toString().split('.').last == typeStr || 
                      (typeStr.contains('ANIVERSARIO') && e == AgendaItemType.ANIVERSARIO) ||
                      (typeStr.contains('REMEDIO') && e == AgendaItemType.REMEDIO)
             );
          } catch (_) {
             if (typeStr.contains('REMEDIO')) type = AgendaItemType.REMEDIO;
          }
       }
       
       // FALLBACK: Context Merge
       // If we have a pending context (e.g. user was asked for date) and current query implies no type change,
       // merge the previous specific type/keywords.
       if (_pendingQueryType != null && type == null) {
           print("DEBUG: Restoring pending context: $_pendingQueryType");
           type = _pendingQueryType;
           // Only restore keywords if they are generic or empty in current?
           // Actually, if user said "Janeiro", keywords is null.
           if (keywords == null) keywords = _pendingQueryKeywords;
           
           // Clear pending once used
           _pendingQueryType = null;
           _pendingQueryKeywords = null;
       }
       
       // Fallback: Infer type from keywords if type is still missing
       if (type == null && keywords != null) {
          final k = keywords!.toLowerCase();
          if (k.contains('aniversario') || k.contains('aniversário')) {
             type = AgendaItemType.ANIVERSARIO;
          } else if (k.contains('remedio') || k.contains('remédio')) {
             type = AgendaItemType.REMEDIO;
          } else if (k.contains('pagamento') || k.contains('conta') || k.contains('vencimento')) {
             type = AgendaItemType.PAGAMENTO;
          }
       }

       // Rule: If date/granularity is missing, ask for clarification.
       // User Request: "se não falar o mes/ano o agente tem que perguntar."
       bool hasDate = date != null || granularity != null;
       bool hasKeywords = keywords != null && keywords.trim().isNotEmpty;
       
       if (!hasDate) {
           // Save context for follow-up
           _pendingQueryType = type;
           _pendingQueryKeywords = keywords;
           print("DEBUG: Saving pending context: $type");
           
           await _voiceService.speak(t('voice_specify_date'));
           return;
       }

       bool matchDay = true;
       bool matchMonth = true;
       bool matchYear = true;

       if (granularity == 'MONTH') {
           matchDay = false;
       } else if (granularity == 'YEAR') {
           matchDay = false;
           matchMonth = false;
       }
       
       // Special rule: if searching for birthdays, year doesn't matter (usually)
       if (type == AgendaItemType.ANIVERSARIO) {
           // matchYear = false; // logic already in repo
       }
       
       print("DEBUG searching: kw=$keywords, date=$date, gran=$granularity, type=$type");
       final results = _agendaRepo.search(
          texto: keywords, 
          tipo: type,
          data: date,
          matchDay: matchDay,
          matchMonth: matchMonth,
          matchYear: matchYear
       );
       
       if (results.isEmpty) {
         String msg = t('voice_search_empty');
         if (keywords != null) msg += "${t('voice_search_about')}$keywords";
         if (date != null) msg += t('voice_search_date');
         msg += ".";
         await _voiceService.speak(msg);
       } else {
         final count = results.length;
         
         // Persona Response Logic
         String intro = "";
         if (count < 3) {
             intro = "Hoje está tranquilo! Você tem apenas $count compromissos."; // "Today is easy"
         } else if (count <= 5) {
             intro = "Você tem $count compromissos na agenda.";
         } else {
             intro = "Dia cheio! Encontrei $count itens.";
         }
         
         // If generic query "Como está meu dia", use this intro.
         // If specific search "Aniversarios", keep standard "Encontrei X".
         // Heuristic: If keywords are empty or very broad, use Persona.
         bool usePersona = keywords == null || keywords.isEmpty || keywords.toLowerCase().contains("agenda") || keywords.toLowerCase().contains("dia");
         
         String msg = usePersona ? intro : "${t('voice_found_many')}$count${t('voice_found_many_suffix')}";
         
         if (usePersona) {
             msg += " O primeiro é";
         }
         
         // Describe items (Limit to 5 to avoid long speech)
         int limit = 5;
         for (int i = 0; i < results.length && i < limit; i++) {
            final item = results[i];
            
            // Format Date
            String dateText = "";
            if (item.dataInicio != null) {
               // Only say date if it's NOT the requested single date (e.g. searching for Month)
               // Simple heuristic: If multiple days involved in results, say date.
               // For now, always say day just in case unless it's today?
               dateText = DateFormat('dd').format(item.dataInicio!);
            }
            
            final timeFormatted = item.horarioInicio ?? "";
            
            if (i > 0) msg += i == results.length - 1 || i == limit - 1 ? " e " : ", ";
            
            msg += " ${item.titulo}";
            
            // Contextualize date speaking
            // If granularity is DAY, dont repeat date for every item?
            // "Dentista às 10, Almoço às 12..." is better than "Dentista dia 18 às 10..."
            if (granularity != 'DAY' && dateText.isNotEmpty) {
                 msg += " dia $dateText";
            }
            
            if (item.tipo != AgendaItemType.ANIVERSARIO && timeFormatted.isNotEmpty) {
               msg += " às $timeFormatted";
            }
         }
         
         if (results.length > limit) {
             msg += " e outros ${results.length - limit}.";
         }
         
         // Offer to read details? (As per user suggestion: "Quer que eu leia os detalhes?")
         // This implies conversational flow. For now, we JUST read them (simpler).
         // "O primeiro é Dentista às 10h..." -> Done above.
         
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
         
         // Trigger Navigation to Form for complete posology
         await _voiceService.speak("Remédio ${title} registrado. Vou abrir o formulário para você completar a posologia.");
         onNavigateToForm?.call(item);
         return; // Stop here, don't save yet
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

  Future<void> _handleGreeting(String greeting) async {
    await _dbService.init();
    
    // Base greeting response
    String response = "";
    
    if (greeting.contains('bom dia')) {
      response = "Bom dia! ";
    } else if (greeting.contains('boa tarde')) {
      response = "Boa tarde! ";
    } else if (greeting.contains('boa noite')) {
      response = "Boa noite! ";
    } else {
      response = "Olá! ";
    }
    
    // Check if Morning Briefing is enabled
    final briefingEnabled = _dbService.getAiMorningBriefingEnabled();
    
    if (briefingEnabled && greeting.contains('bom dia')) {
      response += "Espero que tenha descansado bem. ";
      
      // Add weather simulation if enabled
      if (_dbService.getAiIncludeWeather()) {
        response += "A previsão para hoje é de sol com algumas nuvens, perfeito para resolver suas pendências. ";
      }
      
      // Add horoscope if enabled and birth date is set
      if (_dbService.getAiIncludeHoroscope()) {
        final birthDate = _dbService.getUserBirthDate();
        if (birthDate != null) {
          // Import zodiac utils at top of file if not already
          final sign = _getZodiacSign(birthDate);
          final luckyNumbers = _generateLuckyNumbers();
          response += "Para $sign, o dia promete oportunidades em finanças. ";
          response += "Seus números da sorte são: $luckyNumbers. ";
        } else {
          response += "Configure sua data de nascimento nas configurações para receber seu horóscopo personalizado. ";
        }
      }
      
      // Add historical fact if enabled
      if (_dbService.getAiIncludeHistory()) {
        response += "Curiosidade: Hoje na história, muitas coisas importantes aconteceram. ";
      }
    } else {
      response += "Como posso ajudar você hoje?";
    }
    
    await _voiceService.speak(response);
  }

  String _getZodiacSign(DateTime birthDate) {
    int day = birthDate.day;
    int month = birthDate.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Áries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Touro";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gêmeos";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Câncer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leão";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgem";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Escorpião";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagitário";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricórnio";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquário";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Peixes";
    return "Desconhecido";
  }

  String _generateLuckyNumbers() {
    final numbers = <int>{};
    final rng = DateTime.now().millisecondsSinceEpoch; // Simple seed
    var seed = rng;
    
    while (numbers.length < 6) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      numbers.add((seed % 60) + 1);
    }
    
    final sortedList = numbers.toList()..sort();
    return sortedList.map((n) => n.toString().padLeft(2, '0')).join(', ');
  }
}
