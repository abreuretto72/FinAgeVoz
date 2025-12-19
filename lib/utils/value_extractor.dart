/// Universal Value Extractor for Multi-language Support
/// 
/// This utility extracts monetary values from natural language phrases
/// in ANY language without requiring language-specific examples.
/// 
/// Supports:
/// - Portuguese: "Impressora laser 1500 reais"
/// - English: "Laser printer 1500 dollars"
/// - Spanish: "Impresora láser 1500 pesos"
/// - French: "Imprimante laser 1500 euros"
/// - And ANY other language!
/// 
/// Author: Antigravity AI
/// Date: 2024-12-19

class ValueExtractor {
  /// Extracts monetary value and description from a natural language phrase
  /// 
  /// Returns a Map with:
  /// - 'amount': double? - The extracted monetary value
  /// - 'description': String - The phrase without the value
  /// - 'hasValue': bool - Whether a value was found
  /// - 'originalPhrase': String - The original input
  /// 
  /// Example:
  /// ```dart
  /// final result = ValueExtractor.extractValueFromPhrase("Impressora laser 1500 reais");
  /// // result = {
  /// //   'amount': 1500.0,
  /// //   'description': 'Impressora laser',
  /// //   'hasValue': true,
  /// //   'originalPhrase': 'Impressora laser 1500 reais'
  /// // }
  /// ```
  static Map<String, dynamic> extractValueFromPhrase(String phrase) {
    if (phrase.isEmpty) {
      return {
        'amount': null,
        'description': '',
        'hasValue': false,
        'originalPhrase': phrase,
      };
    }

    // Regex to find numbers (integers or decimals with . or , as separator)
    // Matches: 10, 10.50, 10,50, 1500, 1500.00, 1.500,00, etc.
    final numberRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)',
      caseSensitive: false,
    );
    
    final matches = numberRegex.allMatches(phrase).toList();
    
    if (matches.isEmpty) {
      return {
        'amount': null,
        'description': phrase.trim(),
        'hasValue': false,
        'originalPhrase': phrase,
      };
    }

    // Try to find the most likely value
    // Priority: Last number found (most common in natural language)
    // "Impressora laser 1500 reais" → 1500
    // "IPVA do corolla 200 reais" → 200
    final match = matches.last;
    
    // Extract and normalize the number
    String valueStr = match.group(0)!;
    
    // Normalize: Remove thousand separators and convert decimal separator to .
    // 1.500,00 → 1500.00
    // 1,500.00 → 1500.00
    valueStr = _normalizeNumber(valueStr);
    
    final value = double.tryParse(valueStr);
    
    if (value == null || value == 0) {
      return {
        'amount': null,
        'description': phrase.trim(),
        'hasValue': false,
        'originalPhrase': phrase,
      };
    }

    // Remove the number and currency words from the phrase to get description
    String description = phrase
        .replaceAll(match.group(0)!, '') // Remove the number
        .replaceAll(_getCurrencyPattern(), '') // Remove currency words
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    // If description is empty, use a generic term
    if (description.isEmpty) {
      description = 'Transação';
    }

    return {
      'amount': value,
      'description': description,
      'hasValue': true,
      'originalPhrase': phrase,
      'extractedValue': match.group(0),
    };
  }

  /// Normalizes number strings to standard format
  /// 
  /// Examples:
  /// - "1.500,00" → "1500.00" (BR/DE format)
  /// - "1,500.00" → "1500.00" (US/UK format)
  /// - "1500" → "1500"
  /// - "1500,50" → "1500.50"
  static String _normalizeNumber(String numberStr) {
    // Count occurrences of . and ,
    final dotCount = '.'.allMatches(numberStr).length;
    final commaCount = ','.allMatches(numberStr).length;
    
    // Determine format based on separators
    if (dotCount > 0 && commaCount > 0) {
      // Both present: determine which is decimal separator
      final lastDot = numberStr.lastIndexOf('.');
      final lastComma = numberStr.lastIndexOf(',');
      
      if (lastDot > lastComma) {
        // US/UK format: 1,500.00
        return numberStr.replaceAll(',', '');
      } else {
        // BR/DE format: 1.500,00
        return numberStr.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (commaCount > 0) {
      // Only comma: could be decimal or thousand separator
      if (commaCount == 1 && numberStr.indexOf(',') > numberStr.length - 4) {
        // Likely decimal: 1500,50
        return numberStr.replaceAll(',', '.');
      } else {
        // Likely thousand separator: 1,500
        return numberStr.replaceAll(',', '');
      }
    } else if (dotCount > 0) {
      // Only dot: could be decimal or thousand separator
      if (dotCount == 1 && numberStr.indexOf('.') > numberStr.length - 4) {
        // Likely decimal: 1500.50
        return numberStr;
      } else {
        // Likely thousand separator: 1.500
        return numberStr.replaceAll('.', '');
      }
    }
    
    // No separators: return as is
    return numberStr;
  }

  /// Returns a regex pattern for common currency words in multiple languages
  static RegExp _getCurrencyPattern() {
    return RegExp(
      r'\b(reais?|real|dollars?|dollar|euros?|euro|pesos?|peso|pounds?|pound|'
      r'libras?|libra|yens?|yen|yuans?|yuan|rubles?|ruble|rupees?|rupee|'
      r'francs?|franc|won|krona|kronor|rand|ringgit|baht|dong|'
      r'R\$|USD|\$|EUR|€|GBP|£|JPY|¥|CNY|RUB|₽|INR|₹)\b',
      caseSensitive: false,
    );
  }

  /// Validates if a phrase likely contains a monetary transaction
  /// 
  /// Returns true if the phrase contains a number that could be a value
  static bool likelyHasValue(String phrase) {
    final result = extractValueFromPhrase(phrase);
    return result['hasValue'] == true;
  }

  /// Extracts multiple values from a phrase (for installments, etc)
  /// 
  /// Example: "3 parcelas de 100 reais" → [3.0, 100.0]
  static List<double> extractAllValues(String phrase) {
    final numberRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)',
    );
    
    final matches = numberRegex.allMatches(phrase);
    final values = <double>[];
    
    for (final match in matches) {
      final normalized = _normalizeNumber(match.group(0)!);
      final value = double.tryParse(normalized);
      if (value != null && value > 0) {
        values.add(value);
      }
    }
    
    return values;
  }
}
