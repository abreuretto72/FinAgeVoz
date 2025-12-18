import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/localization.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  String get _currentLanguage => Localizations.localeOf(context).toString();
  String t(String key) {
    // Fallback manual para chaves novas caso não estejam no arb
    if (key == 'about_title') return 'Sobre o App';
    if (key == 'terms_of_use') return 'Termos de Uso';
    
    // Tenta pegar do localization padrão
    return AppLocalizations.t(key, _currentLanguage);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(t('about_title'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.mic, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            
            // App Name
            const Text(
              'FinAgeVoz',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v$_appVersion ($_buildNumber)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'monospace'
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Links
            _buildLinkButton(AppLocalizations.t('help_privacy_title', _currentLanguage), Icons.privacy_tip_outlined, () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
               );
            }),
            
            /* 
            // TODO: Criar tela de termos ou link externo
            _buildLinkButton(t('terms_of_use'), Icons.description_outlined, () {
               _launchUrl('https://finagevoz.com/terms'); 
            }),
            */
            
            const Spacer(flex: 3),
            
            // Company & Contact Info
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: [
                   const Text(
                    'Multiverso Digital',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl('mailto:contato@multiversodigital.com.br'),
                    child: const Text(
                      'contato@multiversodigital.com.br',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '© 2025 FinAgeVoz. Todos os direitos reservados.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(String text, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                text, 
                style: const TextStyle(fontSize: 16, color: Colors.white)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
