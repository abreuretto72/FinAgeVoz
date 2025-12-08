import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/agenda_models.dart';

Future<void> initAgendaHive() async {
  // Hive.initFlutter(); // Already handled in main.dart

  // Registrando adapters
  if (!Hive.isAdapterRegistered(100)) Hive.registerAdapter(AgendaItemTypeAdapter());
  if (!Hive.isAdapterRegistered(101)) Hive.registerAdapter(ItemStatusAdapter());
  if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(RecorrenciaInfoAdapter());
  if (!Hive.isAdapterRegistered(103)) Hive.registerAdapter(PagamentoInfoAdapter());
  if (!Hive.isAdapterRegistered(104)) Hive.registerAdapter(RemedioInfoAdapter());
  if (!Hive.isAdapterRegistered(105)) Hive.registerAdapter(AniversarioInfoAdapter());
  if (!Hive.isAdapterRegistered(106)) Hive.registerAdapter(AnexoAdapter());
  if (!Hive.isAdapterRegistered(107)) Hive.registerAdapter(AgendaItemAdapter());

  // Abrindo a box principal
  if (!Hive.isBoxOpen('agenda_items')) {
    await Hive.openBox<AgendaItem>('agenda_items');
  }
}

Future<void> ensureAgendaBoxOpen() async {
  if (!Hive.isBoxOpen('agenda_items')) {
    await Hive.openBox<AgendaItem>('agenda_items');
  }
}

Box<AgendaItem> get agendaBox => Hive.box<AgendaItem>('agenda_items');
