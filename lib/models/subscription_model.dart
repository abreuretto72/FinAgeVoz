
enum UserPlan {
  free,
  premium,
}

enum PaymentMethod {
  pix,
  creditCard,
  store, // Apple/Google Pay
}

enum PaymentStatus {
  pending,
  approved,
  rejected,
  error,
}

class SubscriptionInfo {
  final UserPlan plan;
  final DateTime? validUntil;
  final bool isTrial;
  final bool isActive;
  final PaymentMethod? paymentMethod;

  const SubscriptionInfo({
    required this.plan,
    this.validUntil,
    this.isTrial = false,
    this.isActive = true,
    this.paymentMethod,
  });

  // Factory para criar um plano Free padrão
  factory SubscriptionInfo.free() {
    return const SubscriptionInfo(
      plan: UserPlan.free,
      isActive: true,
    );
  }

  // Factory para criar um plano Premium
  factory SubscriptionInfo.premium({
    required DateTime validUntil,
    bool isTrial = false,
    PaymentMethod? paymentMethod,
  }) {
    return SubscriptionInfo(
      plan: UserPlan.premium,
      validUntil: validUntil,
      isTrial: isTrial,
      isActive: true,
      paymentMethod: paymentMethod,
    );
  }

  // Serialização JSON para persistência simples
  Map<String, dynamic> toJson() {
    return {
      'plan': plan.toString(),
      'validUntil': validUntil?.toIso8601String(),
      'isTrial': isTrial,
      'isActive': isActive,
      'paymentMethod': paymentMethod?.toString(),
    };
  }

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: UserPlan.values.firstWhere(
        (e) => e.toString() == json['plan'],
        orElse: () => UserPlan.free,
      ),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      isTrial: json['isTrial'] ?? false,
      isActive: json['isActive'] ?? true,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString() == json['paymentMethod'],
              orElse: () => PaymentMethod.pix,
            )
          : null,
    );
  }

  bool get isPremium => plan == UserPlan.premium && isActive && (validUntil == null || validUntil!.isAfter(DateTime.now()));
  bool get isFree => !isPremium;
  
  String get planName => isPremium ? 'Premium' : 'Gratuito';
}
