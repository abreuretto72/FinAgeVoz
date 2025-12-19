import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class BalanceManager {
  static const String BOX_NAME = 'monthly_closings';
  
  final Box _box; // Key: "yyyy-MM", Value: Map<String, dynamic>
  
  BalanceManager(this._box);

  static Future<BalanceManager> init() async {
    final box = await Hive.openBox(BOX_NAME);
    return BalanceManager(box);
  }

  /// Retorna o último fechamento disponível
  Map<String, dynamic>? getLastClosing() {
    if (_box.isEmpty) return null;
    // Keys são strings yyyy-MM, então a última alfabética deve ser a mais recente
    final sortedKeys = _box.keys.cast<String>().toList()..sort();
    return _box.get(sortedKeys.last)?.cast<String, dynamic>();
  }

  Map<String, dynamic>? getClosing(String monthYear) {
    return _box.get(monthYear)?.cast<String, dynamic>();
  }

  /// Calcula e salva o fechamento de um mês específico
  Future<void> consolidateMonth(DateTime date, List<Transaction> allTransactions) async {
    final monthYear = DateFormat('yyyy-MM').format(date);
    
    // Obter saldo inicial (Fechamento do mês anterior ou 0)
    final prevMonthDate = DateTime(date.year, date.month - 1);
    final prevMonthKey = DateFormat('yyyy-MM').format(prevMonthDate);
    // Recursão implícita: Se o mês anterior não existe, ele deveria existir?
    // Vamos assumir que o processo de recálculo garante a ordem sequencial.
    final prevClosing = getClosing(prevMonthKey);
    
    double openingBalance = 0.0;
    if (prevClosing != null) {
      openingBalance = (prevClosing['closingBalance'] as num).toDouble();
    }
    
    // Calcular movimentos do mês (SOMENTE REALIZADOS/PAGOS PELO FLUXO DE CAIXA)
    double income = 0;
    double expense = 0;
    double netChange = 0;

    for (var t in allTransactions) {
      if (!t.isRealized) continue;
      
      // Determinar a data efetiva do fluxo (Caixa)
      DateTime effectiveDate = t.paymentDate ?? t.date;
      
      if (effectiveDate.year == date.year && effectiveDate.month == date.month) {
          // Accumulate for Math
          netChange += t.amount;
          
          // Accumulate for Reporting (Absolute values)
          if (t.isExpense) {
            expense += t.amount.abs();
          } else {
            income += t.amount.abs();
          }
      }
    }

    // ALGEBRAIC SUM: Opening + NetChange (since expenses are negative)
    double closingBalance = openingBalance + netChange;

    final data = {
      'monthYear': monthYear,
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'totalIncome': income,
      'totalExpense': expense,
      'isClosed': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _box.put(monthYear, data);
    print("DEBUG: Consolidado $monthYear. Início: $openingBalance, Fim: $closingBalance");
  }
  
  /// Recalcula em cascata a partir de uma data até o mês ATUAL (inclusive)
  Future<void> recalculateFrom(DateTime date, List<Transaction> allTransactions) async {
    print("DEBUG: Iniciando recálculo em cascata a partir de ${DateFormat('yyyy-MM').format(date)}");
    DateTime current = DateTime(date.year, date.month);
    final now = DateTime.now();
    // Incluir o mês atual no recálculo para ter o saldo parcial atualizado também se quisermos
    // Mas o fechamento do mês atual é 'aberto'. 
    // Vamos consolidar até o mês atual para ter o 'openingBalance' do próximo mês já pronto?
    // Ou apenas até o mês passado?
    // O requisito diz: "propagagar a diferença... até chegar ao mês atual."
    // Isso implica que o mês atual deve ter seu Saldo Inicial corrigido.
    // Então devemos consolidar ATÉ O MÊS ANTERIOR ao atual.
    
    final lastClosedMonth = DateTime(now.year, now.month - 1); // Ex: Se agora é Dez, lastClosed é No
    
    // Se a data de recálculo for futura ao último fechado, nada a fazer históricos.
    // Mas se estamos recalculando o passado, vamos até o último fechado.
    
    // Se nunca houve fechamento, começamos da primeira transação?
    // Vamos apenas garantir que percorremos do mês solicitado até o mês passado.
    
    while (current.isBefore(lastClosedMonth) || current.isAtSameMomentAs(lastClosedMonth)) {
      await consolidateMonth(current, allTransactions);
      current = DateTime(current.year, current.month + 1);
    }
  }
  
  /// Garante que todos os meses desde a primeira transação até hoje tenham fechamentos
  Future<void> ensureHistoryConsistency(List<Transaction> allTransactions) async {
    if (allTransactions.isEmpty) return;
    
    // Ordenar por data
    final sorted = List<Transaction>.from(allTransactions)
      ..sort((a, b) => (a.paymentDate ?? a.date).compareTo(b.paymentDate ?? b.date));
      
    final firstDate = sorted.first.paymentDate ?? sorted.first.date;
    final now = DateTime.now();
    final lastClosedMonth = DateTime(now.year, now.month - 1);
    
    if (firstDate.isAfter(lastClosedMonth)) return; // Nada antigo para fechar
    
    // Verificar lacunas. Para simplificar e garantir integridade:
    // Recalcular TUDO desde o primeiro mês se detectar inconsistência ou se for a primeira vez.
    // Verificamos se temos o fechamento do mês anterior ao atual.
    final lastKey = DateFormat('yyyy-MM').format(lastClosedMonth);
    if (!_box.containsKey(lastKey)) {
       print("DEBUG: Histórico de fechamento incompleto. Recalculando tudo desde ${firstDate.year}-${firstDate.month}...");
       await recalculateFrom(firstDate, allTransactions);
    }
  }

  /// Força um recálculo total, limpando dados antigos (Cache Busting)
  Future<void> rebuildAll(List<Transaction> allTransactions) async {
    print("DEBUG: Force Rebuild All Balances...");
    await _box.clear();
    if (allTransactions.isEmpty) return;
    
    // Sort logic duplicated from ensureHistoryConsistency but essential here
    final sorted = List<Transaction>.from(allTransactions)
      ..sort((a, b) => (a.paymentDate ?? a.date).compareTo(b.paymentDate ?? b.date));
      
    final firstDate = sorted.first.paymentDate ?? sorted.first.date;
    await recalculateFrom(firstDate, allTransactions);
  }

  double getCurrentBalance(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final prevMonthDate = DateTime(now.year, now.month - 1);
    final prevMonthKey = DateFormat('yyyy-MM').format(prevMonthDate);
    final prevClosing = getClosing(prevMonthKey);
    
    double baseBalance = 0;
    if (prevClosing != null) {
      baseBalance = (prevClosing['closingBalance'] as num).toDouble();
    } else {
        // Se não tem fechamento anterior, pode ser que o usuário começou a usar este mês
        // ou a consistência ainda não rodou.
        // Fallback: calcular tudo (lento) para garantir precisão se não tiver cache.
        // Ou assumir 0 se a consistência rodar no init.
    }
    
    // Calcular movimentações do mês ATUAL
    // Calcular movimentações do mês ATUAL
    double currentNetChange = 0;
    
    for (var t in allTransactions) {
      if (!t.isRealized) continue;
      DateTime effectiveDate = t.paymentDate ?? t.date;
      if (effectiveDate.year == now.year && effectiveDate.month == now.month) {
         currentNetChange += t.amount; // Algebraic sum
      }
    }
    
    return baseBalance + currentNetChange;
  }
}
