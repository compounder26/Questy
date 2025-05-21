// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceAdapter extends TypeAdapter<Recurrence> {
  @override
  final int typeId = 2;

  @override
  Recurrence read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Recurrence.none;
      case 1:
        return Recurrence.daily;
      case 2:
        return Recurrence.weekly;
      default:
        return Recurrence.none;
    }
  }

  @override
  void write(BinaryWriter writer, Recurrence obj) {
    switch (obj) {
      case Recurrence.none:
        writer.writeByte(0);
        break;
      case Recurrence.daily:
        writer.writeByte(1);
        break;
      case Recurrence.weekly:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 