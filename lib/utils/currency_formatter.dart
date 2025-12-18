import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper para formatação de moeda respeitando o locale do usuário
/// 
/// Resolve o problema crítico de "R$" hardcoded que quebra
/// a experiência para usuários internacionais.
class CurrencyFormatter {
  /// Formata valor como moeda baseado no locale atual
  /// 
  /// Exemplos:
  /// - pt_BR: R$ 1.234,56
  /// - en_US: $1,234.56
  /// - es_ES: 1.234,56 €
  /// - de_DE: 1.234,56 €
  static String format(BuildContext context, double value) {
    final locale = Localizations.localeOf(context).toString();
    return formatWithLocale(locale, value);
  }
  
  /// Formata valor com locale específico (sem context)
  static String formatWithLocale(String locale, double value) {
    try {
      final formatter = NumberFormat.simpleCurrency(
        locale: locale,
        decimalDigits: 2,
      );
      return formatter.format(value);
    } catch (e) {
      // Fallback para pt_BR se locale não suportado
      debugPrint('CurrencyFormatter: Locale $locale not supported, using pt_BR');
      final formatter = NumberFormat.simpleCurrency(
        locale: 'pt_BR',
        decimalDigits: 2,
      );
      return formatter.format(value);
    }
  }
  
  /// Retorna apenas o símbolo da moeda
  static String getSymbol(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return getSymbolWithLocale(locale);
  }
  
  /// Retorna símbolo da moeda com locale específico
  static String getSymbolWithLocale(String locale) {
    try {
      final formatter = NumberFormat.simpleCurrency(locale: locale);
      return formatter.currencySymbol;
    } catch (e) {
      return 'R\$'; // Fallback
    }
  }
  
  /// Parse string de moeda para double
  /// Aceita formatos: "R$ 1.234,56", "$1,234.56", "1234.56", etc.
  static double? parse(String value) {
    try {
      // Remove símbolos de moeda e espaços
      String cleaned = value
          .replaceAll(RegExp(r'[R\$€£¥₹]'), '')
          .replaceAll(' ', '')
          .trim();
      
      // Detecta se usa vírgula ou ponto como decimal
      if (cleaned.contains(',') && cleaned.contains('.')) {
        // Formato: 1.234,56 (europeu) ou 1,234.56 (americano)
        if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
          // Vírgula é decimal
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Ponto é decimal
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        // Apenas vírgula - assumir decimal
        cleaned = cleaned.replaceAll(',', '.');
      }
      
      return double.parse(cleaned);
    } catch (e) {
      debugPrint('CurrencyFormatter: Failed to parse "$value": $e');
      return null;
    }
  }
}
