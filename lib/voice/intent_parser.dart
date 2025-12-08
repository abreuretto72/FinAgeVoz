import '../services/ai_service.dart';

/// Handles intent parsing logic.
/// Currently wraps AIService, but allows for regex optimizations in future.
class IntentParser {
  final AIService _aiService;

  IntentParser({AIService? aiService}) : _aiService = aiService ?? AIService();

  Future<Map<String, dynamic>> parse(String text) async {
    return await _aiService.processCommand(text);
  }
}
