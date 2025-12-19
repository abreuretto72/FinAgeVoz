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
      length: 6,
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
              const Tab(text: 'Comportamento IA'), // Using hardcoded string for now or add to localization
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
            _buildAiBehaviorTab(),
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
            t('help_quick_questions_title'), 
            t('help_quick_questions_desc'),
          ),
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
          
          _buildSectionHeader("Novos Comandos"),
          _buildHelpItem(
            "Saudações Personalizadas", 
            "Fale 'Bom dia', 'Boa tarde' ou 'Boa noite' e a IA vai te cumprimentar pelo nome. Com 'Bom dia', você recebe o briefing matinal completo.",
          ),
          _buildHelpItem(
            "Briefing Matinal", 
            "Comando: 'Bom dia' → Receba almanaque cultural (história, santo do dia, datas comemorativas), notícias gerais, notícias do seu time, mercado financeiro, horóscopo e números da sorte.",
          ),
          _buildHelpItem(
            "Notícias a Qualquer Hora", 
            "Comandos: 'Quais as notícias?', 'Me conte as manchetes', 'O que está acontecendo?' → Receba notícias gerais, do seu time (classificação + último jogo) e do mercado (Bovespa + ações).",
          ),
          _buildHelpItem(
            "Horóscopo", 
            "Após configurar sua data de nascimento, pergunte 'Qual meu horóscopo?' para receber previsão astral + números da sorte.",
          ),
          
          _buildSectionHeader("Inteligência Emocional"),
          _buildHelpItem(
            "Expressões de Sentimentos", 
            "A IA reconhece quando você expressa emoções e responde com empatia:\n• 'Estou cansado' → Apoio e sugestão de descanso\n• 'Estou estressado' → Palavras de conforto\n• 'Estou feliz' → Compartilha sua alegria\n• 'Estou triste' → Oferece apoio emocional\n• 'Estou com fome' → Sugere fazer uma pausa",
          ),
          _buildHelpItem(
            "Cortesia e Despedidas", 
            "Comandos sociais:\n• 'Obrigado' → Resposta cordial\n• 'Tchau' / 'Até logo' → Despedida amigável\n• 'Oi' / 'Olá' → Saudação calorosa",
          ),
          
          _buildSectionHeader("Humor e Entretenimento"),
          _buildHelpItem(
            "Piadas e Diversão", 
            "Peça para a IA te fazer rir:\n• 'Conte uma piada' → Piada sobre tecnologia\n• 'Me faz rir' → Piada sobre finanças/trabalho\n• 'Quero uma piada' → Piada de números\n• 'Conta uma piada de finanças' → Piada sobre dinheiro\n• 'Me diverte' → Piada sobre programação\n\nTodas as piadas são limpas e apropriadas para todas as idades!",
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
        _buildHelpItem(
          t('help_balance_reports_title'), 
          t('help_balance_desc'),
        ),
        
        _buildSectionHeader("Importação e Exportação"),
        _buildHelpItem(
          "Exportar Dados", 
          "Você pode exportar todas as suas transações para um arquivo CSV:\n• Vá em Menu → Finanças → Ícone de 3 pontos (⋮) → Exportar CSV\n• O arquivo será salvo na pasta Downloads do seu dispositivo\n• Use para backup, análise em Excel ou migração de dados\n• Formato: data, descrição, valor, tipo, categoria, subcategoria, status de pagamento",
        ),
        _buildHelpItem(
          "Importar Dados", 
          "Importe transações de arquivos CSV:\n• Vá em Menu → Finanças → Ícone de 3 pontos (⋮) → Importar CSV\n• Selecione o arquivo CSV do seu dispositivo\n• O arquivo deve seguir o formato: data, descrição, valor, tipo, categoria\n• Útil para migrar dados de outros apps ou restaurar backups\n• As transações importadas serão mescladas com as existentes",
        ),
        _buildHelpItem(
          "Backup e Sincronização", 
          "Para backup automático na nuvem:\n• Configure o Google Drive em Menu → Sincronização\n• Seus dados serão salvos automaticamente\n• Restaure em qualquer dispositivo fazendo login com a mesma conta",
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
        _buildSectionHeader("Importação e Exportação"),
        _buildHelpItem(
          "Exportar Agenda", 
          "Você pode exportar todos os seus eventos de agenda para um arquivo CSV:\n• Vá em Menu → Agenda → Ícone de 3 pontos (⋮) → Exportar CSV\n• O arquivo será salvo na pasta Downloads do seu dispositivo\n• Inclui: compromissos, tarefas, aniversários, pagamentos, remédios\n• Use para backup ou compartilhar sua agenda",
        ),
        _buildHelpItem(
          "Importar Agenda", 
          "Importe eventos de arquivos CSV:\n• Vá em Menu → Agenda → Ícone de 3 pontos (⋮) → Importar CSV\n• Selecione o arquivo CSV do seu dispositivo\n• O arquivo deve seguir o formato: tipo, título, data, hora, descrição\n• Útil para migrar dados de outros apps ou restaurar backups\n• Os eventos importados serão mesclados com os existentes",
        ),
        _buildHelpItem(
          "Sincronização com Google Calendar", 
          "Integre com sua agenda do Google:\n• Configure em Menu → Agenda → Sincronizar com Google\n• Seus eventos do Google Calendar aparecerão no app\n• Eventos criados no app podem ser salvos no Google Calendar\n• Mantenha tudo sincronizado entre dispositivos",
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

  Widget _buildAiBehaviorTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      children: [
        _buildInfoCard(
            "Cérebro da IA", 
            "Controle total sobre a personalidade, conhecimento e habilidades do seu assistente FinAgeVoz.",
            icon: Icons.psychology
        ),
        
        _buildSectionHeader("Perfil Pessoal"),
        _buildHelpItem(
          "Seu Nome", 
          "Configure seu primeiro nome em Configurações > Geral. A IA vai te chamar pelo nome em todas as interações (ex: 'Bom dia, João!').",
        ),
        _buildHelpItem(
          "Data de Nascimento", 
          "Necessária para o Horóscopo. Digite manualmente no formato DD/MM/AAAA. A IA calcula seu signo automaticamente.",
        ),
        _buildHelpItem(
          "Time do Coração", 
          "Configure seu time favorito. A IA vai incluir notícias sobre ele no briefing matinal e comentar sobre jogos quando relevante.",
        ),
        
        _buildSectionHeader("Personalidade"),
        _buildHelpItem(
          "Modo Terapêutico", 
          "Quando ativo, a IA oferece apoio emocional se você disser que está cansado ou estressado. Se desligado, ela é mais objetiva.",
        ),
        _buildHelpItem(
          "Humor & Proatividade", 
          "Permite que a IA conte piadas e inicie conversas proativamente ao abrir o app.",
        ),
        
        _buildSectionHeader("Briefing Matinal (Bom Dia)"),
        _buildHelpItem(
          "Almanaque Cultural", 
          "Escolha o que quer ouvir: Curiosidades Históricas, Santo do Dia, Datas Comemorativas. A IA gera conteúdo real sobre a data atual.",
        ),
        _buildHelpItem(
          "Notícias do Dia", 
          "Receba manchetes gerais, notícias do seu time (classificação + último jogo), e resumo do mercado (Bovespa + ações).",
        ),
        _buildHelpItem(
          "Previsão do Tempo", 
          "Informação simulada sobre o clima do dia (sol, nuvens, etc.).",
        ),
        _buildHelpItem(
          "Horóscopo & Sorte", 
          "Previsão astral baseada no seu signo + 6 números da sorte para Mega-Sena (1-60).",
        ),
        
        _buildSectionHeader("Relógio Falante"),
        _buildHelpItem(
          "Anúncio Automático", 
          "O app fala a hora a cada 15 minutos. Útil para deficientes visuais ou para focar no tempo.",
        ),
        _buildHelpItem(
          "Horário de Silêncio", 
          "Configure quando NÃO quer ser incomodado (ex: 22h às 07h). O relógio respeita seu descanso.",
        ),
        _buildHelpItem(
          "Formato da Fala", 
          "Escolha entre 'Apenas Hora' ou 'Data Completa + Hora' (ex: 'Quinta, 18 de Dezembro. São 14 horas.').",
        ),
        
        _buildSectionHeader("Como Usar"),
        _buildHelpItem(
          "Comando: Bom Dia", 
          "Fale 'Bom dia' para receber o briefing completo personalizado com seu nome, almanaque, notícias, horóscopo e números da sorte.",
        ),
        _buildHelpItem(
          "Comando: Notícias", 
          "Fale 'Quais as notícias?' a qualquer hora para ouvir manchetes gerais, notícias do seu time e resumo do mercado.",
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
