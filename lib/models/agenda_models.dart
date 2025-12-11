import 'package:hive/hive.dart';

part 'agenda_models.g.dart';

@HiveType(typeId: 100)
enum AgendaItemType {
  @HiveField(0) COMPROMISSO,
  @HiveField(1) TAREFA,
  @HiveField(2) LEMBRETE,
  @HiveField(3) META,
  @HiveField(4) PROJETO,
  @HiveField(5) NOTA,
  @HiveField(6) EVENTO_RECORRENTE,
  @HiveField(7) PRAZO,
  @HiveField(8) ROTINA,
  @HiveField(9) PAGAMENTO,
  @HiveField(10) REMEDIO,
  @HiveField(11) ANIVERSARIO,
}

@HiveType(typeId: 101)
enum ItemStatus {
  @HiveField(0) PENDENTE,
  @HiveField(1) EM_ANDAMENTO,
  @HiveField(2) CONCLUIDO,
  @HiveField(3) CANCELADO,
}

@HiveType(typeId: 102)
class RecorrenciaInfo {
  @HiveField(0)
  String frequencia; // "DIARIO", "SEMANAL", "MENSAL", "ANUAL", "HORAS", "CUSTOM"

  @HiveField(1)
  int? intervalo;

  @HiveField(2)
  List<int>? diasDaSemana; // 0..6

  RecorrenciaInfo({
    required this.frequencia,
    this.intervalo,
    this.diasDaSemana,
  });
}

@HiveType(typeId: 103)
class PagamentoInfo {
  @HiveField(0)
  double valor;

  @HiveField(1)
  String moeda;

  @HiveField(2)
  String status; // "PENDENTE", "PAGO", "ATRASADO", "CANCELADO"

  @HiveField(3)
  DateTime dataVencimento;

  @HiveField(4)
  DateTime? dataPagamento;

  @HiveField(5)
  bool recorrente;

  @HiveField(6)
  String? forma; // "pix", "boleto", "cartao", etc.

  @HiveField(7)
  String? descricaoFinanceira;

  @HiveField(8)
  String? transactionId;

  PagamentoInfo({
    required this.valor,
    this.moeda = "BRL",
    required this.status,
    required this.dataVencimento,
    this.dataPagamento,
    this.recorrente = false,
    this.forma,
    this.descricaoFinanceira,
    this.transactionId,
  });
}

@HiveType(typeId: 104)
class RemedioInfo {
  @HiveField(0)
  String nome;

  @HiveField(1)
  String dosagem;

  @HiveField(2)
  int? quantidade;

  @HiveField(3)
  String? horario; // "08:00"

  @HiveField(4)
  String frequenciaTipo; // "HORAS", "DIAS", "SEMANAL"

  @HiveField(5)
  int intervalo; // ex: 8 (a cada 8 horas)

  @HiveField(6)
  List<int>? diasDaSemana; // se usar semanal

  @HiveField(7)
  DateTime inicioTratamento;

  @HiveField(8)
  DateTime? fimTratamento;

  @HiveField(9)
  bool exigirConfirmacao;

  @HiveField(10)
  String status; // "PENDENTE", "TOMADO", "ATRASADO"

  @HiveField(11)
  DateTime? proximaDose;

  @HiveField(12)
  DateTime? ultimaDoseTomada;

  @HiveField(13)
  String? id;

  @HiveField(14)
  String? posologiaId;

  RemedioInfo({
    required this.nome,
    required this.dosagem,
    this.quantidade,
    this.horario,
    required this.frequenciaTipo,
    required this.intervalo,
    this.diasDaSemana,
    required this.inicioTratamento,
    this.fimTratamento,
    this.exigirConfirmacao = true,
    this.status = "PENDENTE",
    this.proximaDose,
    this.ultimaDoseTomada,
    this.id,
    this.posologiaId,
  });
}

@HiveType(typeId: 105)
class AniversarioInfo {
  @HiveField(0)
  String nomePessoa;

  @HiveField(1)
  DateTime? dataNascimento;

  @HiveField(2)
  int notificarAntes; // dias antes

  @HiveField(3)
  String? mensagemPadrao;

  @HiveField(4)
  String? cartaoImagemUrl;

  @HiveField(5)
  bool permitirEnvioCartao;

  @HiveField(6)
  String? status; // "PROXIMO", "HOJE"

  @HiveField(7)
  String? telefone;

  @HiveField(8, defaultValue: false)
  bool mensagemGeradaPorIA;

  @HiveField(9, defaultValue: true)
  bool precisaConfirmarAntesDeEnviar;

  @HiveField(10)
  int? ultimoAnoEnviado;

  @HiveField(11)
  String? parentesco;

  @HiveField(12)
  String? emailContato;

  @HiveField(13)
  String? smsPhone;

  AniversarioInfo({
    required this.nomePessoa,
    this.dataNascimento,
    this.notificarAntes = 1,
    this.mensagemPadrao, // Agora representa mensagemPersonalizada
    this.cartaoImagemUrl,
    this.permitirEnvioCartao = true,
    this.status,
    this.telefone, // whatsappPhone
    this.mensagemGeradaPorIA = false,
    this.precisaConfirmarAntesDeEnviar = true,
    this.ultimoAnoEnviado,
    this.parentesco,
    this.emailContato,
    this.smsPhone,
  });
}

@HiveType(typeId: 106)
class Anexo {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tipo; // "DOCUMENTO", "IMAGEM", "VIDEO", "AUDIO", "URL", "ARQUIVO_LOCAL", "PASTA_LOCAL"

  @HiveField(2)
  String? nome;

  @HiveField(3)
  String? url;

  @HiveField(4)
  String? caminhoLocal;

  @HiveField(5)
  int? tamanhoBytes;

  @HiveField(6)
  DateTime criadoEm;

  Anexo({
    required this.id,
    required this.tipo,
    this.nome,
    this.url,
    this.caminhoLocal,
    this.tamanhoBytes,
    required this.criadoEm,
  });
}

@HiveType(typeId: 107)
class AgendaItem extends HiveObject {
  @HiveField(0)
  AgendaItemType tipo;

  @HiveField(1)
  String titulo;

  @HiveField(2)
  String? descricao;

  @HiveField(3)
  DateTime? dataInicio;

  @HiveField(4)
  DateTime? dataFim;

  @HiveField(5)
  String? horarioInicio;

  @HiveField(6)
  String? horarioFim;

  @HiveField(7)
  List<String>? categorias;

  @HiveField(8)
  ItemStatus? status;

  @HiveField(9)
  RecorrenciaInfo? recorrencia;

  @HiveField(10)
  PagamentoInfo? pagamento;

  @HiveField(11)
  RemedioInfo? remedio;

  @HiveField(12)
  AniversarioInfo? aniversario;

  @HiveField(13)
  List<Anexo>? anexos;

  @HiveField(14)
  DateTime criadoEm;

  @HiveField(15)
  DateTime atualizadoEm;

  @HiveField(16)
  String? googleEventId; // ID do evento no Google Calendar

  AgendaItem({
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.dataInicio,
    this.dataFim,
    this.horarioInicio,
    this.horarioFim,
    this.categorias,
    this.status,
    this.recorrencia,
    this.pagamento,
    this.remedio,
    this.aniversario,
    this.anexos,
    this.googleEventId,
    DateTime? criado,
    DateTime? atualizado,
  })  : criadoEm = criado ?? DateTime.now(),
        atualizadoEm = atualizado ?? DateTime.now();
}
