import 'package:flutter/material.dart';
import '../models/agenda_models.dart';
import '../services/agenda_repository.dart';
import '../services/ai_service.dart';
import '../services/contact_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class AgendaFormScreen extends StatefulWidget {
  final AgendaItem? item;
  final AgendaItem? draftItem;

  const AgendaFormScreen({super.key, this.item, this.draftItem});

  @override
  State<AgendaFormScreen> createState() => _AgendaFormScreenState();
}

class _AgendaFormScreenState extends State<AgendaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AgendaItemType _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repo = AgendaRepository();

  // Specific Fields Controllers
  // Payment
  final _valueController = TextEditingController();
  final _paymentStatusController = TextEditingController(text: 'PENDENTE');
  DateTime? _paymentDate;

  // Medicine
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  double _intervalHours = 8.0;

  // Birthday
  final _personNameController = TextEditingController();
  final _birthdayMessageController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _smsController = TextEditingController();
  String? _selectedRelationship;
  double _notifyDaysBefore = 1.0;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  
  List<Anexo> _attachments = [];
  bool _isGeneratingMessage = false;
  bool _aiGenerated = false;

  @override
  void initState() {
    super.initState();
    
    final sourceItem = widget.item ?? widget.draftItem;
    
    if (sourceItem != null) {
      _selectedType = sourceItem.tipo;
      _titleController.text = sourceItem.titulo;
      _descriptionController.text = sourceItem.descricao ?? '';
      _startDate = sourceItem.dataInicio;
      if (sourceItem.horarioInicio != null) {
        final parts = sourceItem.horarioInicio!.split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      // Load specific fields based on type
      if (_selectedType == AgendaItemType.PAGAMENTO && sourceItem.pagamento != null) {
        _valueController.text = sourceItem.pagamento!.valor.toString();
        _paymentDate = sourceItem.pagamento!.dataVencimento;
        _paymentStatusController.text = sourceItem.pagamento!.status;
      }
      if (_selectedType == AgendaItemType.REMEDIO && sourceItem.remedio != null) {
        _medNameController.text = sourceItem.remedio!.nome;
        _dosageController.text = sourceItem.remedio!.dosagem;
        _intervalHours = sourceItem.remedio!.intervalo.toDouble();
      }
      if (_selectedType == AgendaItemType.ANIVERSARIO && sourceItem.aniversario != null) {
        _personNameController.text = sourceItem.aniversario!.nomePessoa;
        _birthdayMessageController.text = sourceItem.aniversario!.mensagemPadrao ?? '';
        _phoneNumberController.text = sourceItem.aniversario!.telefone ?? '';
        _emailController.text = sourceItem.aniversario!.emailContato ?? '';
        _smsController.text = sourceItem.aniversario!.smsPhone ?? '';
        _selectedRelationship = sourceItem.aniversario!.parentesco;
        _notifyDaysBefore = sourceItem.aniversario!.notificarAntes.toDouble();
        _aiGenerated = sourceItem.aniversario!.mensagemGeradaPorIA;
      }
      
      if (sourceItem.anexos != null) {
        _attachments = List.from(sourceItem.anexos!);
      }

    } else {
      _selectedType = AgendaItemType.COMPROMISSO; // Default
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _startTime = TimeOfDay.now();
    }
    
    // Listener para sincronizar Nome -> Título em Aniversários
    _personNameController.addListener(() {
      if (_selectedType == AgendaItemType.ANIVERSARIO && _titleController.text.isEmpty) {
         // Só copia se o título estiver vazio ou se o usuário não mudou manualmente
         // Simplificação: Vamos forçar a cópia se o título começar com "Aniversário de " ou estiver vazio
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Novo Item' : 'Editar Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            DropdownButtonFormField<AgendaItemType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: AgendaItemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getIconForType(type)),
                      const SizedBox(width: 8),
                      Text(type.toString().split('.').last),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedType != AgendaItemType.ANIVERSARIO)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (_selectedType != AgendaItemType.ANIVERSARIO && (v == null || v.isEmpty)) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Generic Date/Time for Appointment/Task etc
            if (_selectedType == AgendaItemType.COMPROMISSO || 
                _selectedType == AgendaItemType.TAREFA || 
                _selectedType == AgendaItemType.LEMBRETE ||
                _selectedType == AgendaItemType.ANIVERSARIO) ...[
               _buildDateTimePickers(),
               const SizedBox(height: 16),
            ],

            // Specific Fields
            if (_selectedType == AgendaItemType.PAGAMENTO) _buildPaymentFields(),
            if (_selectedType == AgendaItemType.REMEDIO) _buildMedicineFields(),
            if (_selectedType == AgendaItemType.ANIVERSARIO) _buildBirthdayFields(),
            
            const SizedBox(height: 16),
            _buildAttachmentsFields(),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Salvar'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

    );
  }

  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _startDate = d);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: _selectedType == AgendaItemType.ANIVERSARIO ? 'Data do Aniversário' : 'Data'),
              child: Text(_startDate != null ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}" : "Selecione"),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _startTime ?? TimeOfDay.now(),
              );
              if (t != null) setState(() => _startTime = t);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Hora'),
              child: Text(_startTime != null ? _startTime!.format(context) : "Selecione"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text("Detalhes do Pagamento", style: TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          controller: _valueController,
          decoration: const InputDecoration(labelText: 'Valor (R\$)'),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
        ),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _paymentDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _paymentDate = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Vencimento'),
            child: Text(_paymentDate != null ? "${_paymentDate!.day}/${_paymentDate!.month}/${_paymentDate!.year}" : "Selecione"),
          ),
        ),
         DropdownButtonFormField<String>(
              value: _paymentStatusController.text,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['PENDENTE', 'PAGO', 'ATRASADO', 'CANCELADO'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _paymentStatusController.text = val!),
         ),
      ],
    );
  }

  Widget _buildMedicineFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text("Detalhes do Remédio", style: TextStyle(fontWeight: FontWeight.bold)),
        TextFormField(
          controller: _medNameController,
          decoration: const InputDecoration(labelText: 'Nome do Remédio'),
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
        TextFormField(
          controller: _dosageController,
          decoration: const InputDecoration(labelText: 'Dosagem (ex: 500mg)'),
        ),
        const SizedBox(height: 8),
        Text("Intervalo: ${_intervalHours.toInt()} horas"),
        Slider(
          value: _intervalHours,
          min: 1,
          max: 24,
          divisions: 23,
          label: "${_intervalHours.toInt()}h",
          onChanged: (v) => setState(() => _intervalHours = v),
        ),
      ],
    );
  }

  Widget _buildBirthdayFields() {
    final relationships = [
      "Amigo", "Amiga", "Avô", "Avó", "Bisavô", "Bisavó", 
      "Chefe", "Cliente", "Colega de trabalho", "Cunhada", "Cunhado",
      "Enteada", "Enteado", "Esposa", "Esposo", "Filho", "Filha", 
      "Fornecedor", "Genro", "Irmão", "Irmã", "Madrasta", "Mãe", 
      "Namorada", "Namorado", "Neta", "Neto", "Nora", "Outro",
      "Padrasto", "Pai", "Prima", "Primo", "Sobrinha", "Sobrinha-neta",
      "Sobrinho", "Sobrinho-neto", "Sogra", "Sogro", "Tia", "Tia-avó", 
      "Tio", "Tio-avô"
    ];

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text("Detalhes do Aniversário", style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(labelText: 'Nome da Pessoa'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.contacts, color: Colors.blue),
              tooltip: 'Selecionar Contato da Lista',
              onPressed: _pickContactFromDevice,
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: relationships.contains(_selectedRelationship) ? _selectedRelationship : null,
          decoration: const InputDecoration(labelText: 'Grau de Parentesco'),
          items: relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _selectedRelationship = v),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(labelText: 'WhatsApp (com DDD)', prefixIcon: Icon(Icons.chat)),
          keyboardType: TextInputType.phone,
        ),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email)),
          keyboardType: TextInputType.emailAddress,
        ),
        TextFormField(
          controller: _smsController,
          decoration: const InputDecoration(labelText: 'SMS (Celular)', prefixIcon: Icon(Icons.sms)),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _birthdayMessageController,
          decoration: InputDecoration(
            labelText: 'Mensagem de Parabéns',
            suffixIcon: IconButton(
              icon: _isGeneratingMessage 
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                 : const Icon(Icons.auto_awesome, color: Colors.purple),
              onPressed: _generateBirthdayMessage,
              tooltip: "Sugerir mensagem com IA",
            ),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        Text("Notificar ${_notifyDaysBefore.toInt()} dias antes"),
        Slider(
          value: _notifyDaysBefore,
          min: 0, max: 7, divisions: 7,
          label: "${_notifyDaysBefore.toInt()} dias antes",
          onChanged: (v) => setState(() => _notifyDaysBefore = v),
        ),
      ],
    );
  }

  Widget _buildAttachmentsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Anexos", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._attachments.map((a) => Chip(
              avatar: const Icon(Icons.attach_file, size: 16),
              label: Text(a.nome ?? "Arquivo"),
              onDeleted: () => setState(() => _attachments.remove(a)),
            )),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text("Adicionar"),
              onPressed: _pickAttachment,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _attachments.add(Anexo(
          id: const Uuid().v4(),
          tipo: 'ARQUIVO_LOCAL',
          nome: file.name,
          caminhoLocal: file.path,
          tamanhoBytes: file.size,
          criadoEm: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _pickContactFromDevice() async {
     final contactData = await ContactService().pickContact();
     if (contactData != null) {
       setState(() {
          _personNameController.text = contactData['name'] ?? '';
          if (contactData['phone']!.isNotEmpty) _phoneNumberController.text = contactData['phone']!;
          if (contactData['sms']!.isNotEmpty) _smsController.text = contactData['sms']!;
          if (contactData['email']!.isNotEmpty) _emailController.text = contactData['email']!;
       });
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contato selecionado!')));
     }
  }

  Future<void> _generateBirthdayMessage() async {
    final name = _personNameController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Digite o nome primeiro.")));
      return;
    }
    
    setState(() => _isGeneratingMessage = true);
    try {
      final ai = AIService();
      String relationship = _selectedRelationship ?? "alguém especial";
      String prompt = "Gere uma mensagem curta de feliz aniversário para $name ($relationship). ";
      
      if (['Mãe', 'Pai', 'Avó', 'Avô', 'Neto', 'Neta', 'Filho', 'Filha'].contains(relationship)) {
         prompt += "Tom: Muito carinhoso, amoroso, familiar.";
      } else if (['Namorado', 'Namorada', 'Esposa', 'Esposo'].contains(relationship)) {
         prompt += "Tom: Romântico, íntimo, emocional.";
      } else if (['Amigo', 'Amiga'].contains(relationship)) {
         prompt += "Tom: Próximo, leve, divertido (sem exageros).";
      } else if (['Chefe', 'Cliente', 'Fornecedor', 'Colega de trabalho'].contains(relationship)) {
         prompt += "Tom: Formal, respeitoso, educado, sem intimidade excessiva.";
      } else {
         prompt += "Tom: Neutro e gentil.";
      }

      final msg = await ai.answerQuestion(prompt);
      final cleanMsg = msg.replaceAll('"', '');
      setState(() {
        _birthdayMessageController.text = cleanMsg;
        _aiGenerated = true; // Mark as AI generated
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao gerar sugestão.")));
    } finally {
      if (mounted) setState(() => _isGeneratingMessage = false);
    }
  }

  IconData _getIconForType(AgendaItemType type) {
    switch (type) {
      case AgendaItemType.COMPROMISSO: return Icons.calendar_today;
      case AgendaItemType.TAREFA: return Icons.check_box;
      case AgendaItemType.PAGAMENTO: return Icons.attach_money;
      case AgendaItemType.REMEDIO: return Icons.medication;
      case AgendaItemType.ANIVERSARIO: return Icons.cake;
      default: return Icons.note;
    }
  }

  Future<void> _save() async {
    try {
      // Auto-fill title
      if (_selectedType == AgendaItemType.ANIVERSARIO) {
          _titleController.text = "Aniversário de ${_personNameController.text}";
      }

      if (!_formKey.currentState!.validate()) {
        showDialog(context: context, builder: (c) => AlertDialog(title: Text("Erro"), content: Text("Campos obrigatórios não preenchidos (verifique vermelho).")));
        return;
      }
      
      // Validação Parentesco
      if (_selectedType == AgendaItemType.ANIVERSARIO) {
         if (_selectedRelationship == null || _selectedRelationship!.isEmpty) {
             showDialog(context: context, builder: (c) => AlertDialog(title: Text("Atenção"), content: Text("Por favor, selecione o Grau de Parentesco.")));
             return;
         }
      }
      
      // Construct objects (Mantendo lógica original...)
      PagamentoInfo? pagInfo;
      RemedioInfo? medInfo;
      AniversarioInfo? bdayInfo;
      RecorrenciaInfo? recInfo;

      if (_selectedType == AgendaItemType.PAGAMENTO) {
         pagInfo = PagamentoInfo(
           valor: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0,
           status: _paymentStatusController.text,
           dataVencimento: _paymentDate ?? DateTime.now(),
           moeda: 'BRL',
         );
      } else if (_selectedType == AgendaItemType.REMEDIO) {
         medInfo = RemedioInfo(
           nome: _medNameController.text,
           dosagem: _dosageController.text,
           frequenciaTipo: 'HORAS',
           intervalo: _intervalHours.toInt(),
           inicioTratamento: DateTime.now(), 
           status: 'PENDENTE',
         );
      } else if (_selectedType == AgendaItemType.ANIVERSARIO) {
         bdayInfo = AniversarioInfo(
           nomePessoa: _personNameController.text,
           mensagemPadrao: _birthdayMessageController.text,
           telefone: _phoneNumberController.text,
           emailContato: _emailController.text,
           smsPhone: _smsController.text,
           parentesco: _selectedRelationship,
           notificarAntes: _notifyDaysBefore.toInt(),
           permitirEnvioCartao: true,
           mensagemGeradaPorIA: _aiGenerated,
           precisaConfirmarAntesDeEnviar: true,
         );
         recInfo = RecorrenciaInfo(frequencia: 'ANUAL');
      }

      final newItem = AgendaItem(
        tipo: _selectedType,
        titulo: _titleController.text,
        descricao: _descriptionController.text,
        dataInicio: _startDate ?? DateTime.now(), // Garante data
        horarioInicio: _startTime != null ? "${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2,'0')}" : null,
        status: ItemStatus.PENDENTE,
        pagamento: pagInfo,
        remedio: medInfo,
        aniversario: bdayInfo,
        recorrencia: recInfo,
        anexos: _attachments,
      );

      // Verificação crítica: Se temos um item, mas ele não está no banco (isInBox false),
      // significa que veio de um rascunho de voz mas foi passado como 'item'.
      // Nesse caso, devemos Adicionar, não Atualizar.
      if (widget.item != null && widget.item!.isInBox) {
        widget.item!.tipo = newItem.tipo;
        widget.item!.titulo = newItem.titulo;
        widget.item!.descricao = newItem.descricao;
        widget.item!.dataInicio = newItem.dataInicio;
        widget.item!.horarioInicio = newItem.horarioInicio;
        widget.item!.pagamento = newItem.pagamento;
        widget.item!.remedio = newItem.remedio;
        widget.item!.aniversario = newItem.aniversario;
        widget.item!.recorrencia = newItem.recorrencia;
        widget.item!.anexos = newItem.anexos;
        
        // Usar .save() direto do objeto Hive é mais seguro para updates
        await widget.item!.save(); 
      } else {
        await _repo.addItem(newItem);
      }

      if (mounted) Navigator.pop(context);

    } catch (e, stack) {
      showDialog(context: context, builder: (c) => AlertDialog(
        title: Text("Erro Técnico"), 
        content: SingleChildScrollView(child: Text("Erro ao salvar: $e\n\n$stack"))
      ));
    }
  }
}
