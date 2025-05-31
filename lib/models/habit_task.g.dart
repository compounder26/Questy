// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitTaskAdapter extends TypeAdapter<HabitTask> {
  @override
  final int typeId = 3;

  @override
  HabitTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitTask(
      id: fields[0] as String,
      description: fields[1] as String,
      difficulty: fields[2] as String,
      estimatedTimeMinutes: fields[3] as int,
      isCompleted: fields[4] as bool,
      lastCompletedDate: fields[5] as DateTime?,
      pointsAwarded: fields[6] as int?,
      expAwarded: fields[7] as int?,
      attributesAwarded: (fields[8] as Map?)?.cast<String, double>(),
      lastVerifiedTimestamp: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitTask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.difficulty)
      ..writeByte(3)
      ..write(obj.estimatedTimeMinutes)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.lastCompletedDate)
      ..writeByte(6)
      ..write(obj.pointsAwarded)
      ..writeByte(7)
      ..write(obj.expAwarded)
      ..writeByte(8)
      ..write(obj.attributesAwarded)
      ..writeByte(9)
      ..write(obj.lastVerifiedTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
