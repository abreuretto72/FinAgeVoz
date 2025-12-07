// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      description: fields[1] as String,
      amount: fields[2] as double,
      isExpense: fields[3] as bool,
      date: fields[4] as DateTime,
      isReversal: fields[5] as bool,
      originalTransactionId: fields[6] as String?,
      category: fields[7] as String,
      subcategory: fields[8] as String?,
      installmentId: fields[9] as String?,
      installmentNumber: fields[10] as int?,
      totalInstallments: fields[11] as int?,
      attachments: (fields[12] as List?)?.cast<String>(),
      updatedAt: fields[13] as DateTime?,
      isDeleted: fields[14] as bool,
      isSynced: fields[15] as bool,
      isPaid: fields[16] as bool,
      paymentDate: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isExpense)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isReversal)
      ..writeByte(6)
      ..write(obj.originalTransactionId)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.subcategory)
      ..writeByte(9)
      ..write(obj.installmentId)
      ..writeByte(10)
      ..write(obj.installmentNumber)
      ..writeByte(11)
      ..write(obj.totalInstallments)
      ..writeByte(12)
      ..write(obj.attachments)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.isDeleted)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.isPaid)
      ..writeByte(17)
      ..write(obj.paymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
