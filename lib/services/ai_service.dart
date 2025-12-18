import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class AIService {
  AIService();

  Future<Map<String, dynamic>> processCommand(String input) async {
    final dbService = DatabaseService();
    final userGroqKey = dbService.getGroqApiKey();

    // IMPORTANTE: Para produção, sempre use Groq API
    // Prioridade:
    // 1. Chave Groq configurada pelo usuário (Menu → Configurações)
    // 2. Chave Groq do .env (padrão para APK de produção)
    
    // 1. Verificar chave configurada pelo usuário
    if (userGroqKey != null && userGroqKey.isNotEmpty) {
      print('AIService: Using user-configured Groq API');
      return _processWithGroq(input, userGroqKey);
    }
    
    // 2. Verificar chave Groq do .env
    final envGroqKey = dotenv.env['GROQ_API_KEY'];
    if (envGroqKey != null && envGroqKey.isNotEmpty) {
      print('AIService: Using Groq API from .env');
      return _processWithGroq(input, envGroqKey);
    }

    // Sem chave API disponível
    print('AIService: No API key configured');
    throw Exception('Nenhuma chave API configurada. Configure uma chave Groq em Configurações.');
  }

  /// Answer a natural language question with context
  Future<String> answerQuestion(String questionPrompt) async {
    final dbService = DatabaseService();
    final userGroqKey = dbService.getGroqApiKey();
    
    String? apiKey;
    
    // Get API key
    if (userGroqKey != null && userGroqKey.isNotEmpty) {
      apiKey = userGroqKey;
    } else {
      final envGroqKey = dotenv.env['GROQ_API_KEY'];
      if (envGroqKey != null && envGroqKey.isNotEmpty) {
        apiKey = envGroqKey;
      }
    }
    
    if (apiKey == null) {
      throw Exception('Nenhuma chave API configurada.');
    }
    
    try {
      await dbService.init();
      final modelName = dbService.getGroqModel();
      
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {'role': 'system', 'content': 'Você é um assistente financeiro prestativo que responde perguntas de forma concisa e natural em português.'},
            {'role': 'user', 'content': questionPrompt}
          ],
          'temperature': 0.3,
          'max_tokens': 200, // Limit response length
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else {
        throw Exception("Groq Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error answering question: $e");
      return "Desculpe, não consegui processar sua pergunta no momento.";
    }
  }

  /// Verifica se o modelo atual está ativo e atualiza se necessário
  /// Retorna o novo modelo se houve atualização, null caso contrário
  Future<String?> verifyAndUpdateModel() async {
    try {
      final dbService = DatabaseService();
      await dbService.init();
      final currentModel = dbService.getGroqModel();
      
      print('AIService: Current model: $currentModel');
      
      // Buscar modelos disponíveis
      final bestModel = await _fetchAvailableGroqModels();
      
      if (bestModel == null) {
        print('AIService: Could not fetch available models');
        return null;
      }
      
      // Se o modelo atual é diferente do melhor disponível, atualizar
      if (currentModel != bestModel) {
        print('AIService: Updating model from $currentModel to $bestModel');
        await dbService.setGroqModel(bestModel);
        return bestModel;
      }
      
      print('AIService: Model is up to date');
      return null;
    } catch (e) {
      print('AIService: Error verifying model: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _processWithGroq(String input, String apiKey) async {
    final dbService = DatabaseService();
    await dbService.init();
    String modelName = dbService.getGroqModel();
    String language = dbService.getLanguage();

    final currentYear = DateTime.now().year;
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final expenseCategories = AppConstants.expenseCategories.join(', ');
    final incomeCategories = AppConstants.incomeCategories.join(', ');
    final expenseSubcategories = jsonEncode(AppConstants.expenseSubcategories);
    final incomeSubcategories = jsonEncode(AppConstants.incomeSubcategories);

    final prompt = _buildPrompt(input, currentYear, currentDate, expenseCategories, incomeCategories, expenseSubcategories, incomeSubcategories, language);

    try {
      final result = await _makeGroqRequest(apiKey, modelName, prompt);
      return result;
    } catch (e) {
      // Check for rate limit error
      if (e.toString().contains("rate_limit_exceeded") || e.toString().contains("429")) {
        print("DEBUG: Rate limit exceeded");
        return {
          "intent": "RATE_LIMIT_ERROR",
          "error": "rate_limit"
        };
      }
      
      if (e.toString().contains("400") || e.toString().contains("404") || e.toString().contains("model_decommissioned")) {
        print("DEBUG: Model might be deprecated. Fetching new config...");
        final newModel = await _fetchRemoteModelConfig();
        if (newModel != null && newModel != modelName) {
          print("DEBUG: Updating model to $newModel");
          await dbService.setGroqModel(newModel);
          // Retry with new model
          return await _makeGroqRequest(apiKey, newModel, prompt);
        }
      }
      print("Groq Exception: $e");
      return {"intent": "UNKNOWN"};
    }
  }

  Future<Map<String, dynamic>> _makeGroqRequest(String apiKey, String model, String prompt) async {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      print("DEBUG: Sending request to Groq with model: $model");
      
      try {
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': 'You are a helpful assistant that outputs JSON only.'},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.1,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 15)); // Timeout de 15 segundos

        print("DEBUG: Groq Response Code: ${response.statusCode}");

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final content = data['choices'][0]['message']['content'];
          print("DEBUG: Groq Content: $content");
          return jsonDecode(content);
        } else {
          throw Exception("Groq Error: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("DEBUG: Network/API Error: $e");
        throw Exception("Erro de conexão ou timeout: $e");
      }
  }

  Future<String?> _fetchRemoteModelConfig() async {
    // Busca diretamente da API do Groq os modelos disponíveis
    return await _fetchAvailableGroqModels();
  }

  /// Busca os modelos disponíveis diretamente da API do Groq
  /// e retorna o melhor modelo Llama disponível
  Future<String?> _fetchAvailableGroqModels() async {
    try {
      final dbService = DatabaseService();
      final apiKey = dbService.getGroqApiKey() ?? dotenv.env['GROQ_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        print('No Groq API key available to fetch models');
        return null;
      }

      final url = Uri.parse('https://api.groq.com/openai/v1/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List;
        
        print('Available Groq models: ${models.length}');
        
        // Priorizar modelos Llama 3.3, depois 3.1, depois outros
        // Preferir modelos "versatile" sobre "specdec"
        final llamaModels = models
            .where((m) => m['id'].toString().contains('llama'))
            .map((m) => m['id'].toString())
            .toList();
        
        print('Llama models found: $llamaModels');
        
        // Ordem de prioridade
        final priorities = [
          'llama-3.3-70b-versatile',
          'llama-3.3-70b-specdec',
          'llama-3.1-70b-versatile',
          'llama-3.1-70b-specdec',
          'llama-3.1-8b-instant',
        ];
        
        for (var priority in priorities) {
          if (llamaModels.contains(priority)) {
            print('Selected model: $priority');
            return priority;
          }
        }
        
        // Se nenhum dos prioritários estiver disponível, pegar o primeiro Llama
        if (llamaModels.isNotEmpty) {
          print('Using first available Llama model: ${llamaModels.first}');
          return llamaModels.first;
        }
        
        print('No Llama models found');
        return null;
      } else {
        print('Failed to fetch models: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching Groq models: $e');
      return null;
    }
  }

  String _buildPrompt(String input, int currentYear, String currentDate, String expenseCategories, String incomeCategories, String expenseSubcategories, String incomeSubcategories, String language) {
    String langName = "Portuguese";
    switch (language) {
      case 'pt_BR': langName = "Portuguese (Brazil)"; break;
      case 'pt_PT': langName = "Portuguese (Portugal)"; break;
      case 'es': langName = "Spanish"; break;
      case 'en': langName = "English"; break;
      case 'hi': langName = "Hindi"; break;
      case 'zh': langName = "Chinese (Mandarin)"; break;
      case 'de': langName = "German"; break;
    }

    return '''
    You are an intelligent assistant for a finance and agenda app.
    The user is speaking in $langName.
    Analyze the following user command: "$input"
    
    IMPORTANT: The current year is $currentYear and today's date is $currentDate. When interpreting relative dates like "tomorrow", "next week", etc., use year $currentYear. For dates in the next year (e.g., "January" when it's December), use year ${currentYear + 1}.
    
    CONTEXT - CATEGORIES:
    Expense Categories: $expenseCategories
    Income Categories: $incomeCategories
    
    Expense Subcategories (Map): $expenseSubcategories
    Income Subcategories (Map): $incomeSubcategories
    
    SECTION: RULES FOR TRANSACTIONS
    1. Determine 'isExpense':
       - 'Vou pagar', 'Gastarei', 'Compra', 'Conta' -> isExpense: true
       - 'Vou receber', 'Receberei', 'Renda', 'Aluguel', 'Salário' -> isExpense: false
    
    2. Determine 'isPaid' and 'status' (CRITICAL RULESET):
       
       A. REALIZED EXPENSES (ALREADY PAID) -> isPaid: TRUE
          - User explicitly says past tense verbs: "Gastei", "Comprei", "Paguei", "Já paguei", "Acabei de pagar", "Tive uma despesa".
          - Examples: "Gastei 150 no mercado", "Comprei um tênis", "Paguei a conta de luz", "Já paguei o condomínio".
          - RULE: If user says "Gastei" or "Comprei", it is DONE. Set isPaid: TRUE.
          - DO NOT set isPaid: false for these unless user adds "para pagar depois".
       
       B. FUTURE EXPENSES (TO PAY) -> isPaid: FALSE
          - User explicitly mentions future payment or scheduling: "Vou pagar", "Para pagar", "Agendar", "Vence", "Boleto", "Fatura", "Conta para pagar".
          - Examples: "Registrar conta para pagar dia 15", "Adicionar boleto", "Agendar aluguel", "Lanchar no cartão para pagar depois".
          - Result: isPaid: false.
       
       C. INSTALLMENTS (PURCHASES) cases:
          - "Comprei em X vezes" -> The purchase happened, but payments are future.
          - Rule: If installments > 1, set isPaid: false (Treat as a debt to be paid in installments).
          - Exception: If explicit "Dei entrada", the Down Payment is paid, but the AI should output the global transaction as Pending (isPaid: false).
       
       D. INCOME:
          - "Recebi", "Entrou", "Caiu na conta" -> isPaid: TRUE.
          - "Vou receber", "Para receber", "Agendar recebimento" -> isPaid: FALSE.
       
       E. AMBIGUITY RESOLUTION (When no clear verb is present):
          - If date is FUTURE -> isPaid: false.
          - If date is PAST -> isPaid: true.
          - If date is TODAY -> 
             - If "Conta", "Boleto", "Fatura" -> isPaid: false (implies bill to pay).
             - If "Almoço", "Mercado", "Uber", "Gasolina", "Farmácia" -> isPaid: true (implies immediate consumption).

    3. Determine 'description' (Slot Filling Rule):
       - If the user specifies an Item, use it.
       - If the user DOES NOT specify an Item (e.g., "Gastei 50 reais"), explicitly set "description": null.
       - DO NOT use generic terms like "Despesa", "Gasto", "Compra", "Receita".
       - This allows the App to ask the user "What was the item?".

    4. Determine 'recurrence' and 'installments':
       - "Parcelado em X vezes" -> installments: X.
       - "Todo mês", "Mensal", "Aluguel mensal" -> recurrence: 'MONTHLY'.
       - PATTERN "X parcelas de Y" matches:
          - installments: X
          - installmentAmount: Y
       - PATTERN "Entrada de Z" matches:
          - downPayment: Z
       - 'amount' field: Should be the TOTAL VALUE (downPayment + (installments * installmentAmount)).
       - CRITICAL: Always populate 'installmentAmount' and 'downPayment' if mentioned. Do not merge them.

    Transaction Examples (Strict Adherence):
    
    // TYPE A: Realized Expenses (isPaid: true) - DO NOT SEND TO PAYMENTS TAB
    "Gastei 150 no mercado" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Mercado", "amount": 150.0, "isExpense": true, "isPaid": true, "date": "$currentDate"}}
    "Comprei um tênis hoje" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Tênis", "amount": 0.0, "isExpense": true, "isPaid": true, "date": "$currentDate"}}
    "Paguei a conta de luz" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Conta de Luz", "amount": 0.0, "isExpense": true, "isPaid": true, "date": "$currentDate"}}
    "Tive uma despesa de 80 com táxi" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Táxi", "amount": 80.0, "isExpense": true, "isPaid": true, "date": "$currentDate"}}
    
    // TYPE B: Future Expenses (isPaid: false) - YES, SEND TO PAYMENTS TAB
    "Registrar conta de luz para pagar dia 15" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Conta de Luz", "amount": 0.0, "isExpense": true, "isPaid": false, "date": "$currentYear-MM-15T00:00:00"}}
    "Adicionar boleto de 300 para pagar amanhã" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Boleto", "amount": 300.0, "isExpense": true, "isPaid": false, "date": "tomorrow"}}
    "Agendar o aluguel para pagar dia 10" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Aluguel", "amount": 0.0, "isExpense": true, "isPaid": false, "date": "$currentYear-MM-10T00:00:00"}}
    
    // TYPE C: Installments (isPaid: false)
    "Fiz uma compra parcelada em 10 vezes" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Compra Parcelada", "amount": 0.0, "isExpense": true, "isPaid": false, "installments": 10}}
    "Comprei geladeira, dei 500 de entrada e 5 parcelas de 250" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Geladeira", "amount": 1750.0, "isExpense": true, "isPaid": false, "installments": 5, "downPayment": 500.0, "installmentAmount": 250.0}}
    
    // TYPE D: Income
    "Recebi 500 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": null, "amount": 500.0, "isExpense": false, "isPaid": true, "date": "$currentDate"}}
    "Aluguel para receber dia 10" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Aluguel", "amount": 0.0, "isExpense": false, "isPaid": false, "date": "$currentYear-MM-10T00:00:00"}}
    
    Agenda Rules:
    1. Title Format for meetings/appointments (COMPROMISSO):
       - MANDATORY FORMAT: "Reunião com <Person/Group>" or "Encontro com <Person/Group>".
       - Extract the person/group name from the phrase after "com".
       - Example: "Reunião com João amanhã" -> title: "Reunião com João".
       - Example: "Consulta com Dra. Maria" -> title: "Consulta com Dra. Maria".
       - IF NO PERSON IS MENTIONES (e.g. "Reunião amanhã às 9h"):
         - Set "title": "Reunião" (generic).
         - Set "missing_person": true.

    2. Title Format for Tasks/Reminders (TAREFA) [IMPORTANT: NOT APPLICABLE TO "REMEDIO" type]:
       - MANDATORY FORMAT: "Lembrete: <Content>".
       - Extract the reminder content from the user's phrase.
       - Example: "Me lembre de pagar o IPTU" -> title: "Lembrete: pagar o IPTU".
       - Example: "Lembrete de levar o carro" -> title: "Lembrete: levar o carro".
       - IF NO CONTENT IS SPECIFIED (e.g. "Me lembre amanhã", "Crie um lembrete"):
         - Set "title": "Lembrete" (generic).
         - Set "missing_content": true.
         - This allows the app to ask "What to remind?".

    Agenda Examples (Smart Agenda):
    "Adicionar uma reunião amanhã às 9 da manhã com o João" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "COMPROMISSO", "title": "Reunião com João", "date": "$currentYear-11-23T09:00:00", "time": "09:00", "description": "Com João"}}
    "Reunião amanhã às 15h" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "COMPROMISSO", "title": "Reunião", "date": "$currentYear-11-23T15:00:00", "time": "15:00", "missing_person": true}}
    "Encontro com a equipe de vendas dia 10" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "COMPROMISSO", "title": "Encontro com Equipe de Vendas", "date": "$currentYear-MM-10T09:00:00"}}
    "Me lembra de tomar remédio às 8" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "REMEDIO", "title": "Tomar remédio", "date": "$currentYear-11-22T20:00:00", "time": "20:00"}}
    "Registrar pagamento da internet no dia 5, valor 120 reais" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "PAGAMENTO", "title": "Internet", "date": "$currentYear-12-05T00:00:00", "payment_value": 120.0}}
    "Agendar aniversário da minha mãe dia 12 de agosto" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "ANIVERSARIO", "title": "Aniversário da mãe", "person_name": "Mãe", "relationship": "Mãe", "date": "$currentYear-08-12T00:00:00"}}
    "Aniversário de Mara 10 de Março" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "ANIVERSARIO", "title": "Aniversário de Mara", "person_name": "Mara", "date": "$currentYear-03-10T00:00:00"}}
    
    // REMINDERS
    "Me lembre de pagar o IPTU amanhã" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Lembrete: pagar o IPTU", "date": "tomorrow"}}
    "Criar um lembrete para levar o carro na revisão" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Lembrete: levar o carro na revisão"}}
    "Lembrete: enviar relatório para o João" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Lembrete: enviar relatório para o João"}}
    "Me lembre amanhã às 8" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Lembrete", "date": "tomorrow", "time": "08:00", "missing_content": true}}
    
    "Caminhar todo dia às 7" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Caminhar", "time": "07:00", "recurrence": {"frequencia": "DIARIO", "intervalo": 1}}}
    "Tomar remédio de 8 em 8 horas" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "REMEDIO", "title": "Tomar remédio", "recurrence": {"frequencia": "HORAS", "intervalo": 8}}}
    "Lixo toda segunda às 20h" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "ROTINA", "title": "Colocar lixo", "time": "20:00", "recurrence": {"frequencia": "SEMANAL", "diasDaSemana": [1]}}}
    
    Navigation Examples:
    "Abrir finanças" -> {"intent": "NAVIGATE", "navigation": {"target": "FINANCE"}}
    "Mostrar categorias" -> {"intent": "NAVIGATE", "navigation": {"target": "CATEGORIES"}}
    "Ver categorias" -> {"intent": "NAVIGATE", "navigation": {"target": "CATEGORIES"}}
    "Mostrar os eventos" -> {"intent": "NAVIGATE", "navigation": {"target": "AGENDA"}}
    "Fechar app" -> {"intent": "NAVIGATE", "navigation": {"target": "CLOSE"}}
    "Mostrar relatório de parcelas" -> {"intent": "NAVIGATE", "navigation": {"target": "INSTALLMENTS"}}
    "Listar parcelas a vencer" -> {"intent": "NAVIGATE", "navigation": {"target": "INSTALLMENTS"}}
    "Ver parcelas" -> {"intent": "NAVIGATE", "navigation": {"target": "INSTALLMENTS"}}

    SPECIAL SECTION: BIRTHDAY NLU (Advanced Recognition)
    Identify colloquial phrases related to birthdays/parties/gifts as Birthday Queries.
    
    Patterns to recognize as {"intent": "QUERY", "query": {"domain": "AGENDA", "type": "ANIVERSARIO"}}:
    1. Direct: "Quais são os aniversários de [Mês]?", "Quem faz aniversário?"
    2. Planning (Gifts/Parties): "Preciso comprar presentes em [Mês]?", "Para quem mandar parabéns?", "Tenho festa em [Mês]?", "Devo me preocupar com presente?"
    3. Quantity: "Quantas pessoas fazem anos?", "O mês está cheio de festas?"
    4. Relationship: "Quais clientes fazem aniversário?", "Tem algum aniversário da família?"
    
    RULES:
    - Extract [Mês] and [Ano]. If Year is missing, use $currentYear.
    - Set "granularity": "MONTH" if a month is mentioned.
    - Set "granularity": "YEAR" if only year is mentioned.
    - Set "keywords" if a specific relationship/name is mentioned (e.g. "clientes", "família").
    
    Call Examples:
    "Ligar para João" -> {"intent": "CALL_CONTACT", "contact": {"name": "João"}}
    "Chamar Maria no WhatsApp" -> {"intent": "CALL_CONTACT", "contact": {"name": "Maria"}}
    "Ligar para o Pedro" -> {"intent": "CALL_CONTACT", "contact": {"name": "Pedro"}}

    Query Examples:
    "Quanto gastei com gasolina?" -> {"intent": "QUERY", "query": {"domain": "FINANCE", "keywords": "gasolina"}}
    "Qual meu saldo?" -> {"intent": "QUERY", "query": {"domain": "FINANCE", "keywords": "saldo"}}
    "Tenho algum evento hoje?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "$currentDate", "granularity": "DAY"}}
    "Tem almoço na casa da Teresa?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "keywords": "almoço Teresa"}}
    "Verificar eventos de amanhã" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "$currentYear-11-23T00:00:00", "granularity": "DAY"}}
    "Aniversários em janeiro" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "$currentYear-01-01", "granularity": "MONTH", "type": "ANIVERSARIO", "keywords": null}}
    "Eventos em 2026" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "2026-01-01", "granularity": "YEAR"}}
    "Quantos aniversários tem em janeiro de 2026?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "2026-01-01", "granularity": "MONTH", "type": "ANIVERSARIO"}}
    "O que tenho na agenda de remédios?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "type": "REMEDIO"}}
    "Quais remédios preciso tomar hoje?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "type": "REMEDIO", "date": "$currentDate", "granularity": "DAY"}}
    ''';
  }
}
