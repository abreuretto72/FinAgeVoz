import 'package:hive/hive.dart';
import '../models/agenda_models.dart';
import '../utils/hive_setup.dart';

class AgendaRepository {
  Box<AgendaItem> get _box => agendaBox;

  List<AgendaItem> getAllItems() => getAll();


  Future<AgendaItem> addItem(AgendaItem item) async {
    final key = await _box.add(item);
    final saved = _box.get(key)!;
    return saved;
  }

  Future<void> updateItem(AgendaItem item) async {
    item.atualizadoEm = DateTime.now();
    await item.save();
  }

  Future<void> deleteItem(AgendaItem item) async {
    await item.delete();
  }

  List<AgendaItem> getAll() {
    return _box.values.toList()
      ..sort((a, b) {
        final da = a.dataInicio ?? a.criadoEm;
        final db = b.dataInicio ?? b.criadoEm;
        return da.compareTo(db);
      });
  }

  List<AgendaItem> getByTipo(AgendaItemType tipo) {
    return _box.values.where((e) => e.tipo == tipo).toList();
  }

  List<AgendaItem> search({
    String? texto,
    AgendaItemType? tipo,
    DateTime? data,
  }) {
    return _box.values.where((item) {
      bool ok = true;

      if (texto != null && texto.trim().isNotEmpty) {
        final t = texto.toLowerCase();
        ok = ok &&
            ((item.titulo.toLowerCase().contains(t)) ||
                ((item.descricao ?? '').toLowerCase().contains(t)));
      }

      if (tipo != null) {
        ok = ok && item.tipo == tipo;
      }

      if (data != null) {
        final di = item.dataInicio;
        if (di == null) return false;
        ok = ok &&
            di.year == data.year &&
            di.month == data.month &&
            di.day == data.day;
      }

      return ok;
    }).toList();
  }
}
