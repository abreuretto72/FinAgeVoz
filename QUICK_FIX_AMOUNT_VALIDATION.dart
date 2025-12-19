// CORREÇÃO RÁPIDA: Adicionar validação no handleTransaction
// Arquivo: lib/voice/voice_controller.dart
// Localização: Método handleTransaction, após linha 100

// CÓDIGO ORIGINAL (linhas 99-101):
/*
       final description = data['description'] ?? "Transação por Voz";
       final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
       final isExpense = data['isExpense'] == true;
*/

// CÓDIGO CORRIGIDO (substituir as linhas acima por):

       final description = data['description'] ?? "Transação por Voz";
       final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
       
       // VALIDATION: Reject transactions with missing/zero amount
       if (amount == 0.0) {
         print("ERROR: Amount is missing or zero. Asking user to repeat with value.");
         await _voiceService.speak("Desculpe, não consegui identificar o valor. Por favor, diga novamente incluindo o valor. Por exemplo: Gastei 150 reais no mercado.");
         return;
       }
       
       final isExpense = data['isExpense'] == true;

// INSTRUÇÕES:
// 1. Abra: lib/voice/voice_controller.dart
// 2. Localize o método handleTransaction (linha ~93)
// 3. Encontre as linhas 99-101 (description, amount, isExpense)
// 4. Substitua pelo código corrigido acima
// 5. Salve o arquivo
// 6. Faça hot reload (tecla 'r' no terminal do flutter run)

// RESULTADO:
// Quando a IA não conseguir identificar o valor, o app:
// - NÃO criará a transação
// - Pedirá ao usuário para repetir o comando COM o valor
// - Evitará criar transações com amount = 0 e isPaid incorreto
