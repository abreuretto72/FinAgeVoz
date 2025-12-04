
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // API Key fornecida pelo usuário
  final String _apiKey = 'test_YZJFaHNFBiKpJwWvgBtmRBjYMig';
  
  // Entitlement ID configurado no RevenueCat (assumindo 'premium')
  static const String entitlementId = 'premium';

  final ValueNotifier<SubscriptionInfo> subscriptionNotifier = ValueNotifier(SubscriptionInfo.free());

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
    } else if (Platform.isIOS) {
      // Se tiver chave iOS, configurar aqui. Por enquanto usando a mesma ou ignorando.
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
    _isInitialized = true;

    // Verificar status inicial
    await _updateCustomerStatus();

    // Ouvir mudanças (renovações, cancelamentos, etc)
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _updateLocalStateFromInfo(customerInfo);
    });
  }

  Future<void> _updateCustomerStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateLocalStateFromInfo(customerInfo);
    } on PlatformException catch (e) {
      print('Erro ao obter status do RevenueCat: $e');
    }
  }

  void _updateLocalStateFromInfo(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[entitlementId];
    final isActive = entitlement?.isActive ?? false;

    if (isActive) {
      // Tentar extrair data de validade se disponível
      DateTime? validUntil;
      if (entitlement?.expirationDate != null) {
        validUntil = DateTime.parse(entitlement!.expirationDate!);
      }

      subscriptionNotifier.value = SubscriptionInfo.premium(
        validUntil: validUntil ?? DateTime.now().add(const Duration(days: 30)), // Fallback
        isTrial: entitlement?.periodType == PeriodType.trial,
        paymentMethod: PaymentMethod.store, // Gerenciado pela loja
      );
    } else {
      subscriptionNotifier.value = SubscriptionInfo.free();
    }
  }

  SubscriptionInfo get currentSubscription => subscriptionNotifier.value;
  bool get isPremium => currentSubscription.isPremium;

  /// Obtém as ofertas (produtos) configurados no RevenueCat
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print('Erro ao buscar ofertas: $e');
      return null;
    }
  }

  /// Realiza a compra de um pacote
  Future<bool> purchasePackage(Package package) async {
    try {
      // Workaround para erro de tipo: forçar dynamic
      final dynamic result = await Purchases.purchasePackage(package);
      CustomerInfo customerInfo;
      
      // Tenta acessar a propriedade customerInfo (comum em wrappers)
      // Se não existir, assume que o próprio objeto é o CustomerInfo
      try {
        customerInfo = result.customerInfo;
      } catch (_) {
        customerInfo = result;
      }
      
      final isPro = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      return isPro;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('Erro na compra: $e');
        throw e; // Repassar erro para UI tratar (exceto cancelamento)
      }
      return false;
    }
  }

  /// Restaura compras anteriores
  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateLocalStateFromInfo(customerInfo);
    } on PlatformException catch (e) {
      print('Erro ao restaurar compras: $e');
      throw e;
    }
  }

  /// Login no RevenueCat (opcional, para vincular ao ID do Firebase)
  Future<void> logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
      await _updateCustomerStatus();
    } on PlatformException catch (e) {
      print('Erro ao logar no RevenueCat: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      subscriptionNotifier.value = SubscriptionInfo.free();
    } on PlatformException catch (e) {
      print('Erro ao deslogar do RevenueCat: $e');
    }
  }
  
  // Métodos antigos de debug/mock (mantidos como stub ou removidos se não usados)
  Future<void> resetToFree() async {
    // Em produção com RevenueCat, não resetamos localmente assim, 
    // mas para debug podemos forçar o notifier.
    subscriptionNotifier.value = SubscriptionInfo.free();
  }
}
