import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper para formatação de datas respeitando o locale do usuário
/// 
/// NUNCA force 'dd/MM/yyyy'. Deixe o sistema decidir o formato correto:
/// - Brasil: 31/12/2025
/// - EUA: 12/31/2025
/// - Japão: 2025/12/31
class DateFormatter {
  /// Formata data curta (ex: 31/12/2025 ou 12/31/2025)
  static String formatShort(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatShortWithLocale(locale, date);
  }
  
  /// Formata data curta com locale específico
  static String formatShortWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.yMd(locale).format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.yMd('pt_BR').format(date);
    }
  }
  
  /// Formata data longa (ex: 31 de dezembro de 2025)
  static String formatLong(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatLongWithLocale(locale, date);
  }
  
  /// Formata data longa com locale específico
  static String formatLongWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.yMMMMd(locale).format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.yMMMMd('pt_BR').format(date);
    }
  }
  
  /// Formata data com hora (ex: 31/12/2025 14:30)
  static String formatWithTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatWithTimeWithLocale(locale, date);
  }
  
  /// Formata data com hora com locale específico
  static String formatWithTimeWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.yMd(locale).add_Hm().format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.yMd('pt_BR').add_Hm().format(date);
    }
  }
  
  /// Formata apenas hora (ex: 14:30 ou 2:30 PM)
  static String formatTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatTimeWithLocale(locale, date);
  }
  
  /// Formata apenas hora com locale específico
  static String formatTimeWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.Hm(locale).format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.Hm('pt_BR').format(date);
    }
  }
  
  /// Formata mês e ano (ex: dezembro de 2025)
  static String formatMonthYear(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatMonthYearWithLocale(locale, date);
  }
  
  /// Formata mês e ano com locale específico
  static String formatMonthYearWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.yMMMM(locale).format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.yMMMM('pt_BR').format(date);
    }
  }
  
  /// Formata dia da semana (ex: segunda-feira)
  static String formatWeekday(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return formatWeekdayWithLocale(locale, date);
  }
  
  /// Formata dia da semana com locale específico
  static String formatWeekdayWithLocale(String locale, DateTime date) {
    try {
      return DateFormat.EEEE(locale).format(date);
    } catch (e) {
      debugPrint('DateFormatter: Locale $locale not supported, using pt_BR');
      return DateFormat.EEEE('pt_BR').format(date);
    }
  }
  
  /// Formata data relativa (ex: "hoje", "ontem", "amanhã")
  static String formatRelative(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = dateOnly.difference(today).inDays;
    
    if (difference == 0) return 'Hoje';
    if (difference == 1) return 'Amanhã';
    if (difference == -1) return 'Ontem';
    if (difference > 1 && difference <= 7) return 'Em $difference dias';
    if (difference < -1 && difference >= -7) return 'Há ${-difference} dias';
    
    return formatShort(context, date);
  }
  
  /// Parse string de data (aceita múltiplos formatos)
  static DateTime? parse(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      // Tenta ISO 8601 primeiro
      return DateTime.tryParse(dateString);
    } catch (e) {
      // Tenta formatos comuns
      final formats = [
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
      ];
      
      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateString);
        } catch (_) {
          continue;
        }
      }
      
      debugPrint('DateFormatter: Failed to parse date: $dateString');
      return null;
    }
  }
}
