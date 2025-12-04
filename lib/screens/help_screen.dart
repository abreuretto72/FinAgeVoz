import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    // Substitua pelo número real
    const phoneNumber = '5511999999999'; 
    const message = 'Olá, preciso de ajuda com o FinAgeVoz.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contato'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('Falar no WhatsApp'),
                subtitle: const Text('Tire dúvidas ou envie sugestões'),
                onTap: () => _openWhatsApp(context),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Dicas de Uso'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Comandos de Voz',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Você pode realizar ações rapidamente usando sua voz. Tente dizer:'),
                    SizedBox(height: 8),
                    _FeatureItem('"Ligar para [Nome do Contato]"', icon: Icons.phone),
                    _FeatureItem('"Adicionar despesa de 50 reais em alimentação"', icon: Icons.mic),
                    _FeatureItem('"Agendar reunião amanhã às 14 horas"', icon: Icons.calendar_today),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Sobre a Assinatura'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Plano Premium',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    SizedBox(height: 8),
                    Text('Ao assinar o plano Premium, você desbloqueia:'),
                    SizedBox(height: 8),
                    _FeatureItem('Sincronização na Nuvem (Backup automático)'),
                    _FeatureItem('Comandos de voz ilimitados'),
                    _FeatureItem('Relatórios avançados'),
                    _FeatureItem('Anexos ilimitados'),
                    SizedBox(height: 16),
                    Text(
                      'O pagamento é processado de forma segura pela Google Play ou App Store. Você pode cancelar a qualquer momento nas configurações da sua loja de aplicativos.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Versão 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final IconData icon;
  
  const _FeatureItem(this.text, {this.icon = Icons.check_circle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: icon == Icons.check_circle ? Colors.green : Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
