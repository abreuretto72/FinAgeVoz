import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../widgets/add_edit_event_dialog.dart';
import '../utils/localization.dart'; // Assuming this exists or I use hardcoded for now, but better use it
import 'dart:collection';

class NewAgendaScreen extends StatefulWidget {
  const NewAgendaScreen({super.key});

  @override
  State<NewAgendaScreen> createState() => _NewAgendaScreenState();
}

class _NewAgendaScreenState extends State<NewAgendaScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Data
  List<Event> _allEvents = [];
  
  // Cache for events to avoid recalculating recurrence constantly (optional, but good for performance)
  // For simplicity, we will calculate on the fly first.

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _dbService.init();
    final events = _dbService.getEvents(); // Assumption: returns List<Event>
    setState(() {
      _allEvents = events;
    });
  }

  // Core Logic: Get events for a specific day
  List<Event> _getEventsForDay(DateTime day) {
    List<Event> eventsForDay = [];
    
    for (var event in _allEvents) {
      if (event.isCancelled) continue; // Skip cancelled? Or show them crossed out? User said "disregard errors", maybe keep it simple.

      // 1. Check Exact Date (Normal Event)
      if (_isSameDay(event.date, day)) {
        eventsForDay.add(event);
        continue;
      }

      // 2. Check Recurrence
      if (event.recurrence != null && event.recurrence != 'NONE') {
        if (_occursOnDate(event, day)) {
            eventsForDay.add(event);
        }
      }
    }
    
    // Sort by time
    eventsForDay.sort((a, b) => a.date.hour.compareTo(b.date.hour) != 0 
        ? a.date.hour.compareTo(b.date.hour) 
        : a.date.minute.compareTo(b.date.minute));
        
    return eventsForDay;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _occursOnDate(Event event, DateTime target) {
    // If target is before event start, it cannot occur (assuming forward recurrence only)
    if (target.isBefore(DateTime(event.date.year, event.date.month, event.date.day))) return false;

    switch (event.recurrence) {
      case 'DAILY':
        return true; // Happens every day after start
      case 'WEEKLY':
        return event.date.weekday == target.weekday;
      case 'MONTHLY':
        return event.date.day == target.day;
      case 'YEARLY':
        return event.date.month == target.month && event.date.day == target.day;
      default:
        return false;
    }
  }

  Future<void> _addEvent() async {
    // Default date to selected day if valid, else Now
    final date = _selectedDay ?? DateTime.now();
    
    // We can pass the date to the dialog if it supports it, 
    // or we can just let user pick.
    // Assuming AddEditEventDialog can take an initial date or we modify it later.
    // For now, standard dialog.
    
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditEventDialog(
         currentLanguage: Localizations.localeOf(context).languageCode == 'pt' ? 'pt_BR' : 'en_US',
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Localization
    // We can get locale code from logic similar to other screens
    final locale = Localizations.localeOf(context).languageCode == 'pt' ? 'pt_BR' : 'en_US'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Inteligente'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTableCalendar(locale),
          const SizedBox(height: 8.0),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTableCalendar(String locale) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar<Event>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        locale: locale,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.redAccent),
          holidayTextStyle: const TextStyle(color: Colors.redAccent),
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF00E5FF), // Cyan Neon
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
        ),
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? DateTime.now());
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text("Nenhum evento neste dia", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(event.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (event.recurrence != null && event.recurrence != 'NONE')
                   const Icon(Icons.repeat, size: 14, color: Colors.cyan),
              ],
            ),
            title: Text(
                event.title, 
                style: TextStyle(
                    decoration: event.isCancelled ? TextDecoration.lineThrough : null,
                    color: event.isCancelled ? Colors.grey : null,
                ),
            ),
            subtitle: event.description.isNotEmpty ? Text(
                event.description, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
            ) : null,
            trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editEvent(event),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editEvent(Event event) async {
     // Edit logic similar to old agenda
     // We find the original event in DB if it's a recurring instance?
     // For this simple implementation, we pass the event object. 
     // BUT `AddEditEventDialog` expects `event` object.
     
     // Note: If we are editing a "Generated" recurring instance (which we are essentially doing visually), 
     // we are actually editing the MASTER event.
     // So passing 'event' (which is the Master from _allEvents) is correct.
     
     final result = await showDialog(
      context: context,
      builder: (context) => AddEditEventDialog(
        event: event,
        currentLanguage: Localizations.localeOf(context).languageCode == 'pt' ? 'pt_BR' : 'en_US',
      ),
    );

    if (result != null) {
       // Save to DB
       // Find index
       final index = _allEvents.indexWhere((e) => e.id == event.id);
       if (index != -1) {
           await _dbService.updateEvent(index, result); // This updates the Hive box
           _loadEvents();
       }
    }
  }
}
