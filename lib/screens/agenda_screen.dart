import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';
import '../models/operation_history.dart';
import '../services/pdf_service.dart';
import '../utils/localization.dart';
import '../widgets/add_edit_event_dialog.dart';
import '../widgets/attachments_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_preview_screen.dart';

enum FilterPeriod { today, thisWeek, thisMonth, all }

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  
  FilterPeriod _selectedPeriod = FilterPeriod.thisMonth;
  DateTime? _selectedDate;
  String _searchQuery = '';
  bool _isAscending = true;
  bool _isSearching = false;
  bool _showOnlyWithAttachments = false;
  
  String get _currentLanguage => Localizations.localeOf(context).toString();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _loadData() async {
    await _dbService.init();
    final events = _dbService.getEvents();
    final language = _dbService.getLanguage();
    
    setState(() {
      // _currentLanguage = language; // No longer needed
      _events = events;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd;

    // 1. Determine the period range
    if (_selectedDate != null) {
      periodStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      periodEnd = periodStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    } else {
      switch (_selectedPeriod) {
        case FilterPeriod.today:
          periodStart = DateTime(now.year, now.month, now.day);
          periodEnd = periodStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
          break;
        case FilterPeriod.thisWeek:
          periodStart = now.subtract(Duration(days: now.weekday - 1));
          periodStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
          periodEnd = periodStart.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
          break;
        case FilterPeriod.thisMonth:
          periodStart = DateTime(now.year, now.month, 1);
          periodEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
          break;
        case FilterPeriod.all:
          // For "All", we start from the earliest event or now, and go up to 2 years in future for recurring
          periodStart = DateTime(2020); 
          periodEnd = DateTime(now.year + 2, 12, 31);
          break;
      }
    }

    _filteredEvents = [];

    // 2. Process events and generate instances
    for (var event in _events) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        bool matchesSearch = event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) continue;
      }

      // Attachments filter
      if (_showOnlyWithAttachments) {
        bool matchesAttachments = event.attachments != null && event.attachments!.isNotEmpty;
        if (!matchesAttachments) continue;
      }

      if (event.recurrence == null || event.recurrence == 'NONE') {
        // Normal event
        if (event.date.isAfter(periodStart.subtract(const Duration(milliseconds: 1))) && 
            event.date.isBefore(periodEnd.add(const Duration(milliseconds: 1)))) {
          _filteredEvents.add(event);
        }
      } else {
        // Recurring event - generate instances
        _filteredEvents.addAll(_generateRecurringInstances(event, periodStart, periodEnd));
      }
    }

    _sortEvents();
  }

  List<Event> _generateRecurringInstances(Event original, DateTime start, DateTime end) {
    List<Event> instances = [];
    DateTime current = original.date;

    // If original date is after the end of period, no instances (unless we want to support back-dated recurrence start, but for now let's assume start date matters)
    if (current.isAfter(end)) return [];

    // Advance current to start of period if needed (optimization)
    // For simple intervals we could calculate, but iteration is safer for months/years
    
    while (current.isBefore(end.add(const Duration(days: 1)))) {
      // Check if current instance falls within the window
      if (current.isAfter(start.subtract(const Duration(milliseconds: 1))) && 
          current.isBefore(end.add(const Duration(milliseconds: 1)))) {
        
        // Create a virtual copy
        instances.add(Event(
          id: "${original.id}_${current.millisecondsSinceEpoch}", // Virtual ID
          title: original.title,
          date: current,
          description: original.description,
          isCancelled: original.isCancelled,
          recurrence: original.recurrence,
          lastNotifiedDate: original.lastNotifiedDate,
        ));
      }

      // Move to next instance
      switch (original.recurrence) {
        case 'DAILY':
          current = current.add(const Duration(days: 1));
          break;
        case 'WEEKLY':
          current = current.add(const Duration(days: 7));
          break;
        case 'MONTHLY':
          // Add 1 month, handling variable days (e.g. Jan 31 -> Feb 28)
          var nextMonth = current.month + 1;
          var nextYear = current.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          // Try to keep the same day, but clamp to max days in month
          var maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
          var nextDay = current.day > maxDays ? maxDays : current.day;
          
          current = DateTime(nextYear, nextMonth, nextDay, current.hour, current.minute);
          break;
        case 'YEARLY':
          current = DateTime(current.year + 1, current.month, current.day, current.hour, current.minute);
          break;
        default:
          return instances; // Should not happen
      }
    }

    return instances;
  }

  void _sortEvents() {
    if (_isAscending) {
      _filteredEvents.sort((a, b) => a.date.compareTo(b.date));
    } else {
      _filteredEvents.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriod = FilterPeriod.all;
        _applyFilters();
      });
    }
  }

  Future<void> _addEvent() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditEventDialog(
        currentLanguage: _currentLanguage,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editEvent(Event event, int index) async {
    // Create snapshot of current state before editing
    final snapshot = {
      'id': event.id,
      'title': event.title,
      'date': event.date.toIso8601String(),
      'description': event.description,
      'isCancelled': event.isCancelled,
      'recurrence': event.recurrence,
    };
    
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditEventDialog(
        event: event,
        currentLanguage: _currentLanguage,
      ),
    );

    if (result is Event) {
      await _dbService.updateEvent(index, result);
      
      // Record edit in history for undo
      final operation = OperationHistory(
        id: const Uuid().v4(),
        type: 'event_edit',
        transactionIds: [],
        description: result.title,
        timestamp: DateTime.now(),
        eventId: result.id,
        eventSnapshot: snapshot,
      );
      await _dbService.addOperationToHistory(operation);
      
      _loadData();
    }
  }

  bool _isSelectionMode = false;
  final Set<String> _selectedEventIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedEventIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedEventIds.contains(id)) {
        _selectedEventIds.remove(id);
        if (_selectedEventIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEventIds.add(id);
      }
    });
  }

  Future<void> _shareOnWhatsApp() async {
    if (_selectedEventIds.isEmpty) return;

    final selectedEvents = _filteredEvents
        .where((e) => _selectedEventIds.contains(e.id))
        .toList();

    if (selectedEvents.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("*Minha Agenda - FinAgeVoz*");
    buffer.writeln("");

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var e in selectedEvents) {
      buffer.writeln("📅 ${dateFormat.format(e.date)}");
      buffer.writeln("📌 ${e.title}");
      if (e.description.isNotEmpty) {
        buffer.writeln("📝 ${e.description}");
      }
      if (e.isCancelled) {
        buffer.writeln("❌ Cancelado");
      }
      buffer.writeln("");
    }

    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse("https://wa.me/?text=$text");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('whatsapp_error'))),
        );
      }
    }
    
    // Exit selection mode after sharing
    setState(() {
      _isSelectionMode = false;
      _selectedEventIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    String locale = _currentLanguage;
    if (locale == 'pt_BR') locale = 'pt_BR';
    else if (locale == 'pt_PT') locale = 'pt_PT';
    else if (locale == 'en') locale = 'en_US';
    else if (locale == 'es') locale = 'es_ES';
    else if (locale == 'de') locale = 'de_DE';
    else if (locale == 'hi') locale = 'hi_IN';
    else if (locale == 'zh') locale = 'zh_CN';
    else if (locale == 'it') locale = 'it_IT';
    else if (locale == 'fr') locale = 'fr_FR';
    else if (locale == 'ja') locale = 'ja_JP';
    else if (locale == 'ar') locale = 'ar_SA';
    else if (locale == 'bn') locale = 'bn_IN';
    else if (locale == 'ru') locale = 'ru_RU';
    else if (locale == 'id') locale = 'id_ID';

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', locale);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : (_isSearching 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                      _applyFilters();
                    });
                  },
                )
              : null),
        title: _isSelectionMode 
          ? Text('${_selectedEventIds.length} selecionados')
          : (_isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: t('search_hint_events'),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                )
              : Text(t('nav_agenda'))),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: 'Enviar para WhatsApp',
              onPressed: _shareOnWhatsApp,
            )
          else ...[
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: t('search_hint_events'),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: t('clear_filters'),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedDate = null;
                  _selectedPeriod = FilterPeriod.all;
                  _showOnlyWithAttachments = false;
                  _isSearching = false;
                  _applyFilters();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('filters_cleared')), duration: const Duration(seconds: 1)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: t('share_report'),
              onPressed: () async {
                try {
                  await PdfService.shareEventsPdf(
                    _filteredEvents,
                    dateFormat,
                    _currentLanguage,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${t('error')}: $e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreen(
                        title: t('events_report_title'),
                        buildPdf: (format) => PdfService.generateEventsPdfBytes(
                          _filteredEvents,
                          dateFormat,
                          _currentLanguage,
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${t('error')}: $e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _applyFilters();
                });
              },
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Unified Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 1. Month (Period)
                ChoiceChip(
                  label: Text(t('period_month')),
                  selected: _selectedPeriod == FilterPeriod.thisMonth && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.thisMonth;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 2. Today (Period)
                ChoiceChip(
                  label: Text(t('period_today')),
                  selected: _selectedPeriod == FilterPeriod.today && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.today;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 3. Week (Period)
                ChoiceChip(
                  label: Text(t('period_week')),
                  selected: _selectedPeriod == FilterPeriod.thisWeek && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.thisWeek;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 4. Date Picker
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate == null 
                      ? t('select_date') 
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                  onPressed: _pickDate,
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                
                // 5. Attachments Filter
                FilterChip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(t('filter_attachments')),
                  selected: _showOnlyWithAttachments,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyWithAttachments = selected;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(child: Text(t('no_events')))
                : ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      // Find original index for editing/deleting
                      // Note: For recurring instances (virtual), we can't edit them directly yet without logic to split/edit series
                      // For now, we only allow editing the original event if it's not a virtual instance.
                      // Virtual instances have IDs like "originalId_timestamp".
                      final isVirtual = event.id.contains('_') && event.recurrence != null && event.recurrence != 'NONE';
                      final originalId = isVirtual ? event.id.split('_')[0] : event.id;
                      final eventIndex = _events.indexWhere((e) => e.id == originalId);
                      final isSelected = _selectedEventIds.contains(event.id);

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleSelection(event.id),
                            )
                          : CircleAvatar(
                              child: (event.attachments != null && event.attachments!.isNotEmpty)
                                  ? Text(
                                      String.fromCharCode(Icons.attach_file.codePoint),
                                      style: TextStyle(
                                        fontFamily: Icons.attach_file.fontFamily,
                                        package: Icons.attach_file.fontPackage,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    )
                                  : const Icon(Icons.event),
                            ),
                        title: Text(event.title),
                        subtitle: Text(dateFormat.format(event.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (event.recurrence != null && event.recurrence != 'NONE')
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.repeat, size: 16, color: Colors.blue),
                              ),
                            if (event.isCancelled)
                              Text(t('cancelled_status'), style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleSelection(event.id);
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(event.id);
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(event.title),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t('date')}: ${dateFormat.format(event.date)}'),
                                  const SizedBox(height: 8),
                                  Text('${t('description')}:'),
                                  Text(event.description),
                                  if (event.recurrence != null && event.recurrence != 'NONE')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.repeat, size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text('${t('recurrence')}: ${t('recurrence_${event.recurrence!.toLowerCase()}')}'),
                                        ],
                                      ),
                                    ),
                                  if (event.isCancelled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('${t('status')}: ${t('cancelled')}', style: const TextStyle(color: Colors.red)),
                                    ),
                                  if (isVirtual)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        "Esta é uma ocorrência de um evento recorrente. Edite o evento original para alterar a série.",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                              actions: [
                                if (eventIndex >= 0) ...[
                                  if (!_events[eventIndex].isCancelled)
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: Text(t('edit')),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _editEvent(_events[eventIndex], eventIndex);
                                      },
                                    ),
                                  if (!_events[eventIndex].isCancelled && !isVirtual)
                                    TextButton.icon(
                                      icon: const Icon(Icons.event_available),
                                      label: Text(t('transfer')),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final newDate = await showDatePicker(
                                          context: context,
                                          initialDate: event.date,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (newDate != null) {
                                          final newTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(event.date),
                                          );
                                          if (newTime != null) {
                                            final originalEvent = _events[eventIndex];
                                            final updatedEvent = Event(
                                              id: originalEvent.id,
                                              title: originalEvent.title,
                                              date: DateTime(
                                                newDate.year,
                                                newDate.month,
                                                newDate.day,
                                                newTime.hour,
                                                newTime.minute,
                                              ),
                                              description: originalEvent.description,
                                              isCancelled: originalEvent.isCancelled,
                                              recurrence: originalEvent.recurrence,
                                              lastNotifiedDate: originalEvent.lastNotifiedDate,
                                              attachments: originalEvent.attachments,
                                            );
                                            await _dbService.updateEvent(eventIndex, updatedEvent);
                                            _loadData();
                                          }
                                        }
                                      },
                                    ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.attach_file),
                                    label: Text(t('attachments_label')),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final originalEvent = _events[eventIndex];
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AttachmentsDialog(
                                          initialAttachments: originalEvent.attachments ?? [],
                                          onSave: (updatedAttachments) async {
                                            final updatedEvent = Event(
                                              id: originalEvent.id,
                                              title: originalEvent.title,
                                              date: originalEvent.date,
                                              description: originalEvent.description,
                                              isCancelled: originalEvent.isCancelled,
                                              recurrence: originalEvent.recurrence,
                                              lastNotifiedDate: originalEvent.lastNotifiedDate,
                                              attachments: updatedAttachments,
                                            );
                                            await _dbService.updateEvent(eventIndex, updatedEvent);
                                            _loadData();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: Icon(_events[eventIndex].isCancelled ? Icons.check_circle : Icons.cancel),
                                    label: Text(_events[eventIndex].isCancelled ? t('reactivate') : t('cancel_event')),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final originalEvent = _events[eventIndex];
                                      final updatedEvent = Event(
                                        id: originalEvent.id,
                                        title: originalEvent.title,
                                        date: originalEvent.date,
                                        description: originalEvent.description,
                                        isCancelled: !originalEvent.isCancelled,
                                        recurrence: originalEvent.recurrence,
                                        lastNotifiedDate: originalEvent.lastNotifiedDate,
                                        attachments: originalEvent.attachments,
                                      );
                                      await _dbService.updateEvent(eventIndex, updatedEvent);
                                      _loadData();
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final isRecurring = _events[eventIndex].recurrence != null && _events[eventIndex].recurrence != 'NONE';
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(t('delete_event')),
                                          content: Text(isRecurring 
                                            ? 'Deseja excluir todas as ocorrências deste evento?' 
                                            : t('confirm_delete')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text(t('cancel')),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text(t('delete')),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _dbService.deleteEvent(eventIndex);
                                        _loadData();
                                      }
                                    },
                                    child: Text(t('delete'), style: const TextStyle(color: Colors.red)),
                                  ),
                                ],
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(t('close')),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
