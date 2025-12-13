
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
    // All features are now free
    return true;
  }

  // Helper não mais usado, mas mantido vazio se algo referenciar
  void _showPaywall(BuildContext context) {
    // Paywall desabilitado
  }
}
