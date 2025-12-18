import 'package:flutter/material.dart';

/// Helper para tratamento defensivo de dados
/// 
/// Garante que o app NUNCA crashe por dados nulos ou corrompidos.
/// Sempre retorna valores padrão seguros.
class SafeDataHelper {
  /// Retorna double seguro (nunca null, nunca NaN, nunca Infinity)
  static double safeDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    
    try {
      if (value is double) {
        if (value.isNaN || value.isInfinite) return defaultValue;
        return value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove símbolos de moeda e espaços
        String cleaned = value
            .replaceAll(RegExp(r'[R\$€£¥₹\s]'), '')
            .trim();
        
        // Detecta formato (vírgula ou ponto como decimal)
        if (cleaned.contains(',') && cleaned.contains('.')) {
          if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
            cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
          } else {
            cleaned = cleaned.replaceAll(',', '');
          }
        } else if (cleaned.contains(',')) {
          cleaned = cleaned.replaceAll(',', '.');
        }
        
        final parsed = double.tryParse(cleaned);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to parse double from $value: $e');
      return defaultValue;
    }
  }
  
  /// Retorna int seguro (nunca null)
  static int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    
    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.replaceAll(RegExp(r'[^\d-]'), ''));
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to parse int from $value: $e');
      return defaultValue;
    }
  }
  
  /// Retorna String segura (nunca null)
  static String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    
    try {
      return value.toString();
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to convert to string: $e');
      return defaultValue;
    }
  }
  
  /// Retorna DateTime seguro (nunca null)
  static DateTime safeDateTime(dynamic value, {DateTime? defaultValue}) {
    defaultValue ??= DateTime.now();
    
    if (value == null) return defaultValue;
    
    try {
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to parse DateTime from $value: $e');
      return defaultValue;
    }
  }
  
  /// Retorna bool seguro (nunca null)
  static bool safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    
    try {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'sim') {
          return true;
        }
        if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'não') {
          return false;
        }
      }
      return defaultValue;
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to parse bool from $value: $e');
      return defaultValue;
    }
  }
  
  /// Retorna List segura (nunca null)
  static List<T> safeList<T>(dynamic value, {List<T>? defaultValue}) {
    defaultValue ??= [];
    
    if (value == null) return defaultValue;
    
    try {
      if (value is List<T>) return value;
      if (value is List) return value.cast<T>();
      return defaultValue;
    } catch (e) {
      debugPrint('SafeDataHelper: Failed to parse List from $value: $e');
      return defaultValue;
    }
  }
  
  /// Valida e sanitiza valor de moeda
  /// Garante que seja positivo e tenha no máximo 2 casas decimais
  static double safeCurrency(dynamic value, {bool allowNegative = false}) {
    final amount = safeDouble(value);
    
    if (!allowNegative && amount < 0) return 0.0;
    
    // Arredonda para 2 casas decimais
    return (amount * 100).round() / 100;
  }
  
  /// Valida e sanitiza porcentagem (0-100)
  static double safePercentage(dynamic value) {
    final percent = safeDouble(value);
    
    if (percent < 0) return 0.0;
    if (percent > 100) return 100.0;
    
    return percent;
  }
}
