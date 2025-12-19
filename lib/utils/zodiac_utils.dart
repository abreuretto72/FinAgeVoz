import 'dart:math';

class ZodiacUtils {
  static String getZodiacSign(DateTime birthDate) {
    int day = birthDate.day;
    int month = birthDate.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Áries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Touro";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gêmeos";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Câncer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leão";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgem";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Escorpião";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagitário";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricórnio";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquário";
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return "Peixes";
    
    return "Desconhecido";
  }

  static String generateLuckyNumbers() {
    final Set<int> numbers = {};
    final Random rng = Random();
    while (numbers.length < 6) {
      numbers.add(rng.nextInt(60) + 1);
    }
    final sortedList = numbers.toList()..sort();
    return sortedList.map((n) => n.toString().padLeft(2, '0')).join(', ');
  }
}
