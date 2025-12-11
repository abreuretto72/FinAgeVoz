import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/attachments_service.dart';
import 'package:uuid/uuid.dart';
import '../../models/medicine_model.dart';
import '../../services/database_service.dart';
import 'posology_form_screen.dart';
import '../../models/transaction_model.dart';

class MedicineFormScreen extends StatefulWidget {
  final Remedio? remedio;

  const MedicineFormScreen({super.key, this.remedio});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _nomeController;
  late TextEditingController _nomeGenericoController;
  late TextEditingController _concentracaoController;
  late TextEditingController _indicacaoController;
  late TextEditingController _obsController;
  
  String _formaFarmaceutica = 'Comprimido';
  String _viaAdministracao = 'Oral';

  final List<String> _formas = ['Comprimido', 'Cápsula', 'Gotas', 'Xarope', 'Injeção', 'Pomada', 'Spray', 'Outro'];
  final List<String> _vias = ['Oral', 'Tópico', 'Nasal', 'Injetável', 'Oftálmico', 'Retal', 'Outro'];

  // Local list of posologies (IDs) to display
  List<Posologia> _posologias = [];
  List<String> _attachments = [];

  bool get isEditing => _lastSavedRemedio != null;
  Remedio? _lastSavedRemedio;
  bool _createPurchaseTransaction = false;
  final _purchaseValueController = TextEditingController();

  late String _remedioId;

  @override
  void initState() {
    super.initState();
    _remedioId = widget.remedio?.id ?? const Uuid().v4();
    _lastSavedRemedio = widget.remedio;
    _nomeController = TextEditingController(text: widget.remedio?.nome ?? '');
    _nomeGenericoController = TextEditingController(text: widget.remedio?.nomeGenerico ?? '');
    _concentracaoController = TextEditingController(text: widget.remedio?.concentracao ?? '');
    _indicacaoController = TextEditingController(text: widget.remedio?.indicacao ?? '');
    _obsController = TextEditingController(text: widget.remedio?.observacoesMedico ?? '');
    
    if (widget.remedio?.attachments != null) {
       _attachments = List.from(widget.remedio!.attachments!);
    }
    
    if (isEditing) {
      _formaFarmaceutica = widget.remedio!.formaFarmaceutica;
      if (!_formas.contains(_formaFarmaceutica)) _formas.add(_formaFarmaceutica);
      
      _viaAdministracao = widget.remedio!.viaAdministracao;
      if (!_vias.contains(_viaAdministracao)) _vias.add(_viaAdministracao);
      
      _loadPosologias();
    }
  }

  Future<void> _loadPosologias() async {
    if (!isEditing) return;
    final list = _db.getPosologias(_remedioId);
    setState(() {
      _posologias = list;
    });
  }

