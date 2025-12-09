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
    
    INSTRUCTION:
    For "ADD_TRANSACTION" intent, you MUST classify the transaction into one of the provided Categories and Subcategories.
    1. Determine if it is an Expense or Income.
    2. Select the most appropriate Category from the respective list.
    3. Select the most appropriate Subcategory from the map for that Category.
    
    For requests to SHOW, LIST or SEE installments or future payments visually, return "NAVIGATE" with target "INSTALLMENTS".
    For other reports, return "NAVIGATE" with target "REPORTS".

    For QUERIES (checking/searching for events/transactions), return "intent": "QUERY" and fill the "query" object.

    Output JSON format:
    {
      "intent": "ADD_TRANSACTION" | "ADD_EVENT" | "ADD_AGENDA_ITEM" | "NAVIGATE" | "QUERY" | "UNDO" | "CALL_CONTACT" | "UNKNOWN",
      "transaction": {
        "description": "string. REQUIRED.",
        "amount": "number. REQUIRED. If not found, return null.",
        "isExpense": "boolean. true for expense, false for income.",
        "date": "ISO 8601 string (YYYY-MM-DDTHH:mm:ss). Use year $currentYear.",
        "category": "string. From the provided list.",
        "subcategory": "string. From the provided map.",
        "installments": "integer. Default 1.",
        "downPayment": "number. Optional.",
        "installmentAmount": "number. Optional."
      },
      "event": {
        "title": "string. REQUIRED.",
        "date": "ISO 8601 string (YYYY-MM-DDTHH:mm:ss). REQUIRED.",
        "description": "string",
        "recurrence": "string. Optional. 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY' or null."
      },
      "agenda_item": {
        "type": "COMPROMISSO" | "TAREFA" | "LEMBRETE" | "PAGAMENTO" | "REMEDIO" | "ANIVERSARIO" | "META" | "PROJETO" | "NOTA" | "ROTINA" | "PRAZO",
        "title": "string. REQUIRED.",
        "date": "ISO 8601 string (YYYY-MM-DDTHH:mm:ss).",
        "time": "HH:mm string.",
        "description": "string",
        "payment_value": "number (for PAGAMENTO)",
        "medicine_dosage": "string (for REMEDIO)",
        "person_name": "string (for ANIVERSARIO)",
        "relationship": "string (for ANIVERSARIO e.g. 'Mãe', 'Amigo', 'Tia')",
        "recurrence": {
          "frequencia": "DIARIO" | "SEMANAL" | "MENSAL" | "ANUAL" | "HORAS",
          "intervalo": "int (default 1)",
          "diasDaSemana": "List<int> (1=Mon, 7=Sun)"
        }
      },
      "navigation": {
        "target": "FINANCE" | "AGENDA" | "HOME" | "CLOSE" | "REPORTS" | "CATEGORIES" | "INSTALLMENTS"
      },
      "contact": {
        "name": "string. The name of the person to call."
      },
      "query": {
        "domain": "AGENDA" | "FINANCE" | "GENERAL",
        "keywords": "string. Search keywords extracted from the user input.",
        "date": "ISO 8601 string (optional)."
      }
    }
    
    Transaction Examples:
    "Gastei 50 reais na padaria hoje" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Padaria", "amount": 50.0, "isExpense": true, "date": "$currentYear-11-22T08:30:00", "category": "Alimentação", "subcategory": "Supermercado", "installments": 1}}
    "Recebi 1000 reais de salário" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Salário", "amount": 1000.0, "isExpense": false, "date": "$currentYear-11-22T08:30:00", "category": "Renda Principal", "subcategory": "Salário Líquido", "installments": 1}}
    "Comprei TV com entrada de 100 e 10 parcelas de 50 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "TV", "amount": 600.0, "isExpense": true, "date": "$currentYear-11-22T08:30:00", "category": "Imobilizado", "subcategory": "Eletrodomésticos", "installments": 10, "downPayment": 100.0, "installmentAmount": 50.0}}
    "Comprei um celular novo em 10 vezes de 200 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Celular novo", "amount": 2000.0, "isExpense": true, "date": "$currentYear-11-22T08:30:00", "category": "Imobilizado", "subcategory": "Celular", "installments": 10, "installmentAmount": 200.0}}
    "Vendi meu carro por 30000 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Venda do carro", "amount": 30000.0, "isExpense": false, "date": "$currentYear-11-22T08:30:00", "category": "Imobilizado", "subcategory": "Automóvel", "installments": 1}}
    "Gastei 100 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Gasto genérico", "amount": 100.0, "isExpense": true, "date": "$currentYear-11-22T08:30:00", "category": null, "subcategory": null, "installments": 1}}
    "Estornar 50 reais da padaria" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Estorno Padaria", "amount": 50.0, "isExpense": false, "date": "$currentYear-11-22T08:30:00", "category": "Alimentação", "subcategory": "Supermercado", "installments": 1}}
    "Reembolso de 200 reais do médico" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Reembolso Médico", "amount": 200.0, "isExpense": false, "date": "$currentYear-11-22T08:30:00", "category": "Saúde", "subcategory": "Consultas", "installments": 1}}
    "Devolução de compra de 100 reais" -> {"intent": "ADD_TRANSACTION", "transaction": {"description": "Devolução Compra", "amount": 100.0, "isExpense": false, "date": "$currentYear-11-22T08:30:00", "category": "Outros", "subcategory": null, "installments": 1}}
    
    Event Examples:
    "Reunião amanhã às 14h" -> {"intent": "ADD_EVENT", "event": {"title": "Reunião", "date": "$currentYear-11-23T14:00:00", "recurrence": null}}
    "Reunião de equipe toda segunda às 10h" -> {"intent": "ADD_EVENT", "event": {"title": "Reunião de equipe", "date": "$currentYear-11-24T10:00:00", "recurrence": "WEEKLY"}}
    "Pagar conta todo dia 5" -> {"intent": "ADD_EVENT", "event": {"title": "Pagar conta", "date": "$currentYear-12-05T09:00:00", "recurrence": "MONTHLY"}}
    
    Agenda Examples (Smart Agenda):
    "Adicionar uma reunião amanhã às 9 da manhã com o João" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "COMPROMISSO", "title": "Reunião com João", "date": "$currentYear-11-23T09:00:00", "time": "09:00", "description": "Com João"}}
    "Me lembra de tomar remédio às 8" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "REMEDIO", "title": "Tomar remédio", "date": "$currentYear-11-22T20:00:00", "time": "20:00"}}
    "Registrar pagamento da internet no dia 5, valor 120 reais" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "PAGAMENTO", "title": "Internet", "date": "$currentYear-12-05T00:00:00", "payment_value": 120.0}}
    "Agendar aniversário da minha mãe dia 12 de agosto" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "ANIVERSARIO", "title": "Aniversário da mãe", "person_name": "Mãe", "relationship": "Mãe", "date": "$currentYear-08-12T00:00:00"}}
    "Aniversário de Mara 10 de Março" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "ANIVERSARIO", "title": "Aniversário de Mara", "person_name": "Mara", "date": "$currentYear-03-10T00:00:00"}}
    "Criar tarefa comprar ração hoje à tarde" -> {"intent": "ADD_AGENDA_ITEM", "agenda_item": {"type": "TAREFA", "title": "Comprar ração", "date": "$currentYear-11-22T15:00:00", "time": "15:00"}}
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

    Call Examples:
    "Ligar para João" -> {"intent": "CALL_CONTACT", "contact": {"name": "João"}}
    "Chamar Maria no WhatsApp" -> {"intent": "CALL_CONTACT", "contact": {"name": "Maria"}}
    "Ligar para o Pedro" -> {"intent": "CALL_CONTACT", "contact": {"name": "Pedro"}}

    Query Examples:
    "Quanto gastei com gasolina?" -> {"intent": "QUERY", "query": {"domain": "FINANCE", "keywords": "gasolina"}}
    "Qual meu saldo?" -> {"intent": "QUERY", "query": {"domain": "FINANCE", "keywords": "saldo"}}
    "Tenho algum evento hoje?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "$currentDate"}}
    "Tem almoço na casa da Teresa?" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "keywords": "almoço Teresa"}}
    "Verificar eventos de amanhã" -> {"intent": "QUERY", "query": {"domain": "AGENDA", "date": "$currentYear-11-23T00:00:00"}}
    ''';
  }
}
