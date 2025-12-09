import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '5511999999999'; 
    const message = 'Olá, preciso de ajuda com o FinAgeVoz.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
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
          title: const Text('Manual do Usuário'),
          actions: [
            IconButton(
              icon: const Icon(Icons.support_agent),
              onPressed: () => _openWhatsApp(context),
              tooltip: "Falar com Suporte",
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Comandos"),
              Tab(text: "Transações"),
              Tab(text: "Agenda"),
              Tab(text: "API"),
              Tab(text: "Limites"),
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
            "Como falar?", 
            "Toque no botão de microfone na tela inicial e fale naturalmente. O app usa Inteligência Artificial para entender sua intenção.",
            icon: Icons.mic
          ),
          _buildSectionHeader("Exemplos Práticos"),
          _buildHelpItem(
            "Adicionar Finanças", 
            "• 'Gastei 50 reais na padaria'\n• 'Recebi 1000 reais de aluguel'\n• 'Compra parcelada em 3x de 200 reais no cartão'",
          ),
          _buildHelpItem(
            "Adicionar Eventos", 
            "• 'Consulta médica dia 15 às 14 horas'\n• 'Almoço com a mãe domingo'\n• 'Lembrete de tomar remédio todo dia às 8 da manhã'",
          ),
          _buildHelpItem(
            "Consultas (Query)", 
            "• 'Quanto gastei com mercado este mês?'\n• 'Tenho algum médico marcado esta semana?'\n• 'Qual meu saldo atual?'",
          ),
          _buildHelpItem(
            "Navegação e Ações", 
            "• 'Ligar para João'\n• 'Abrir Agenda'\n• 'Ir para Finanças'",
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
            "Gestão Financeira", 
            "Controle completo de suas receitas e despesas com suporte a categorias, parcelamentos e relatórios.",
            icon: Icons.attach_money
        ),
        _buildSectionHeader("Funcionalidades"),
        _buildHelpItem(
          "Lançamentos", 
          "Registre gastos e ganhos. Você pode categorizar cada item (Alimentação, Transporte, Saúde, etc).",
        ),
        _buildHelpItem(
          "Parcelamentos Inteligentes", 
          "Ao lançar uma despesa parcelada (ex: 'Compra de TV em 10x'), o app cria automaticamente as previsões futuras. O saldo é ajustado mês a mês.",
        ),
        _buildHelpItem(
          "Imobilizado", 
          "Use a categoria 'Imobilizado' para registrar bens de valor durável, como compra e venda de imóveis ou veículos.",
        ),
        _buildHelpItem(
          "Relatórios Gráficos", 
          "Na tela de Finanças, toque em 'Relatórios' para ver gráficos de pizza e evolução mensal, além de exportar extratos em PDF.",
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
            "Agenda Inteligente", 
            "Sua agenda reúne 4 tipos de itens: Compromissos, Aniversários, Remédios e Pagamentos.",
            icon: Icons.calendar_month
        ),
        _buildSectionHeader("Funcionalidades de Agenda"),
        _buildHelpItem(
          "Abas Organizadoras", 
          "Navegue pelas abas no topo para ver listas específicas (ex: só Aniversários ou só Pagamentos).",
        ),
        _buildHelpItem(
          "Relatórios PDF", 
          "Toque no ícone PDF no topo da agenda. Você pode filtrar por data e tipo de item para gerar relatórios detalhados.",
        ),
        _buildHelpItem(
          "Eventos Virtuais", 
          "Parcelas de compras e horários de remédios são gerados automaticamente na agenda para visualização diária.",
        ),
        
        const Divider(height: 40),
        _buildSectionHeader("Sáude & Remédios"),
        _buildHelpItem(
          "Cadastro e Controle", 
          "Cadastre remédios com foto, dosagem e estoque. O app avisa quando o remédio estiver acabando.",
        ),
        _buildHelpItem(
          "Posologia", 
          "Defina intervalos (ex: 8 em 8 horas). O app calcula e notifica todos os horários futuros.",
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
            "Integração IA", 
            "O FinAgeVoz utiliza a poderosa API da Groq para entender seus comandos de voz com precisão.",
            icon: Icons.api
        ),
        _buildSectionHeader("Configuração"),
        _buildHelpItem(
          "Chave de API (API Key)", 
          "Para o funcionamento dos comandos de voz inteligentes, é necessário configurar uma chave da Groq API nas Configurações do app.",
        ),
        _buildHelpItem(
          "Privacidade", 
          "Seus comandos de texto são enviados para a API apenas para processamento de linguagem natural. Nenhum dado financeiro sensível é armazenado nos servidores da IA.",
        ),
        _buildHelpItem(
          "Backup na Nuvem", 
          "Usuários Premium têm seus dados sincronizados de forma segura na nuvem (Firebase), permitindo acesso em múltiplos dispositivos.",
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
            "Planos e Limites", 
            "Entenda as diferenças entre o uso Gratuito e o Plano Premium.",
            icon: Icons.lock_open
        ),
        _buildSectionHeader("Comparativo"),
        Card(
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: const [
               TableRow(
                 decoration: BoxDecoration(color: Colors.grey),
                 children: [
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Recurso", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Gratuito", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Premium", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                 ]
               ),
               TableRow(children: [
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Comandos de Voz")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Limitado (50/mês)")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Ilimitado")),
               ]),
               TableRow(children: [
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Backup Nuvem")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Não")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Sim")),
               ]),
               TableRow(children: [
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Relatórios PDF")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Básico")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Avançado")),
               ]),
               TableRow(children: [
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Anexos")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("50 MB")),
                   Padding(padding: EdgeInsets.all(8.0), child: Text("Ilimitado")),
               ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Versão 1.2.0',
            style: TextStyle(color: Colors.grey),
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
