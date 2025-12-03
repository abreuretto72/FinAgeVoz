// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OperationHistoryAdapter extends TypeAdapter<OperationHistory> {
  @override
  final int typeId = 4;

  @override
  OperationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OperationHistory(
      id: fields[0] as String,
      type: fields[1] as String,
      transactionIds: (fields[2] as List).cast<String>(),
      description: fields[3] as String,
      timestamp: fields[4] as DateTime,
      installmentCount: fields[5] as int?,
      totalAmount: fields[6] as double?,
      eventId: fields[7] as String?,
      eventSnapshot: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, OperationHistory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.transactionIds)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.installmentCount)
      ..writeByte(6)
      ..write(obj.totalAmount)
      ..writeByte(7)
      ..write(obj.eventId)
      ..writeByte(8)
      ..write(obj.eventSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
