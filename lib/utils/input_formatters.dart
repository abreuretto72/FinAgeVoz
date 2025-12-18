import 'package:flutter/services.dart';

/// Input Formatter que aceita TANTO vírgula quanto ponto como separador decimal
/// 
/// Resolve o problema crítico de internacionalização:
/// - Brasil/Europa: 1.234,56 (ponto = milhar, vírgula = decimal)
/// - EUA/UK: 1,234.56 (vírgula = milhar, ponto = decimal)
/// 
/// Este formatter permite ambos os formatos sem travar o cálculo.
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalDigits;
  final bool allowNegative;
  
  DecimalInputFormatter({
    this.decimalDigits = 2,
    this.allowNegative = false,
  });
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permite vazio
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove caracteres inválidos, mantendo apenas dígitos, vírgula, ponto e sinal negativo
    String text = newValue.text;
    
    // Permite sinal negativo apenas no início
    if (allowNegative && text.startsWith('-')) {
      text = '-' + text.substring(1).replaceAll(RegExp(r'[^\d,.]'), '');
    } else {
      text = text.replaceAll(RegExp(r'[^\d,.]'), '');
    }
    
    // Conta quantas vírgulas e pontos existem
    final commaCount = ','.allMatches(text).length;
    final dotCount = '.'.allMatches(text).length;
    
    // Se tem mais de um separador decimal, mantém o valor antigo
    if (commaCount + dotCount > 1) {
      // Permite múltiplos separadores de milhar, mas apenas um decimal
      // Detecta qual é o separador decimal (último)
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        // Vírgula é decimal, remove outras vírgulas e todos os pontos
        final parts = text.split(',');
        if (parts.length > 2) {
          return oldValue; // Múltiplas vírgulas decimais - inválido
        }
        text = parts[0].replaceAll('.', '') + (parts.length > 1 ? ',${parts[1]}' : '');
      } else if (lastDot > lastComma) {
        // Ponto é decimal, remove outros pontos e todas as vírgulas
        final parts = text.split('.');
        if (parts.length > 2) {
          return oldValue; // Múltiplos pontos decimais - inválido
        }
        text = parts[0].replaceAll(',', '') + (parts.length > 1 ? '.${parts[1]}' : '');
      }
    }
    
    // Limita casas decimais
    if (text.contains(',')) {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length > decimalDigits) {
        parts[1] = parts[1].substring(0, decimalDigits);
        text = parts.join(',');
      }
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length == 2 && parts[1].length > decimalDigits) {
        parts[1] = parts[1].substring(0, decimalDigits);
        text = parts.join('.');
      }
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formatter para valores monetários
/// Aceita vírgula e ponto, limita a 2 casas decimais
class CurrencyInputFormatter extends DecimalInputFormatter {
  CurrencyInputFormatter() : super(decimalDigits: 2, allowNegative: false);
}

/// Formatter para porcentagens
/// Aceita vírgula e ponto, limita a 2 casas decimais, máximo 100
class PercentageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove caracteres inválidos
    String text = newValue.text.replaceAll(RegExp(r'[^\d,.]'), '');
    
    // Substitui vírgula por ponto para validação
    final value = double.tryParse(text.replaceAll(',', '.'));
    
    // Se maior que 100, mantém valor antigo
    if (value != null && value > 100) {
      return oldValue;
    }
    
    // Limita a 2 casas decimais
    if (text.contains(',')) {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length > 2) {
        parts[1] = parts[1].substring(0, 2);
        text = parts.join(',');
      }
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length == 2 && parts[1].length > 2) {
        parts[1] = parts[1].substring(0, 2);
        text = parts.join('.');
      }
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
