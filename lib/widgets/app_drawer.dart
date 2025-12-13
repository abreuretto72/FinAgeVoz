import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/general_settings_screen.dart';
import '../screens/category_screen.dart';
import '../screens/data_management_screen.dart';
import '../screens/help_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/delete_account_screen.dart';

import '../utils/localization.dart';

class AppDrawer extends StatelessWidget {
  final Function(Widget) navigate;
  final VoidCallback onImportExportTap;
  final String currentLanguage;

  const AppDrawer({
    super.key,
    required this.navigate,
    required this.onImportExportTap,
    required this.currentLanguage,
  });

  String t(String key) => AppLocalizations.t(key, currentLanguage);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FinAgeVoz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestão Inteligente',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ===== GRUPO 1: Configurações & Preferências =====
          _buildSectionHeader(context, 'Configurações & Preferências', Icons.settings),
          
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(t('menu_settings')),
            subtitle: const Text('Idioma, Voz, Biometria'),
            onTap: () {
              Navigator.pop(context);
              navigate(const GeneralSettingsScreen());
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(t('nav_categories')),
            subtitle: const Text('Gerenciar categorias'),
            onTap: () {
              Navigator.pop(context);
              navigate(const CategoryScreen());
            },
          ),

          const Divider(height: 32, thickness: 1),

          // ===== GRUPO 2: Gerenciamento de Dados & Utilitários =====
          _buildSectionHeader(context, 'Gerenciamento de Dados', Icons.storage),
          
          ListTile(
            leading: const Icon(Icons.import_export, color: Colors.blue),
            title: const Text('Importação & Exportação'),
            subtitle: const Text('Planilhas e Agenda Google'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              onImportExportTap();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text(t('menu_manage_data')),
            subtitle: const Text('Backup, Nuvem, Estatísticas'),
            onTap: () {
              Navigator.pop(context);
              navigate(const DataManagementScreen());
            },
          ),

          const Divider(height: 32, thickness: 1),

          // ===== GRUPO 3: Suporte, Ajuda & Legal =====
          _buildSectionHeader(context, 'Suporte & Informações', Icons.help_outline),
          
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(t('menu_help')),
            onTap: () {
              Navigator.pop(context);
              navigate(const HelpScreen());
            },
          ),
          

          
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(t('menu_about')),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Política de Privacidade'),
            onTap: () {
              Navigator.pop(context);
              navigate(const PrivacyPolicyScreen());
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.orange),
            title: const Text('Excluir Conta'),
            onTap: () {
              Navigator.pop(context);
              navigate(const DeleteAccountScreen());
            },
          ),

          const Divider(height: 32, thickness: 1),
          
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: Text(t('menu_exit'), style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
          ),
          
          const SizedBox(height: 80), // Espaço extra para scroll completo
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('about_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('about_version')),
            const SizedBox(height: 10),
            Text(t('about_description')),
            const SizedBox(height: 20),
            Text(t('about_developed_by'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(t('about_company')),
            const SizedBox(height: 5),
            Text(t('about_email_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(t('about_email')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }
}
