import 'package:hive/hive.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 108)
class Remedio extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  String? nomeGenerico;

  @HiveField(3)
  String formaFarmaceutica; // comprimido, cápsula, gotas, xarope...

  @HiveField(4)
  String concentracao; // ex: "500 mg", "25 mg/mL"

  @HiveField(5)
  String viaAdministracao; // oral, tópico, nasal, injetável...

  @HiveField(6)
  String? indicacao; // para que serve

  @HiveField(7)
  String? observacoesMedico; // campo livre

  @HiveField(8)
  DateTime criadoEm;

  @HiveField(9)
  DateTime atualizadoEm;

  @HiveField(10)
  List<String> posologiaIds; // Relacionamento

  @HiveField(11)
  List<String>? attachments;

  Remedio({
    required this.id,
    required this.nome,
    this.nomeGenerico,
    this.formaFarmaceutica = 'Comprimido',
    this.concentracao = '',
    this.viaAdministracao = 'Oral',
    this.indicacao,
    this.observacoesMedico,
    required this.criadoEm,
    required this.atualizadoEm,
    this.posologiaIds = const [],
    this.attachments,
  });
}

@HiveType(typeId: 109)
class Posologia extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String remedioId;

  @HiveField(2)
  double quantidadePorDose;

  @HiveField(3)
  String unidadeDose; // comprimido, mL, gotas...

  @HiveField(4)
  String frequenciaTipo; 
  // "INTERVALO" (8 em 8h) 
  // "HORARIOS_FIXOS" (08:00, 20:00) 
  // "VEZES_DIA" (3x ao dia) 
  // "SE_NECESSARIO" (SOS)

  @HiveField(5)
  int? intervaloHoras;

  @HiveField(6)
  List<String>? horariosDoDia; // ["08:00", "20:00"]

  @HiveField(7)
  int? vezesAoDia;

  @HiveField(8)
  List<int>? diasDaSemana; // 0=Domingo...6=Sábado ou 1..7 (User implementation defined, let's use 1=Mon..7=Sun standard or 0..6? Helper usually uses 1..7, but let's stick to DateTime.weekday which is 1..7)

  @HiveField(9)
  DateTime inicioTratamento;

  @HiveField(10)
  DateTime? fimTratamento;

  @HiveField(11)
  bool usoContinuo;

  @HiveField(12)
  bool usarSeNecessario;

  @HiveField(13)
  int? maxDosesPorDia;

  @HiveField(14)
  bool? tomarComAlimento;

  @HiveField(15)
  String? instrucoesExtras;

  @HiveField(16)
  bool exigirConfirmacao;

  @HiveField(17)
  DateTime criadoEm;

  @HiveField(18)
  DateTime atualizadoEm;

  Posologia({
    required this.id,
    required this.remedioId,
    required this.quantidadePorDose,
    required this.unidadeDose,
    required this.frequenciaTipo,
    this.intervaloHoras,
    this.horariosDoDia,
    this.vezesAoDia,
    this.diasDaSemana,
    required this.inicioTratamento,
    this.fimTratamento,
    this.usoContinuo = false,
    this.usarSeNecessario = false,
    this.maxDosesPorDia,
    this.tomarComAlimento,
    this.instrucoesExtras,
    this.exigirConfirmacao = true,
    required this.criadoEm,
    required this.atualizadoEm,
  });
}

@HiveType(typeId: 110)
class HistoricoTomada extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String posologiaId;

  @HiveField(2)
  DateTime dataHoraProgramada; // Quando deveria ter tomado

  @HiveField(3)
  DateTime? dataHoraReal; // Quando realmente tomou (null = não tomou/pulou?)

  @HiveField(4)
  bool taken; // Tomou ou pulou?

  @HiveField(5)
  String? observacao;

  HistoricoTomada({
    required this.id,
    required this.posologiaId,
    required this.dataHoraProgramada,
    this.dataHoraReal,
    required this.taken,
    this.observacao,
  });
}
