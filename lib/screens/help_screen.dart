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
            _buildSectionTitle('Comandos de Voz'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Experimente dizer:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _FeatureItem('"Adicionar despesa de 50 reais em alimentação"', icon: Icons.mic),
                    _FeatureItem('"Ligar para Maria"', icon: Icons.phone),
                    _FeatureItem('"Agendar dentista amanhã às 14 horas"', icon: Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Navegação'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _FeatureItem('Diga "Finanças" para ir às finanças', icon: Icons.attach_money),
                    _FeatureItem('Diga "Agenda" para ir à agenda', icon: Icons.calendar_today),
                    _FeatureItem('Ligar para o contato', icon: Icons.phone),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Finanças'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _FeatureItem('Controle de Despesas e Receitas', icon: Icons.attach_money),
                    _FeatureItem('Parcelamentos: O app gera as parcelas futuras e avisa no vencimento.', icon: Icons.credit_card),
                    _FeatureItem('Categoria Imobilizado: Para compra e venda de bens duráveis (ex: Imóveis, Veículos).', icon: Icons.business),
                    _FeatureItem('Relatórios: Visualize gastos por categoria e resumo de parcelamentos.', icon: Icons.bar_chart),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Agenda e Saúde'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _FeatureItem('Avisos de Voz: Todos os eventos da agenda são avisados por voz quando chega a hora.', icon: Icons.record_voice_over),
                    _FeatureItem('Lembretes de Medicamentos: Receba avisos antes e na hora exata de tomar seu remédio.', icon: Icons.medication),
                    Padding(
                      padding: EdgeInsets.only(left: 24, bottom: 8),
                      child: Text(
                        'Dica: Crie um evento na Agenda com o nome do remédio e configure a recorrência.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    _FeatureItem('Confirmação de Pagamento: O app pergunta se você pagou uma parcela no dia do vencimento.', icon: Icons.check_circle_outline),
                    _FeatureItem('Contatos: Ligue diretamente pelo app usando comandos de voz.', icon: Icons.contact_phone),
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
                'Versão 1.1.0',
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
