import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/medicine_model.dart';
import '../../services/database_service.dart';

class PosologyFormScreen extends StatefulWidget {
  final String remedioId;
  final Posologia? posologia;

  const PosologyFormScreen({super.key, required this.remedioId, this.posologia});

  @override
  State<PosologyFormScreen> createState() => _PosologyFormScreenState();
}

class _PosologyFormScreenState extends State<PosologyFormScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  Posologia? _lastSavedPosologia;

  late TextEditingController _qtdController;
  late TextEditingController _instrucoesController;
  
  String _unidadeDose = 'Comprimido(s)';
  final List<String> _unidades = ['Comprimido(s)', 'Cápsula(s)', 'mL', 'Gotas', 'Aplicação', 'Injeção'];
  
  String _frequenciaTipo = 'INTERVALO';
  // "INTERVALO", "HORARIOS_FIXOS", "VEZES_DIA", "SE_NECESSARIO"
  
  // Condicionais
  TextEditingController _intervaloHorasController = TextEditingController(text: '8');
  TextEditingController _vezesDiaController = TextEditingController(text: '3');
  
  // Horarios fixos
  List<TimeOfDay> _horariosFixos = [const TimeOfDay(hour: 8, minute: 0)];

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _usoContinuo = false;
  bool _tomarComAlimento = false;
  bool _exigirConfirmacao = true;

  @override
  void initState() {
    super.initState();
    _lastSavedPosologia = widget.posologia;
    final p = widget.posologia;
    _qtdController = TextEditingController(text: p?.quantidadePorDose.toString() ?? '1');
    _instrucoesController = TextEditingController(text: p?.instrucoesExtras ?? '');
    
    if (p != null) {
      _unidadeDose = p.unidadeDose;
      
      // Normalize Frequency Type to ensure it matches Dropdown items
      const validTypes = ['INTERVALO', 'HORARIOS_FIXOS', 'VEZES_DIA', 'SE_NECESSARIO'];
      if (validTypes.contains(p.frequenciaTipo)) {
         _frequenciaTipo = p.frequenciaTipo;
      } else {
         // Fallback/Correction for legacy/mismatched values
         final upper = p.frequenciaTipo.toUpperCase();
         if (validTypes.contains(upper)) {
            _frequenciaTipo = upper;
         } else {
             // If completely invalid, keep default 'INTERVALO' or derived? 
             // We keep default 'INTERVALO' set at declaration.
             // Print debug info
             print("DEBUG: Invalid Frequency Type '${p.frequenciaTipo}'. Reverting to INTERVALO.");
         }
      }

      if (!_unidades.contains(_unidadeDose)) _unidades.add(_unidadeDose);

      _intervaloHorasController.text = p.intervaloHoras?.toString() ?? '8';
      _vezesDiaController.text = p.vezesAoDia?.toString() ?? '3';
      
      // If legacy VEZES_DIA is found but not in our "Strict" dropdown list, 
      // we might want to convert it or show it. 
      // But we removed it from dropdown. So we must add it back OR map it.
      // Let's add it back to valid types in logic but maybe not in UI? 
      // No, if it's in DB, we must show it or migration is needed.
      // PROPOSAL: Convert VEZES_DIA to INTERVALO (approx) for display, or just mapping.
      // For now, if p.frequenciaTipo is VEZES_DIA, I will override it to INTERVALO in the UI state to allow user to re-configure properly.
      
      if (p.frequenciaTipo == 'VEZES_DIA') {
          _frequenciaTipo = 'INTERVALO';
          // Estimate interval: 24 / times
          if (p.vezesAoDia != null && p.vezesAoDia! > 0) {
             _intervaloHorasController.text = (24 / p.vezesAoDia!).floor().toString();
          }
      }
      
      if (p.horariosDoDia != null) {
        try {
          _horariosFixos = p.horariosDoDia!.map((s) {
             final parts = s.split(':');
             return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }).toList();
        } catch (e) {
          print("DEBUG: Error parsing time strings: $e");
          _horariosFixos = [];
        }
      }

      _dataInicio = p.inicioTratamento;
      _dataFim = p.fimTratamento;
      _usoContinuo = p.usoContinuo;
      _tomarComAlimento = p.tomarComAlimento ?? false;
      _exigirConfirmacao = p.exigirConfirmacao;
    }
  }

  bool _hasUnsavedChanges() {
      final qtd = _qtdController.text;
      final instr = _instrucoesController.text;
      
      if (_lastSavedPosologia == null) {
          if (qtd != '1') return true;
          if (instr.isNotEmpty) return true;
          if (_unidadeDose != 'Comprimido(s)') return true;
          if (_frequenciaTipo != 'INTERVALO') return true;
          return false; 
      }
      
      final last = _lastSavedPosologia!;
      bool qtdChanged = qtd != last.quantidadePorDose.toString();
      if (last.quantidadePorDose % 1 == 0) {
         if (qtd == last.quantidadePorDose.toInt().toString()) qtdChanged = false;
      }
      
      if (qtdChanged) return true;
      if (instr != (last.instrucoesExtras ?? '')) return true;
      if (_unidadeDose != last.unidadeDose) return true;
      if (_frequenciaTipo != last.frequenciaTipo) return true;
      return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
           final l10n = AppLocalizations.of(context)!;
           final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                 title: Text(l10n.discardChanges),
                 content: Text(l10n.unsavedPosologyMessage),
                 actions: [
                    TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx, false)),
                    TextButton(child: Text(l10n.exit), onPressed: () => Navigator.pop(ctx, true)),
                 ]
              )
           );
           if (confirm == true) Navigator.of(context).pop();
        } else {
           Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.posologia == null ? AppLocalizations.of(context)!.newPosology : AppLocalizations.of(context)!.editPosology),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Builder(
                 builder: (context) => Text(AppLocalizations.of(context)!.dose, style: const TextStyle(fontWeight: FontWeight.bold))
               ),
               Row(
                 children: [
                    Expanded(
                      child: Builder(
                        builder: (context) => TextFormField(
                          controller: _qtdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity),
                          validator: (v) => v!.isEmpty ? AppLocalizations.of(context)!.required : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) => DropdownButtonFormField<String>(
                          value: _unidadeDose,
                          items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => _unidadeDose = v!),
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.unit),
                        ),
                      ),
                    )
                 ],
               ),
               const SizedBox(height: 24),
               const Text("Frequência", style: TextStyle(fontWeight: FontWeight.bold)),
               DropdownButtonFormField<String>(
                 value: _frequenciaTipo,
                 decoration: const InputDecoration(labelText: 'Tipo de Frequência'),
                 items: const [
                   DropdownMenuItem(value: 'INTERVALO', child: Text('Intervalo Fixo (ex: 8 em 8h)')),
                   DropdownMenuItem(value: 'HORARIOS_FIXOS', child: Text('Horários Específicos (ex: 08:00)')),
                   DropdownMenuItem(value: 'SE_NECESSARIO', child: Text('Se Necessário (SOS)')),
                 ],
                 onChanged: (v) => setState(() => _frequenciaTipo = v!),
               ),
               const SizedBox(height: 16),
               
               if (_frequenciaTipo == 'INTERVALO')
                 TextFormField(
                   controller: _intervaloHorasController,
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(labelText: 'A cada quantas horas?', suffixText: 'horas'),
                   validator: (v) => _frequenciaTipo == 'INTERVALO' && (v!.isEmpty || int.tryParse(v) == null) ? 'Inválido' : null,
                 ),
                 
               if (_frequenciaTipo == 'VEZES_DIA')
                 TextFormField(
                   controller: _vezesDiaController,
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(labelText: 'Quantas vezes ao dia?'),
                   validator: (v) => _frequenciaTipo == 'VEZES_DIA' && (v!.isEmpty || int.tryParse(v) == null) ? 'Inválido' : null,
                 ),

               if (_frequenciaTipo == 'HORARIOS_FIXOS') ...[
                  const Text("Horários definidos:"),
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._horariosFixos.map((t) => Chip(
                        label: Text(t.format(context)),
                        onDeleted: () => setState(() => _horariosFixos.remove(t)),
                      )),
                      ActionChip(
                        label: const Icon(Icons.add, size: 16),
                        onPressed: _pickTime,
                      )
                    ],
                  ),
                  if (_horariosFixos.isEmpty)
                    const Text("Adicione pelo menos um horário", style: TextStyle(color: Colors.red)),
               ],

               const SizedBox(height: 24),
               const Text("Duração do Tratamento", style: TextStyle(fontWeight: FontWeight.bold)),
               ListTile(
                 title: const Text("Início"),
                 subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dataInicio)),
                 trailing: const Icon(Icons.calendar_today),
                 onTap: _pickStartDate,
               ),
               SwitchListTile(
                 title: const Text("Uso Contínuo"),
                 value: _usoContinuo,
                 onChanged: (v) => setState(() {
                   _usoContinuo = v;
                   if (v) _dataFim = null;
                 }),
               ),
               if (!_usoContinuo)
                 ListTile(
                   title: const Text("Fim (Opcional)"),
                   subtitle: Text(_dataFim == null ? "Sem data final" : DateFormat('dd/MM/yyyy').format(_dataFim!)),
                   trailing: const Icon(Icons.calendar_today),
                   onTap: _pickEndDate,
                 ),
                 
               const SizedBox(height: 24),
               const Text("Outros", style: TextStyle(fontWeight: FontWeight.bold)),
               SwitchListTile(
                 title: const Text("Tomar com alimento?"),
                 value: _tomarComAlimento,
                 onChanged: (v) => setState(() => _tomarComAlimento = v),
               ),
               SwitchListTile(
                 title: const Text("Exigir confirmação?"),
                 subtitle: const Text("Vou te perguntar se você tomou"),
                 value: _exigirConfirmacao,
                 onChanged: (v) => setState(() => _exigirConfirmacao = v),
               ),
               TextFormField(
                 controller: _instrucoesController,
                 decoration: const InputDecoration(labelText: 'Instruções Extras (ex: estômago vazio)'),
               ),
               
               // Summary Section
               if (_frequenciaTipo.isNotEmpty)
                  Container(
                     margin: const EdgeInsets.only(top: 16),
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                     ),
                     child: Column(
                        children: [
                           const Text("RESUMO DO TRATAMENTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                           const SizedBox(height: 8),
                           Text(
                              _buildSummaryText(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                           ),
                        ],
                     ),
                  ),
             ],
           ), // Column
          ), // Padding
        ), // Form
      ), // SingleChild
     ), // Scaffold
    ); // PopScope
  }

  String _buildSummaryText() {
     String text = "Tomar ${_qtdController.text} $_unidadeDose";
     
     if (_frequenciaTipo == 'INTERVALO') {
        text += " a cada ${_intervaloHorasController.text} horas";
     } else if (_frequenciaTipo == 'HORARIOS_FIXOS') {
        text += " nos horários: ${_horariosFixos.map((t) => t.format(context)).join(', ')}";
     } else if (_frequenciaTipo == 'VEZES_DIA') {
        text += " ${_vezesDiaController.text} vezes ao dia";
     } else if (_frequenciaTipo == 'SE_NECESSARIO') {
        text += " se necessário";
     }
     
     if (_usoContinuo) {
        text += " (Uso Contínuo)";
     } else if (_dataFim != null) {
        text += " até ${DateFormat('dd/MM/yyyy').format(_dataFim!)}";
     }
     
     return text;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      setState(() {
        if (!_horariosFixos.any((element) => element.hour == t.hour && element.minute == t.minute)) {
          _horariosFixos.add(t);
          _horariosFixos.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        }
      });
    }
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context, 
      initialDate: _dataInicio, 
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030)
    );
    if (d != null) {
      if (!mounted) return;
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dataInicio));
      if (t != null) {
        setState(() {
          _dataInicio = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        });
      }
    }
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
       context: context,
       initialDate: _dataFim ?? _dataInicio.add(const Duration(days: 7)),
       firstDate: _dataInicio,
       lastDate: DateTime(2030)
    );
    if (d != null) {
       setState(() => _dataFim = d);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frequenciaTipo == 'HORARIOS_FIXOS' && _horariosFixos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione horários')));
      return;
    }

    final p = Posologia(
      id: widget.posologia?.id ?? const Uuid().v4(),
      remedioId: widget.remedioId,
      quantidadePorDose: double.parse(_qtdController.text.replaceAll(',', '.')),
      unidadeDose: _unidadeDose,
      frequenciaTipo: _frequenciaTipo,
      intervaloHoras: int.tryParse(_intervaloHorasController.text),
      vezesAoDia: int.tryParse(_vezesDiaController.text),
      horariosDoDia: _horariosFixos.map((t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}").toList(),
      inicioTratamento: _dataInicio,
      fimTratamento: _dataFim,
      usoContinuo: _usoContinuo,
      tomarComAlimento: _tomarComAlimento,
      exigirConfirmacao: _exigirConfirmacao,
      instrucoesExtras: _instrucoesController.text,
      criadoEm: widget.posologia?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    if (widget.posologia != null) {
      await _db.updatePosologia(p);
    } else {
      await _db.addPosologia(p);
    }
    
    _lastSavedPosologia = p;
    
    if (mounted) Navigator.pop(context);
  }
}
