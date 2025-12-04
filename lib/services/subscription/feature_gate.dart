
import 'package:flutter/material.dart';
import 'subscription_service.dart';
import '../../models/subscription_model.dart';
import '../../screens/subscription/paywall_screen.dart';

enum AppFeature {
  createTransaction,
  createAttachment,
  useCloudSync,
  useAdvancedReports,
  useUnlimitedAI,
  voiceCommands,
}

class FeatureGate {
  final SubscriptionService _subscriptionService;

  FeatureGate(this._subscriptionService);

  /// Verifica se o recurso pode ser usado.
  /// Se [showPaywall] for true, abre o Paywall automaticamente se bloqueado.
  Future<bool> canUseFeature(BuildContext context, AppFeature feature, {bool showPaywall = true}) async {
    final isPremium = _subscriptionService.isPremium;
    bool allowed = false;

    switch (feature) {
      case AppFeature.createTransaction:
        // Exemplo: Free tem limite, Premium ilimitado.
        // Aqui simplificamos: sempre true, mas em produção checaria contagem do banco.
        allowed = true; 
        break;
        
      case AppFeature.createAttachment:
        allowed = isPremium;
        break;
        
      case AppFeature.useCloudSync:
        allowed = isPremium;
        break;
        
      case AppFeature.useAdvancedReports:
        allowed = isPremium;
        break;
        
      case AppFeature.useUnlimitedAI:
        allowed = isPremium; // Free poderia ter limite diário
        break;

      case AppFeature.voiceCommands:
        // Exemplo: Free tem limite de X comandos
        allowed = true; 
        break;
    }

    if (!allowed && showPaywall) {
      _showPaywall(context);
    }

    return allowed;
  }

  void _showPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }
}
