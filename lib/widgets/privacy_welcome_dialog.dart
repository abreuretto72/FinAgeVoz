import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';

/// Dialog de boas-vindas com aviso de privacidade
/// Exibido apenas na primeira execução do app
/// Conforme Google Play e App Store Privacy Policies
class PrivacyWelcomeDialog extends StatelessWidget {
  const PrivacyWelcomeDialog({super.key});

  /// Verifica se o usuário já aceitou a política de privacidade
  static Future<bool> hasAcceptedPrivacy() async {
    final db = DatabaseService();
    await db.init();
    return db.hasAcceptedPrivacy();
  }

  /// Marca que o usuário aceitou a política de privacidade
  static Future<void> markPrivacyAccepted() async {
    final db = DatabaseService();
    await db.init();
    await db.setPrivacyAccepted(true);
  }

  /// Mostra o dialog se necessário (primeira execução)
  static Future<bool> showIfNeeded(BuildContext context) async {
    final accepted = await hasAcceptedPrivacy();
    
    if (!accepted && context.mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Não pode fechar clicando fora
        builder: (context) => const PrivacyWelcomeDialog(),
      );
      
      return result ?? false;
    }
    
    return true; // Já aceitou anteriormente
  }

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTermsOfService() async {
    final url = Uri.parse('https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de privacidade
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip,
                size: 48,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título
            const Text(
              'Bem-vindo ao FinAgeVoz',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Mensagem principal
            const Text(
              'Ao continuar, você concorda com os nossos Termos de Uso e Política de Privacidade.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Informações sobre dados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Utilizamos dados analíticos anônimos para melhorar o app.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.security,
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seus dados financeiros e de saúde são criptografados e nunca compartilhados.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.mic_off,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Comandos de voz são processados localmente e não são armazenados.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Links para documentos
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: _openPrivacyPolicy,
                  child: const Text(
                    'Política de Privacidade',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' | ',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                TextButton(
                  onPressed: _openTermsOfService,
                  child: const Text(
                    'Termos de Uso',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Sair'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      await markPrivacyAccepted();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Aceitar e Continuar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
