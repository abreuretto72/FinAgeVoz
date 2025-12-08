// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecorrenciaInfoAdapter extends TypeAdapter<RecorrenciaInfo> {
  @override
  final int typeId = 102;

  @override
  RecorrenciaInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecorrenciaInfo(
      frequencia: fields[0] as String,
      intervalo: fields[1] as int?,
      diasDaSemana: (fields[2] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecorrenciaInfo obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.frequencia)
      ..writeByte(1)
      ..write(obj.intervalo)
      ..writeByte(2)
      ..write(obj.diasDaSemana);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecorrenciaInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PagamentoInfoAdapter extends TypeAdapter<PagamentoInfo> {
  @override
  final int typeId = 103;

  @override
  PagamentoInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PagamentoInfo(
      valor: fields[0] as double,
      moeda: fields[1] as String,
      status: fields[2] as String,
      dataVencimento: fields[3] as DateTime,
      dataPagamento: fields[4] as DateTime?,
      recorrente: fields[5] as bool,
      forma: fields[6] as String?,
      descricaoFinanceira: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PagamentoInfo obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.valor)
      ..writeByte(1)
      ..write(obj.moeda)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.dataVencimento)
      ..writeByte(4)
      ..write(obj.dataPagamento)
      ..writeByte(5)
      ..write(obj.recorrente)
      ..writeByte(6)
      ..write(obj.forma)
      ..writeByte(7)
      ..write(obj.descricaoFinanceira);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagamentoInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RemedioInfoAdapter extends TypeAdapter<RemedioInfo> {
  @override
  final int typeId = 104;

  @override
  RemedioInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RemedioInfo(
      nome: fields[0] as String,
      dosagem: fields[1] as String,
      quantidade: fields[2] as int?,
      horario: fields[3] as String?,
      frequenciaTipo: fields[4] as String,
      intervalo: fields[5] as int,
      diasDaSemana: (fields[6] as List?)?.cast<int>(),
      inicioTratamento: fields[7] as DateTime,
      fimTratamento: fields[8] as DateTime?,
      exigirConfirmacao: fields[9] as bool,
      status: fields[10] as String,
      proximaDose: fields[11] as DateTime?,
      ultimaDoseTomada: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RemedioInfo obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.nome)
      ..writeByte(1)
      ..write(obj.dosagem)
      ..writeByte(2)
      ..write(obj.quantidade)
      ..writeByte(3)
      ..write(obj.horario)
      ..writeByte(4)
      ..write(obj.frequenciaTipo)
      ..writeByte(5)
      ..write(obj.intervalo)
      ..writeByte(6)
      ..write(obj.diasDaSemana)
      ..writeByte(7)
      ..write(obj.inicioTratamento)
      ..writeByte(8)
      ..write(obj.fimTratamento)
      ..writeByte(9)
      ..write(obj.exigirConfirmacao)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.proximaDose)
      ..writeByte(12)
      ..write(obj.ultimaDoseTomada);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedioInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AniversarioInfoAdapter extends TypeAdapter<AniversarioInfo> {
  @override
  final int typeId = 105;

  @override
  AniversarioInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AniversarioInfo(
      nomePessoa: fields[0] as String,
      dataNascimento: fields[1] as DateTime?,
      notificarAntes: fields[2] as int,
      mensagemPadrao: fields[3] as String?,
      cartaoImagemUrl: fields[4] as String?,
      permitirEnvioCartao: fields[5] as bool,
      status: fields[6] as String?,
      telefone: fields[7] as String?,
      mensagemGeradaPorIA: fields[8] == null ? false : fields[8] as bool,
      precisaConfirmarAntesDeEnviar:
          fields[9] == null ? true : fields[9] as bool,
      ultimoAnoEnviado: fields[10] as int?,
      parentesco: fields[11] as String?,
      emailContato: fields[12] as String?,
      smsPhone: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AniversarioInfo obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.nomePessoa)
      ..writeByte(1)
      ..write(obj.dataNascimento)
      ..writeByte(2)
      ..write(obj.notificarAntes)
      ..writeByte(3)
      ..write(obj.mensagemPadrao)
      ..writeByte(4)
      ..write(obj.cartaoImagemUrl)
      ..writeByte(5)
      ..write(obj.permitirEnvioCartao)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.telefone)
      ..writeByte(8)
      ..write(obj.mensagemGeradaPorIA)
      ..writeByte(9)
      ..write(obj.precisaConfirmarAntesDeEnviar)
      ..writeByte(10)
      ..write(obj.ultimoAnoEnviado)
      ..writeByte(11)
      ..write(obj.parentesco)
      ..writeByte(12)
      ..write(obj.emailContato)
      ..writeByte(13)
      ..write(obj.smsPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AniversarioInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnexoAdapter extends TypeAdapter<Anexo> {
  @override
  final int typeId = 106;

  @override
  Anexo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Anexo(
      id: fields[0] as String,
      tipo: fields[1] as String,
      nome: fields[2] as String?,
      url: fields[3] as String?,
      caminhoLocal: fields[4] as String?,
      tamanhoBytes: fields[5] as int?,
      criadoEm: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Anexo obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.nome)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.caminhoLocal)
      ..writeByte(5)
      ..write(obj.tamanhoBytes)
      ..writeByte(6)
      ..write(obj.criadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnexoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgendaItemAdapter extends TypeAdapter<AgendaItem> {
  @override
  final int typeId = 107;

  @override
  AgendaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgendaItem(
      tipo: fields[0] as AgendaItemType,
      titulo: fields[1] as String,
      descricao: fields[2] as String?,
      dataInicio: fields[3] as DateTime?,
      dataFim: fields[4] as DateTime?,
      horarioInicio: fields[5] as String?,
      horarioFim: fields[6] as String?,
      categorias: (fields[7] as List?)?.cast<String>(),
      status: fields[8] as ItemStatus?,
      recorrencia: fields[9] as RecorrenciaInfo?,
      pagamento: fields[10] as PagamentoInfo?,
      remedio: fields[11] as RemedioInfo?,
      aniversario: fields[12] as AniversarioInfo?,
      anexos: (fields[13] as List?)?.cast<Anexo>(),
    )
      ..criadoEm = fields[14] as DateTime
      ..atualizadoEm = fields[15] as DateTime;
  }

  @override
  void write(BinaryWriter writer, AgendaItem obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.tipo)
      ..writeByte(1)
      ..write(obj.titulo)
      ..writeByte(2)
      ..write(obj.descricao)
      ..writeByte(3)
      ..write(obj.dataInicio)
      ..writeByte(4)
      ..write(obj.dataFim)
      ..writeByte(5)
      ..write(obj.horarioInicio)
      ..writeByte(6)
      ..write(obj.horarioFim)
      ..writeByte(7)
      ..write(obj.categorias)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.recorrencia)
      ..writeByte(10)
      ..write(obj.pagamento)
      ..writeByte(11)
      ..write(obj.remedio)
      ..writeByte(12)
      ..write(obj.aniversario)
      ..writeByte(13)
      ..write(obj.anexos)
      ..writeByte(14)
      ..write(obj.criadoEm)
      ..writeByte(15)
      ..write(obj.atualizadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgendaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgendaItemTypeAdapter extends TypeAdapter<AgendaItemType> {
  @override
  final int typeId = 100;

  @override
  AgendaItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgendaItemType.COMPROMISSO;
      case 1:
        return AgendaItemType.TAREFA;
      case 2:
        return AgendaItemType.LEMBRETE;
      case 3:
        return AgendaItemType.META;
      case 4:
        return AgendaItemType.PROJETO;
      case 5:
        return AgendaItemType.NOTA;
      case 6:
        return AgendaItemType.EVENTO_RECORRENTE;
      case 7:
        return AgendaItemType.PRAZO;
      case 8:
        return AgendaItemType.ROTINA;
      case 9:
        return AgendaItemType.PAGAMENTO;
      case 10:
        return AgendaItemType.REMEDIO;
      case 11:
        return AgendaItemType.ANIVERSARIO;
      default:
        return AgendaItemType.COMPROMISSO;
    }
  }

  @override
  void write(BinaryWriter writer, AgendaItemType obj) {
    switch (obj) {
      case AgendaItemType.COMPROMISSO:
        writer.writeByte(0);
        break;
      case AgendaItemType.TAREFA:
        writer.writeByte(1);
        break;
      case AgendaItemType.LEMBRETE:
        writer.writeByte(2);
        break;
      case AgendaItemType.META:
        writer.writeByte(3);
        break;
      case AgendaItemType.PROJETO:
        writer.writeByte(4);
        break;
      case AgendaItemType.NOTA:
        writer.writeByte(5);
        break;
      case AgendaItemType.EVENTO_RECORRENTE:
        writer.writeByte(6);
        break;
      case AgendaItemType.PRAZO:
        writer.writeByte(7);
        break;
      case AgendaItemType.ROTINA:
        writer.writeByte(8);
        break;
      case AgendaItemType.PAGAMENTO:
        writer.writeByte(9);
        break;
      case AgendaItemType.REMEDIO:
        writer.writeByte(10);
        break;
      case AgendaItemType.ANIVERSARIO:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgendaItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 101;

  @override
  ItemStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemStatus.PENDENTE;
      case 1:
        return ItemStatus.EM_ANDAMENTO;
      case 2:
        return ItemStatus.CONCLUIDO;
      case 3:
        return ItemStatus.CANCELADO;
      default:
        return ItemStatus.PENDENTE;
    }
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    switch (obj) {
      case ItemStatus.PENDENTE:
        writer.writeByte(0);
        break;
      case ItemStatus.EM_ANDAMENTO:
        writer.writeByte(1);
        break;
      case ItemStatus.CONCLUIDO:
        writer.writeByte(2);
        break;
      case ItemStatus.CANCELADO:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
