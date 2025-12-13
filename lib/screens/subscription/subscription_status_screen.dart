import 'package:flutter/material.dart';
import '../../services/subscription/subscription_service.dart';
import '../../models/subscription_model.dart';

class SubscriptionStatusScreen extends StatelessWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status da Conta'),
      ),
      body: ValueListenableBuilder<SubscriptionInfo>(
        valueListenable: subscriptionService.subscriptionNotifier,
        builder: (context, info, _) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.check_circle_outline, size: 100, color: Colors.greenAccent),
                   const SizedBox(height: 24),
                   const Text(
                     'Versão Completa',
                     style: TextStyle(
                       fontSize: 28,
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 32.0),
                     child: Text(
                       'Você tem acesso gratuito a todos os recursos do FinAgeVoz.',
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontSize: 16,
                         color: Colors.white70,
                       ),
                     ),
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
