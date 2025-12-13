import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';

class AddEditEventDialog extends StatefulWidget {
  final Event? event;
  final String currentLanguage;

  const AddEditEventDialog({
    super.key,
    this.event,
    required this.currentLanguage,
  });

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _recurrence;
  int _reminderMinutes = 30; // Default 30 minutes

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _selectedDate = widget.event!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.date);
      _recurrence = widget.event!.recurrence;
      if (_recurrence == 'NONE') _recurrence = null;
      _reminderMinutes = widget.event!.reminderMinutes;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _recurrence = null;
      _reminderMinutes = 30;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String t(String key) => AppLocalizations.t(key, widget.currentLanguage);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final event = Event(
        id: widget.event?.id ?? const Uuid().v4(),
        title: _titleController.text,
        date: dateTime,
        description: _descriptionController.text,
        isCancelled: widget.event?.isCancelled ?? false,
        recurrence: _recurrence,
        lastNotifiedDate: widget.event?.lastNotifiedDate, // Preservar data de notificação
        reminderMinutes: _reminderMinutes,
      );

      if (widget.event != null) {
        // Update existing event - return event for parent to handle
        Navigator.pop(context, event);
      } else {
        // Add new event
        await _dbService.addEvent(event);
        

        
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? t('add_event') : t('edit_event')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: t('title')),
                validator: (value) => value == null || value.isEmpty ? t('required_field') : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat.yMd(widget.currentLanguage).format(_selectedDate)),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime.format(context)),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrence,
                decoration: InputDecoration(labelText: t('recurrence')),
                items: [
                  DropdownMenuItem(value: null, child: Text(t('recurrence_none'))),
                  DropdownMenuItem(value: 'DAILY', child: Text(t('recurrence_daily'))),
                  DropdownMenuItem(value: 'WEEKLY', child: Text(t('recurrence_weekly'))),
                  DropdownMenuItem(value: 'MONTHLY', child: Text(t('recurrence_monthly'))),
                  DropdownMenuItem(value: 'YEARLY', child: Text(t('recurrence_yearly'))),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurrence = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(labelText: 'Avisar com antecedência'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Na hora do evento')),
                  DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutos antes (Padrão)')),
                  DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                  DropdownMenuItem(value: 120, child: Text('2 horas antes')),
                  DropdownMenuItem(value: 1440, child: Text('1 dia antes')),
                ],
                onChanged: (value) {
                  setState(() {
                    _reminderMinutes = value ?? 30;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: t('description')),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('cancel')),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(t('save')),
        ),
      ],
    );
  }
}
