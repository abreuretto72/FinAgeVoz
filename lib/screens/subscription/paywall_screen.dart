
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/subscription/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  bool _isLoading = true;
  Offerings? _offerings;
  
  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await _subscriptionService.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _subscriptionService.purchasePackage(package);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          Navigator.pop(context); // Fecha o Paywall
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assinatura ativada com sucesso!'), backgroundColor: Colors.green),
          );
        } else {
          // Compra ok, mas não ativou premium (provável erro de config no RevenueCat)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compra realizada, mas Premium não ativado. Verifique configuração (Entitlement).'), 
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na compra: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _subscriptionService.restorePurchases();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas com sucesso.')),
        );
        // Se restaurou e ficou premium, fecha
        if (_subscriptionService.isPremium) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header com botão fechar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _restore,
                        child: const Text('Restaurar', style: TextStyle(color: Colors.white70)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              const Icon(Icons.star, size: 60, color: Colors.amber),
                              const SizedBox(height: 16),
                              const Text(
                                'Seja Premium',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Desbloqueie todo o potencial do FinAgeVoz',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Benefícios
                              _buildBenefitItem(Icons.cloud_sync, 'Sincronização em Nuvem'),
                              _buildBenefitItem(Icons.mic, 'Comandos de Voz Ilimitados'),
                              _buildBenefitItem(Icons.analytics, 'Relatórios Avançados'),
                              _buildBenefitItem(Icons.backup, 'Backup Automático'),

                              const SizedBox(height: 40),

                              // Ofertas
                              if (_offerings != null && _offerings!.current != null && _offerings!.current!.availablePackages.isNotEmpty)
                                ..._offerings!.current!.availablePackages.map((package) {
                                  // Lógica melhorada para detectar tipo de pacote
                                  bool isAnnual = package.packageType == PackageType.annual;
                                  bool isMonthly = package.packageType == PackageType.monthly;

                                  // Fallback se o tipo não for explícito (comum em testes)
                                  if (!isAnnual && !isMonthly) {
                                    final id = package.identifier.toLowerCase();
                                    if (id.contains('year') || id.contains('anual') || id.contains('12')) {
                                      isAnnual = true;
                                    } else {
                                      isMonthly = true;
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildPriceCard(
                                      context,
                                      title: isAnnual ? 'Anual' : 'Mensal',
                                      price: package.storeProduct.priceString,
                                      period: isAnnual ? '/ano' : '/mês',
                                      isBestValue: isAnnual, // Destacar anual como melhor valor
                                      subtitle: isAnnual ? 'Melhor Valor' : null,
                                      onTap: () => _purchase(package),
                                    ),
                                  );
                                }).toList()
                              else
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Nenhuma oferta disponível no momento.\nVerifique sua configuração no RevenueCat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              
                              const SizedBox(height: 20),
                              
                              // ✅ CORREÇÃO: Links obrigatórios conforme Google Play Payments Policy 3.2
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final url = Uri.parse('https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Erro ao abrir link')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Política de Privacidade',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(' | ', style: TextStyle(color: Colors.white54)),
                                  TextButton(
                                    onPressed: () async {
                                      final url = Uri.parse('https://abreuretto72.github.io/FinAgeVoz/web_pages/terms-of-service-pt.html');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Erro ao abrir link')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Termos de Uso',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Assinatura com renovação automática. Cancele a qualquer momento.\n'
                                'Gerenciado pela Google Play Store.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required bool isBestValue,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isBestValue ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBestValue ? Colors.amber : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBestValue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'RECOMENDADO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