  bool _hasUnsavedChanges() {
     final nome = _nomeController.text;
     final gen = _nomeGenericoController.text;
     final conc = _concentracaoController.text;
     final ind = _indicacaoController.text;
     final obs = _obsController.text;

     if (_lastSavedRemedio == null) {
       return nome.isNotEmpty || gen.isNotEmpty || conc.isNotEmpty || ind.isNotEmpty || obs.isNotEmpty;
     }

     return nome != _lastSavedRemedio!.nome ||
            gen != _lastSavedRemedio!.nomeGenerico ||
            _formaFarmaceutica != _lastSavedRemedio!.formaFarmaceutica ||
            conc != _lastSavedRemedio!.concentracao ||
            _viaAdministracao != _lastSavedRemedio!.viaAdministracao ||
            ind != _lastSavedRemedio!.indicacao ||
            obs != _lastSavedRemedio!.observacoesMedico;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (_hasUnsavedChanges()) {
           final l10n = AppLocalizations.of(context)!;
           final bool? confirm = await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                 title: Text(l10n.discardChanges),
                 content: Text(l10n.unsavedChangesMessage),
                 actions: [
                    TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.pop(ctx, false)),
                    TextButton(child: Text(l10n.exit), onPressed: () => Navigator.pop(ctx, true)),
                 ],
              )
           );
           if (confirm == true) {
              navigator.pop();
           }
        } else {
           navigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Remédio' : 'Novo Remédio'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Remédio *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeGenericoController,
                decoration: const InputDecoration(labelText: 'Nome Genérico (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _formas.contains(_formaFarmaceutica) ? _formaFarmaceutica : null,
                      decoration: const InputDecoration(labelText: 'Forma', border: OutlineInputBorder()),
                      items: _formas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _formaFarmaceutica = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _concentracaoController,
                      decoration: const InputDecoration(labelText: 'Concentração (ex: 500mg)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vias.contains(_viaAdministracao) ? _viaAdministracao : null,
                decoration: const InputDecoration(labelText: 'Via de Administração', border: OutlineInputBorder()),
                items: _vias.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _viaAdministracao = v!),
              ),
               const SizedBox(height: 16),
              TextFormField(
                controller: _indicacaoController,
                decoration: const InputDecoration(labelText: 'Indicação (Para que serve?)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _obsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações / Instruções Médicas', border: OutlineInputBorder()),
              ),
              
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(l10n.attachmentsPrescriptions, style: const TextStyle(fontWeight: FontWeight.bold));
                }
              ),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Wrap(
                     spacing: 8,
                     children: [
                        ..._attachments.map((path) => Chip(
                           label: Text(path.split(RegExp(r'[/\\]')).last),
                           onDeleted: () => _deleteAttachment(path),
                        )),
                        ActionChip(
                           avatar: const Icon(Icons.attach_file),
                           label: Text(l10n.add),
                           onPressed: _pickAttachment,
                        )
                     ],
                  );
                }
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              // Purchase Integration Section
              SwitchListTile(
                 title: const Text("Registrar Compra (Financeiro)", style: TextStyle(fontWeight: FontWeight.bold)),
                 subtitle: const Text("Criar despesa no fluxo de caixa"),
                 value: _createPurchaseTransaction,
                 onChanged: (val) => setState(() => _createPurchaseTransaction = val),
                 secondary: const Icon(Icons.attach_money, color: Colors.green),
              ),
              if (_createPurchaseTransaction)
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   child: Column(
                     children: [
                        TextFormField(
                           controller: _purchaseValueController,
                           decoration: const InputDecoration(
                             labelText: 'Valor da Compra (R\$)', 
                             border: OutlineInputBorder(),
                             prefixText: 'R\$ '
                           ),
                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                           validator: (v) => _createPurchaseTransaction && (v == null || v.isEmpty) ? 'Informe o valor' : null,
                        ),
                        const SizedBox(height: 8),
                         const Text("A despesa será lançada com a data de hoje.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   ),
                 ),

              const SizedBox(height: 16),
              const Divider(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text("Posologias (Regras de Tomada)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   if (isEditing)
                     IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue), onPressed: _addPosologia)
                ],
              ),
              if (!isEditing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Salve o remédio primeiro para adicionar posologias.", style: TextStyle(color: Colors.grey)),
                ),
              
              if (isEditing)
                 ..._posologias.map((p) => Card(
                   child: ListTile(
                     title: Text(p.frequenciaTipo == 'INTERVALO' 
                         ? "A cada ${p.intervaloHoras} horas"
                         : p.frequenciaTipo == 'HORARIOS_FIXOS' 
                            ? "Horários: ${p.horariosDoDia?.join(', ')}" 
                            : p.frequenciaTipo),
                     subtitle: Text("${p.quantidadePorDose} ${p.unidadeDose}"),
                     trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editPosologia(p)),
                   ),
                 )),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _save() async {
    await _saveInternal(shouldPop: true);
  }

  Future<bool> _saveInternal({bool shouldPop = true}) async {
    if (!_formKey.currentState!.validate()) return false;

    final id = _remedioId;
    
    // Preserve existing posologies if validating/saving multiple times
    List<String> currentPosologies = widget.remedio?.posologiaIds ?? [];
    final dbRemedio = _db.getRemedio(id);
    if (dbRemedio != null) {
        currentPosologies = dbRemedio.posologiaIds;
    }

    final remedio = Remedio(
      id: id,
      nome: _nomeController.text,
      nomeGenerico: _nomeGenericoController.text,
      formaFarmaceutica: _formaFarmaceutica,
      concentracao: _concentracaoController.text,
      viaAdministracao: _viaAdministracao,
      indicacao: _indicacaoController.text,
      observacoesMedico: _obsController.text,
      criadoEm: widget.remedio?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
      posologiaIds: currentPosologies,
      attachments: _attachments,
    );

    if (dbRemedio != null) {
      await _db.updateRemedio(remedio);
    } else {
      await _db.addRemedio(remedio);
    }
    
    // Process Purchase if enabled
    if (_createPurchaseTransaction) {
       final valorRaw = _purchaseValueController.text.replaceAll(',', '.');
       final valor = double.tryParse(valorRaw) ?? 0.0;
       
       if (valor > 0) {
           final t = Transaction(
               id: const Uuid().v4(),
               description: "Compra Remédio: ${_nomeController.text}",
               amount: valor,
               date: DateTime.now(),
               isExpense: true,
               category: "Saúde", // Default category
               isPaid: true, // Default to Paid as per "Regra de Ouro" for today
           );
           await _db.addTransaction(t);
           
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Despesa registrada com sucesso!')));
           }
       }
    }
    
    _lastSavedRemedio = remedio;

    if (shouldPop && mounted) {
       Navigator.pop(context);
    }
    return true;
  }

  void _addPosologia() async {
    // Ensure medicine is saved (not just draft) before adding children
    // Always save current changes (create or update) before adding children
    bool success = await _saveInternal(shouldPop: false);
    if (!success) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os dados obrigatórios primeiro.')));
       return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PosologyFormScreen(remedioId: _remedioId)),
    );
    _loadPosologias();
  }

  void _editPosologia(Posologia p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PosologyFormScreen(remedioId: _remedioId, posologia: p)),
    );
    _loadPosologias();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
       final savedPath = await AttachmentsService.saveAttachment(File(result.files.single.path!));
       setState(() {
          _attachments.add(savedPath);
       });
    }
  }

  Future<void> _deleteAttachment(String path) async {
      await AttachmentsService.deleteAttachment(path);
      setState(() {
         _attachments.remove(path);
      });
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Remédio?'),
        content: const Text('Isso excluirá o remédio e todas as suas posologias. Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteRemedio(_remedioId);
      if (mounted) Navigator.pop(context);
    }
  }
}
