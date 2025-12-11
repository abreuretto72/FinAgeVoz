import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/pdf_service.dart';

/// Tela de exibição da Política de Privacidade
/// Carrega o arquivo correto baseado no idioma do app
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final DatabaseService _db = DatabaseService();
  String _policyText = '';
  bool _isLoading = true;
  String _currentLanguage = 'pt';

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  /// Determina qual arquivo carregar baseado no idioma
  String _getPolicyFileName() {
    // Obter idioma do app
    _currentLanguage = _db.getLanguage();
    
    // Mapear idioma para arquivo correto
    // Português (Brasil e Portugal) -> pt
    if (_currentLanguage.startsWith('pt')) {
      return 'assets/privacy_policy_pt.txt';
    }
    
    // Todos os outros idiomas -> inglês (padrão internacional)
    return 'assets/privacy_policy_en.txt';
  }

  Future<void> _loadPolicy() async {
    try {
      final fileName = _getPolicyFileName();
      final text = await rootBundle.loadString(fileName);
      
      if (mounted) {
        setState(() {
          _policyText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _policyText = _getErrorMessage();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGitHubPage() async {
    final String urlString = _currentLanguage.startsWith('pt')
        ? 'https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-pt.html'
        : 'https://abreuretto72.github.io/FinAgeVoz/web_pages/privacy-policy-en.html';
        
    final Uri url = Uri.parse(urlString);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_currentLanguage.startsWith('pt') 
              ? 'Erro ao abrir link' 
              : 'Error opening link')),
        );
      }
    }
  }

  String _getErrorMessage() {
    if (_currentLanguage.startsWith('pt')) {
      return 'Erro ao carregar a Política de Privacidade.\n\n'
          'Por favor, entre em contato com o suporte:\n'
          'abreu@multiversodigital.com.br';
    } else {
      return 'Error loading Privacy Policy.\n\n'
          'Please contact support:\n'
          'abreu@multiversodigital.com.br';
    }
  }

  String _getTitle() {
    return _currentLanguage.startsWith('pt') 
        ? 'Política de Privacidade' 
        : 'Privacy Policy';
  }

  String _getHeaderTitle() {
    return _currentLanguage.startsWith('pt')
        ? 'Sua Privacidade é Nossa Prioridade'
        : 'Your Privacy is Our Priority';
  }

  String _getHeaderSubtitle() {
    return _currentLanguage.startsWith('pt')
        ? 'Leia como protegemos seus dados'
        : 'Read how we protect your data';
  }

  String _getCopiedMessage() {
    return _currentLanguage.startsWith('pt')
        ? 'Política copiada para a área de transferência'
        : 'Policy copied to clipboard';
  }

  String _getContactTitle() {
    return _currentLanguage.startsWith('pt')
        ? 'Dúvidas sobre Privacidade?'
        : 'Privacy Questions?';
  }

  String _getContactSubtitle() {
    return _currentLanguage.startsWith('pt')
        ? 'Entre em contato conosco:'
        : 'Contact us:';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: _currentLanguage.startsWith('pt') ? 'Imprimir PDF' : 'Print PDF',
            onPressed: () {
               PdfService.generatePrivacyPolicyReport(_policyText, _currentLanguage);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: _currentLanguage.startsWith('pt') ? 'Compartilhar' : 'Share',
            onPressed: () {
               PdfService.sharePrivacyPolicyReport(_policyText, _currentLanguage);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com ícone (Clicável para abrir GitHub)
                  InkWell(
                    onTap: _openGitHubPage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.privacy_tip,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getHeaderTitle(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getHeaderSubtitle(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),

                  
                  // Conteúdo da política
                  SelectableText(
                    _policyText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer com informações de contato
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.contact_mail, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              _getContactTitle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getContactSubtitle(),
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'E-mail: abreu@multiversodigital.com.br',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentLanguage.startsWith('pt')
                              ? 'Responsável: Belisario Retto de Abreu'
                              : 'Responsible: Belisario Retto de Abreu',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
