import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Entitlement ID configurado no RevenueCat (assumindo 'premium')
  static const String entitlementId = 'premium';

  final ValueNotifier<SubscriptionInfo> subscriptionNotifier = ValueNotifier(
    SubscriptionInfo.premium(
      validUntil: DateTime.now().add(const Duration(days: 365 * 100)), // 100 anos
      isTrial: false,
      paymentMethod: PaymentMethod.store,
    ),
  );

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    // Sem lógica de RevenueCat necessária
    _isInitialized = true;
  }

  SubscriptionInfo get currentSubscription => subscriptionNotifier.value;
  bool get isPremium => true;

  /// Obtém as ofertas (produtos) - Retorna null pois é tudo gratuito
  Future<dynamic> getOfferings() async {
    return null;
  }

  /// Simula compra bem sucedida
  Future<bool> purchasePackage(dynamic package) async {
    return true;
  }

  /// Restaura compras - no-op
  Future<void> restorePurchases() async {
    // Nada a fazer
  }

  /// Login - no-op
  Future<void> logIn(String appUserId) async {
    // Nada a fazer
  }

  Future<void> logOut() async {
    // Nada a fazer
  }
  
  Future<void> resetToFree() async {
    // Não permite reset para free
  }
}
