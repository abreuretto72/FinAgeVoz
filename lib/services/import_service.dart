import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:device_calendar/device_calendar.dart' hide Event;
import 'package:device_calendar/device_calendar.dart' as device_calendar show Event;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';

class ImportService {
  final DatabaseService _dbService = DatabaseService();

  ImportService() {
    tz.initializeTimeZones();
  }

  Future<int> importTransactions() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();

        if (fields.isEmpty) return 0;

        // Remove header if present (assuming first row is header)
        // We check if the first column of the first row looks like a date. If not, it's a header.
        int startIndex = 0;
        if (fields.isNotEmpty) {
           final firstCell = fields[0][0].toString();
           if (DateTime.tryParse(firstCell) == null && _parseDate(firstCell) == null) {
             startIndex = 1;
           }
        }

        int importedCount = 0;

        for (int i = startIndex; i < fields.length; i++) {
          final row = fields[i];
          if (row.length < 5) continue; // Skip invalid rows

          // Expected columns: Date, Category, Subcategory, Description, Value
          final dateStr = row[0].toString();
          final category = row[1].toString();
          final subcategory = row[2].toString();
          final description = row[3].toString();
          final valueStr = row[4].toString();

          final date = _parseDate(dateStr);
          final amount = _parseAmount(valueStr);

          if (date != null && amount != null) {
            final transaction = Transaction(
              id: const Uuid().v4(),
              description: description,
              amount: amount.abs(), // Store absolute value
              isExpense: amount < 0, // Negative value implies expense
              date: date,
              category: category,
              subcategory: subcategory.isNotEmpty ? subcategory : null,
            );

            await _dbService.addTransaction(transaction);
            importedCount++;
          }
        }
        return importedCount;
      }
      return 0;
    } catch (e) {
      print("Import Error: $e");
      throw Exception("Erro ao importar arquivo: $e");
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Try ISO format first
      return DateTime.tryParse(dateStr);
    } catch (_) {}

    try {
      // Try PT-BR format
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (_) {}
    
    try {
       // Try PT-BR format with time
      return DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
    } catch (_) {}

    return null;
  }

  double? _parseAmount(String valueStr) {
    try {
      // Remove currency symbols and fix decimal separator
      String cleanValue = valueStr
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '') // Remove thousands separator
          .replaceAll(',', '.'); // Replace decimal separator
      
      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  Future<int> importEvents() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final icsString = await file.readAsString();
        final iCalendar = ICalendar.fromString(icsString);
        
        int importedCount = 0;

        if (iCalendar.data.isNotEmpty) {
          for (var item in iCalendar.data) {
            if (item['type'] == 'VEVENT') {
              final dtStart = item['dtstart'];
              final summary = item['summary'];
              final description = item['description'];

              if (dtStart != null && summary != null) {
                DateTime? date;
                if (dtStart is IcsDateTime) {
                  date = dtStart.toDateTime();
                } else if (dtStart is String) {
                   date = DateTime.tryParse(dtStart);
                }

                if (date != null) {
                  final event = Event(
                    id: const Uuid().v4(),
                    title: summary.toString(),
                    date: date,
                    description: description?.toString() ?? '',
                  );
                  await _dbService.addEvent(event);
                  importedCount++;
                }
              }
            }
          }
        }
        return importedCount;
      }
      return 0;
    } catch (e) {
      print("Import Error: $e");
      throw Exception("Erro ao importar agenda: $e");
    }
  }

  // Device Calendar Integration
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Future<List<Calendar>> retrieveDeviceCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return [];
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      return calendarsResult.data ?? [];
    } catch (e) {
      print("Error retrieving calendars: $e");
      return [];
    }
  }

  Future<int> importFromDeviceCalendar(String calendarId) async {
    try {
      // Import events from last year to next year
      final startDate = DateTime.now().subtract(const Duration(days: 365));
      final endDate = DateTime.now().add(const Duration(days: 365));
      
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        int count = 0;
        for (var deviceEvent in eventsResult.data!) {
          if (deviceEvent.start != null && deviceEvent.title != null) {
             // Note: device_calendar uses TZDateTime which is a DateTime
             final event = Event(
                id: const Uuid().v4(),
                title: deviceEvent.title!,
                date: deviceEvent.start!, 
                description: deviceEvent.description ?? '',
             );
             await _dbService.addEvent(event);
             count++;
          }
        }
        return count;
      }
      return 0;
    } catch (e) {
      throw Exception("Erro ao importar do calendário: $e");
    }
  }

  Future<void> exportTransactionsToCsv() async {
    try {
      final transactions = _dbService.getTransactions();
      if (transactions.isEmpty) {
        throw Exception("Não há transações para exportar.");
      }

      // Create CSV data
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        "Data",
        "Categoria",
        "Subcategoria",
        "Descrição",
        "Valor",
        "Tipo"
      ]);

      // Rows
      for (var t in transactions) {
        rows.add([
          DateFormat('dd/MM/yyyy HH:mm').format(t.date),
          t.category,
          t.subcategory ?? '',
          t.description,
          t.amount,
          t.isExpense ? 'Despesa' : 'Receita'
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/transacoes_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
      final file = File(path);
      
      // Write with UTF-8 BOM for Excel compatibility
      await file.writeAsBytes([0xEF, 0xBB, 0xBF] + utf8.encode(csv));

      // Share file
      await Share.shareXFiles([XFile(path)], text: 'Minhas Transações FinAgeVoz');
      
    } catch (e) {
      print("Export Error: $e");
      throw Exception("Erro ao exportar: $e");
    }
  }
  Future<int> exportEventsToDeviceCalendar(String calendarId) async {
    try {
      final events = _dbService.getEvents();
      if (events.isEmpty) return 0;

      int count = 0;
      // Use timezone from device or default
      final location = timeZoneDatabase.locations['America/Sao_Paulo']; 

      for (var event in events) {
        // Skip past events if desired, but user asked for "records" so we export all or maybe just future?
        // Let's export all for now, but usually one wants future.
        // Actually, to avoid duplicates we should check if it exists, but we don't store external IDs.
        // We will just create them.
        
        final tzDate = TZDateTime.from(event.date, location ?? local);

        final deviceEvent = device_calendar.Event(
          calendarId,
          title: event.title,
          start: tzDate,
          end: tzDate.add(const Duration(hours: 1)), // Default 1 hour duration
          description: event.description,
        );

        final result = await _deviceCalendarPlugin.createOrUpdateEvent(deviceEvent);
        if (result?.isSuccess == true) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print("Export Calendar Error: $e");
      throw Exception("Erro ao exportar para agenda: $e");
    }
  }

  Future<void> exportCategoriesToCsv() async {
    try {
      final categories = _dbService.getCategories();
      if (categories.isEmpty) {
        throw Exception("Não há categorias para exportar.");
      }

      // Create CSV data
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        "Tipo",
        "Categoria",
        "Descrição",
        "Subcategorias"
      ]);

      // Rows
      for (var c in categories) {
        rows.add([
          c.type == 'expense' ? 'Despesa' : 'Receita',
          c.name,
          c.description,
          c.subcategories.join('; ') // Join subcategories with semicolon
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/categorias_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
      final file = File(path);
      
      // Write with UTF-8 BOM for Excel compatibility
      await file.writeAsBytes([0xEF, 0xBB, 0xBF] + utf8.encode(csv));

      // Share file
      await Share.shareXFiles([XFile(path)], text: 'Minhas Categorias FinAgeVoz');
      
    } catch (e) {
      print("Export Categories Error: $e");
      throw Exception("Erro ao exportar categorias: $e");
    }
  }
}
