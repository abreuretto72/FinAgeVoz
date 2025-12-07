// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 1;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      description: fields[3] as String,
      isCancelled: fields[4] as bool,
      recurrence: fields[5] as String?,
      lastNotifiedDate: fields[6] as DateTime?,
      attachments: (fields[7] as List?)?.cast<String>(),
      updatedAt: fields[8] as DateTime?,
      isDeleted: fields[9] as bool,
      isSynced: fields[10] as bool,
      reminderMinutes: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isCancelled)
      ..writeByte(5)
      ..write(obj.recurrence)
      ..writeByte(6)
      ..write(obj.lastNotifiedDate)
      ..writeByte(7)
      ..write(obj.attachments)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.reminderMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
