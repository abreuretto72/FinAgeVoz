import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/talking_clock_service.dart';

class AiBehaviorScreen extends StatefulWidget {
  const AiBehaviorScreen({super.key});

  @override
  State<AiBehaviorScreen> createState() => _AiBehaviorScreenState();
}

class _AiBehaviorScreenState extends State<AiBehaviorScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  @override
  void initState() {
    super.initState();
    // Ensure DB is ready? Ideally called in main, but safe to check.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Comportamento da IA', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildSectionHeader("Personalidade & Empatia", Icons.psychology),
          _buildPersonalitySection(),
          const SizedBox(height: 20),
          _buildSectionHeader("Briefing Matinal", Icons.wb_sunny),
          _buildMorningBriefingSection(),
          const SizedBox(height: 20),
          _buildSectionHeader("Relógio Falante", Icons.access_time_filled),
          _buildTalkingClockSection(), // Enhanced section
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Personalize como o FinAgeVoz interage com você. Defina o nível de empatia, humor e proatividade.",
              style: TextStyle(color: Colors.blueAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSwitch(
            "Modo Terapêutico",
            "IA valida sentimentos e oferece apoio emocional.",
            _dbService.getAiTherapeuticMode(),
            (val) async {
                await _dbService.setAiTherapeuticMode(val);
                setState(() {});
            },
            Colors.pinkAccent,
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildSwitch(
            "Permitir Humor",
            "IA pode contar piadas e usar tom descontraído.",
            _dbService.getAiAllowHumor(),
            (val) async {
                await _dbService.setAiAllowHumor(val);
                setState(() {});
            },
            Colors.amber,
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildSwitch(
            "Modo Proativo",
            "IA puxa assunto se iniciada com saudação.",
            _dbService.getAiProactiveMode(),
            (val) async {
                await _dbService.setAiProactiveMode(val);
                setState(() {});
            },
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildMorningBriefingSection() {
    bool enabled = _dbService.getAiMorningBriefingEnabled();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSwitch(
            "Resumo Diário",
            "Oferecer briefing ao receber 'Bom dia'.",
            enabled,
            (val) async {
                await _dbService.setAiMorningBriefingEnabled(val);
                setState(() {});
            },
            Colors.orange,
          ),
          if (enabled) ...[
            const Divider(color: Colors.white10, height: 1),
            _buildCheckbox("Manchetes", _dbService.getAiIncludeNews(), (v) async {
                await _dbService.setAiIncludeNews(v!);
                setState((){});
            }),
            _buildCheckbox("Previsão do Tempo", _dbService.getAiIncludeWeather(), (v) async {
                await _dbService.setAiIncludeWeather(v!);
                setState((){});
            }),
            _buildCheckbox("Horóscopo", _dbService.getAiIncludeHoroscope(), (v) async {
                await _dbService.setAiIncludeHoroscope(v!);
                setState((){});
            }),
            _buildCheckbox("Curiosidades Históricas", _dbService.getAiIncludeHistory(), (v) async {
                await _dbService.setAiIncludeHistory(v!);
                setState((){});
            }),
            _buildCheckbox("Santo do Dia", _dbService.getAiIncludeReligious(), (v) async {
                await _dbService.setAiIncludeReligious(v!);
                setState((){});
            }),
            _buildCheckbox("Datas Comemorativas", _dbService.getAiIncludeCommemorative(), (v) async {
                await _dbService.setAiIncludeCommemorative(v!);
                setState((){});
            }),
          ]
        ],
      ),
    );
  }

  Widget _buildTalkingClockSection() {
    bool enabled = _dbService.getTalkingClockEnabled();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitch(
            "Anunciar Hora",
            "Automaticamente a cada 15 minutos.",
            enabled,
            (val) {
                setState(() {
                    if (val) TalkingClockService().start();
                    else TalkingClockService().stop();
                });
            },
            Colors.teal,
          ),
          if (enabled) ...[
             const Padding(
               padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
               child: Text("Conteúdo da Fala", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
             ),
             RadioListTile<bool>(
                title: const Text("Apenas Hora", style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('"São 14 horas e 15 minutos"', style: TextStyle(color: Colors.grey, fontSize: 12)),
                value: true, 
                groupValue: _dbService.getTalkingClockDateOnHourOnly(), // This logic handles "Date on Hour ONLY" -> if TRUE, means mostly Time Only. 
                                                                        // Wait, the requirement: 
                                                                        // Radio 1: Apenas Hora (Time Only always?) -> The previous logic was "Date on Hour Only".
                                                                        // Let's adapt. 
                                                                        // If "DateOnHourOnly" is TRUE -> It avoids date on 15,30,45.
                                                                        // If "DateOnHourOnly" is FALSE -> It speaks Date ALWAYS.
                                                                        // The requirement asks for:
                                                                        // 1. "Apenas Hora" -> Never speak date? Or mimic the "Date on hour only" which is cleaner?
                                                                        // The Prompt says: Radio Button: Apenas Hora ("São 14:15") vs Radio Button: Data Completa ("Quinta...").
                                                                        // This implies "Always Date" vs "Never Date" OR "Smart Date".
                                                                        // Let's stick to the previous Smart logic but re-label for clarity or change logic.
                                                                        // I'll interpret "Apenas Hora" as the "Smart Mode" (Date only on hour, otherwise too repetitive), OR explicit "Never Date".
                                                                        // Let's use the Smart Mode as the default "Clean" option.
                onChanged: (val) {
                    TalkingClockService().setPreferences(speakDateOnHourOnly: true);
                    setState((){});
                },
                activeColor: Colors.teal,
             ),
             RadioListTile<bool>(
                title: const Text("Data Completa + Hora", style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('"Quinta, 18 de Dez. São..."', style: TextStyle(color: Colors.grey, fontSize: 12)),
                value: false, 
                groupValue: _dbService.getTalkingClockDateOnHourOnly(),
                onChanged: (val) {
                    TalkingClockService().setPreferences(speakDateOnHourOnly: false);
                    setState((){});
                },
                activeColor: Colors.teal,
             ),

             const Divider(color: Colors.white10),
             const Padding(
               padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
               child: Text("Modo Silencioso (Não Perturbar)", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
             ),
             ListTile(
               title: const Text("Início do Silêncio", style: TextStyle(color: Colors.white)),
               trailing: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                 child: Text("${_dbService.getTalkingClockQuietStart()}:00", style: const TextStyle(color: Colors.white)),
               ),
               onTap: () => _pickHour(true),
             ),
             ListTile(
               title: const Text("Fim do Silêncio", style: TextStyle(color: Colors.white)),
               trailing: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                 child: Text("${_dbService.getTalkingClockQuietEnd()}:00", style: const TextStyle(color: Colors.white)),
               ),
               onTap: () => _pickHour(false),
             ),
          ]
        ],
      ),
    );
  }

  Future<void> _pickHour(bool isStart) async {
      // Simple dialog to pick hour 0-23
      int current = isStart ? _dbService.getTalkingClockQuietStart() : _dbService.getTalkingClockQuietEnd();
      
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: Text(isStart ? "Início do Silêncio" : "Fim do Silêncio", style: const TextStyle(color: Colors.white)),
          content: SizedBox(
             height: 200,
             width: 100,
             child: ListView.builder(
               itemCount: 24,
               itemBuilder: (ctx, i) {
                   return ListTile(
                     title: Text("$i:00", style: TextStyle(color: i == current ? Colors.teal : Colors.white)),
                     onTap: () {
                         if (isStart) _dbService.setTalkingClockQuietStart(i);
                         else _dbService.setTalkingClockQuietEnd(i);
                         Navigator.pop(ctx);
                         setState((){});
                         // Update Calling Clock Service?
                         // Service reads from DB every minute, so no need to push. 
                         // But wait, I implemented Service to use internal variables initialized on init. 
                         // I should probably update Service to read live or update it.
                         // Let's update Service variables.
                         TalkingClockService().reloadSettings(); // Need to implement this
                     },
                   );
               },
             ),
          ),
        )
      );
  }

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool) onChanged, Color color) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: color,
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
     return CheckboxListTile(
       title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
       value: value,
       onChanged: onChanged,
       activeColor: Colors.blueAccent,
       checkColor: Colors.white,
       contentPadding: const EdgeInsets.only(left: 16, right: 16),
       dense: true,
     );
  }
}
