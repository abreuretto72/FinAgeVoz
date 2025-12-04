
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/subscription/subscription_service.dart';
import '../../models/subscription_model.dart';
import 'paywall_screen.dart';

class SubscriptionStatusScreen extends StatelessWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Assinatura'),
      ),
      body: ValueListenableBuilder<SubscriptionInfo>(
        valueListenable: subscriptionService.subscriptionNotifier,
        builder: (context, info, _) {
          final isPremium = info.isPremium;
          final dateFormat = DateFormat('dd/MM/yyyy');

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Icon(
                          isPremium ? Icons.workspace_premium : Icons.person_outline,
                          size: 80,
                          color: isPremium ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Plano Atual',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          info.planName.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPremium ? Colors.amber[800] : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        if (isPremium) ...[
                          _buildInfoRow('Status', 'Ativo', Colors.green),
                          const SizedBox(height: 12),
                          if (info.validUntil != null)
                            _buildInfoRow('Válido até', dateFormat.format(info.validUntil!), null),
                          const SizedBox(height: 12),
                          _buildInfoRow('Pagamento', info.paymentMethod.toString().split('.').last.toUpperCase(), null),
                        ] else ...[
                          const Text(
                            'Você está usando a versão gratuita com recursos limitados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Botões fixos na parte inferior
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPremium)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PaywallScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('FAZER UPGRADE AGORA'),
                          ),
                        ),

                      if (isPremium)
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Para cancelar, acesse as assinaturas na sua loja de aplicativos (Play Store/App Store).')),
                            );
                          },
                          child: const Text('Gerenciar Assinatura'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
