import 'package:flutter/material.dart';

/// Widget de aviso obrigatório para conformidade com Google Play
/// quando usando IA Generativa (Groq/LLM)
class AIDisclaimerBanner extends StatelessWidget {
  const AIDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withOpacity(0.2),
        border: Border.all(
          color: Colors.orange.shade700,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade400,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠️ Respostas geradas por IA. Podem conter erros.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade200,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
