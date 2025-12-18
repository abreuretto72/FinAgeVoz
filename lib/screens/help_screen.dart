import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/localization.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _appVersion = '';
  String _buildNumber = '';

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

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '5511999999999'; 
    final message = t('whatsapp_message');
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(t('whatsapp_error'))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('help_manual_title')),
          actions: [
            IconButton(
              icon: const Icon(Icons.support_agent),
              onPressed: () => _openWhatsApp(context),
              tooltip: t('help_support_tooltip'),
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t('help_tab_commands')),
              Tab(text: t('help_tab_transactions')),
              Tab(text: t('help_tab_agenda')),
              Tab(text: t('help_tab_api')),
              Tab(text: t('help_tab_limits')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommandsTab(),
            _buildTransactionsTab(),
            _buildAgendaTab(),
            _buildApiTab(),
            _buildLimitsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandsTab() {
     return ListView(
       physics: const AlwaysScrollableScrollPhysics(),
       padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
       children: [
          _buildInfoCard(
            t('help_how_to_speak_title'), 
            t('help_how_to_speak_desc'),
            icon: Icons.mic
          ),
          _buildSectionHeader(t('help_section_examples')),
          _buildHelpItem(
            t('help_add_finance_title'), 
            t('help_add_finance_desc'),
          ),
          _buildHelpItem(
            t('help_add_event_title'), 
            t('help_add_event_desc'),
          ),
          _buildHelpItem(
            t('help_queries_title'), 
            t('help_queries_desc'),
          ),
          _buildHelpItem(
            t('help_nav_actions_title'), 
            t('help_nav_actions_desc'),
          ),
       ],
     );
  }

  Widget _buildTransactionsTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        _buildInfoCard(
            t('help_module_fin_title'), 
            t('help_module_fin_desc'),
            icon: Icons.attach_money
        ),
        _buildSectionHeader(t('help_section_features')),
        _buildHelpItem(
          t('help_entries_title'), 
          t('help_entries_desc'),
        ),
        _buildHelpItem(
          t('help_smart_installments_title'), 
          t('help_smart_installments_desc'),
        ),
        _buildHelpItem(
          t('help_fixed_assets_title'), 
          t('help_fixed_assets_desc'),
        ),
        _buildHelpItem(
          t('help_graphic_reports_title'), 
          t('help_graphic_reports_desc'),
        ),
      ],
    );
  }

  Widget _buildAgendaTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        _buildInfoCard(
            t('help_smart_agenda_title'), 
            t('help_smart_agenda_desc'),
            icon: Icons.calendar_month
        ),
        _buildSectionHeader(t('help_section_agenda_features')),
        _buildHelpItem(
          t('help_tabs_organization_title'), 
          t('help_tabs_organization_desc'),
        ),
        _buildHelpItem(
          t('help_pdf_reports_title'), 
          t('help_pdf_reports_desc'),
        ),
        _buildHelpItem(
          t('help_virtual_events_title'), 
          t('help_virtual_events_desc'),
        ),
        _buildHelpItem(
          t('help_module_bday_title'),
          t('help_module_bday_desc'),
        ),
        
        // Notification Alert
        Card(
          color: Colors.amber.shade50,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildHelpItem(
               t('help_notifications_title'), 
               t('help_notifications_desc'),
            ),
          ),
        ),
        
        const Divider(height: 40),
        _buildSectionHeader(t('help_section_health')),

        _buildHelpItem(
          t('help_module_meds_title'), 
          t('help_module_meds_desc'),
        ),
      ],
    );
  }

  Widget _buildApiTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        _buildInfoCard(
            t('help_ai_integration_title'), 
            t('help_ai_integration_desc'),
            icon: Icons.api
        ),
        _buildSectionHeader(t('help_section_config')),
        _buildHelpItem(
          t('help_api_key_config_title'), 
          t('help_api_key_config_desc'),
        ),
        _buildHelpItem(
          t('help_privacy_title'), 
          t('help_privacy_desc'),
        ),
        _buildHelpItem(
          t('help_cloud_backup_title'), 
          t('help_cloud_backup_desc'),
        ),
      ],
    );
  }

  Widget _buildLimitsTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        _buildInfoCard(
            t('help_plans_limits_title'), 
            t('help_plans_limits_desc'),
            icon: Icons.lock_open
        ),
        _buildSectionHeader(t('help_section_compare')),
        Card(
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
               TableRow(
                 decoration: const BoxDecoration(color: Colors.grey),
                 children: [
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_resource'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_free'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_premium'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                 ]
               ),
               TableRow(children: [
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_voice_cmds'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_voice_limit'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_unlimited'))),
               ]),
               TableRow(children: [
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_cloud_backup'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_no'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_yes'))),
               ]),
               TableRow(children: [
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_pdf_reports'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_basic'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_advanced'))),
               ]),
               TableRow(children: [
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_attachments'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_50mb'))),
                   Padding(padding: const EdgeInsets.all(8.0), child: Text(t('help_table_unlimited'))),
               ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, {IconData? icon}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 30, color: Colors.blue), const SizedBox(width: 16)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black87, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
