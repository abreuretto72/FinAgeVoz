import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_service.dart';

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
            icon: const Icon(Icons.share),
            tooltip: _currentLanguage.startsWith('pt') ? 'Compartilhar' : 'Share',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _policyText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getCopiedMessage()),
                  duration: const Duration(seconds: 2),
                ),
              );
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
                  // Header com ícone
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.privacy_tip,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getHeaderTitle(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getHeaderSubtitle(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Conteúdo da política
                  SelectableText(
                    _policyText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer com informações de contato
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.contact_mail, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              _getContactTitle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getContactSubtitle(),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'E-mail: abreu@multiversodigital.com.br',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentLanguage.startsWith('pt')
                              ? 'Responsável: Belisario Retto de Abreu'
                              : 'Responsible: Belisario Retto de Abreu',
                          style: const TextStyle(fontSize: 13),
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
