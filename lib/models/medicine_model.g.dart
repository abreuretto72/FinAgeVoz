// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RemedioAdapter extends TypeAdapter<Remedio> {
  @override
  final int typeId = 108;

  @override
  Remedio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Remedio(
      id: fields[0] as String,
      nome: fields[1] as String,
      nomeGenerico: fields[2] as String?,
      formaFarmaceutica: fields[3] as String,
      concentracao: fields[4] as String,
      viaAdministracao: fields[5] as String,
      indicacao: fields[6] as String?,
      observacoesMedico: fields[7] as String?,
      criadoEm: fields[8] as DateTime,
      atualizadoEm: fields[9] as DateTime,
      posologiaIds: (fields[10] as List).cast<String>(),
      attachments: (fields[11] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Remedio obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.nomeGenerico)
      ..writeByte(3)
      ..write(obj.formaFarmaceutica)
      ..writeByte(4)
      ..write(obj.concentracao)
      ..writeByte(5)
      ..write(obj.viaAdministracao)
      ..writeByte(6)
      ..write(obj.indicacao)
      ..writeByte(7)
      ..write(obj.observacoesMedico)
      ..writeByte(8)
      ..write(obj.criadoEm)
      ..writeByte(9)
      ..write(obj.atualizadoEm)
      ..writeByte(10)
      ..write(obj.posologiaIds)
      ..writeByte(11)
      ..write(obj.attachments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemedioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PosologiaAdapter extends TypeAdapter<Posologia> {
  @override
  final int typeId = 109;

  @override
  Posologia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Posologia(
      id: fields[0] as String,
      remedioId: fields[1] as String,
      quantidadePorDose: fields[2] as double,
      unidadeDose: fields[3] as String,
      frequenciaTipo: fields[4] as String,
      intervaloHoras: fields[5] as int?,
      horariosDoDia: (fields[6] as List?)?.cast<String>(),
      vezesAoDia: fields[7] as int?,
      diasDaSemana: (fields[8] as List?)?.cast<int>(),
      inicioTratamento: fields[9] as DateTime,
      fimTratamento: fields[10] as DateTime?,
      usoContinuo: fields[11] as bool,
      usarSeNecessario: fields[12] as bool,
      maxDosesPorDia: fields[13] as int?,
      tomarComAlimento: fields[14] as bool?,
      instrucoesExtras: fields[15] as String?,
      exigirConfirmacao: fields[16] as bool,
      criadoEm: fields[17] as DateTime,
      atualizadoEm: fields[18] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Posologia obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.remedioId)
      ..writeByte(2)
      ..write(obj.quantidadePorDose)
      ..writeByte(3)
      ..write(obj.unidadeDose)
      ..writeByte(4)
      ..write(obj.frequenciaTipo)
      ..writeByte(5)
      ..write(obj.intervaloHoras)
      ..writeByte(6)
      ..write(obj.horariosDoDia)
      ..writeByte(7)
      ..write(obj.vezesAoDia)
      ..writeByte(8)
      ..write(obj.diasDaSemana)
      ..writeByte(9)
      ..write(obj.inicioTratamento)
      ..writeByte(10)
      ..write(obj.fimTratamento)
      ..writeByte(11)
      ..write(obj.usoContinuo)
      ..writeByte(12)
      ..write(obj.usarSeNecessario)
      ..writeByte(13)
      ..write(obj.maxDosesPorDia)
      ..writeByte(14)
      ..write(obj.tomarComAlimento)
      ..writeByte(15)
      ..write(obj.instrucoesExtras)
      ..writeByte(16)
      ..write(obj.exigirConfirmacao)
      ..writeByte(17)
      ..write(obj.criadoEm)
      ..writeByte(18)
      ..write(obj.atualizadoEm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosologiaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoricoTomadaAdapter extends TypeAdapter<HistoricoTomada> {
  @override
  final int typeId = 110;

  @override
  HistoricoTomada read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoricoTomada(
      id: fields[0] as String,
      posologiaId: fields[1] as String,
      dataHoraProgramada: fields[2] as DateTime,
      dataHoraReal: fields[3] as DateTime?,
      taken: fields[4] as bool,
      observacao: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoricoTomada obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.posologiaId)
      ..writeByte(2)
      ..write(obj.dataHoraProgramada)
      ..writeByte(3)
      ..write(obj.dataHoraReal)
      ..writeByte(4)
      ..write(obj.taken)
      ..writeByte(5)
      ..write(obj.observacao);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoricoTomadaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
