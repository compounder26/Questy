// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletedTaskAdapter extends TypeAdapter<CompletedTask> {
  @override
  final int typeId = 4;

  @override
  CompletedTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedTask(
      id: fields[0] as String,
      description: fields[1] as String,
      difficulty: fields[2] as String,
      estimatedTimeMinutes: fields[3] as int,
      completionDate: fields[4] as DateTime,
      pointsAwarded: fields[5] as int?,
      expAwarded: fields[6] as int?,
      attributesAwarded: (fields[7] as Map?)?.cast<String, double>(),
      parentHabitId: fields[8] as String,
      parentHabitTitle: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedTask obj) {
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
      ..write(obj.completionDate)
      ..writeByte(5)
      ..write(obj.pointsAwarded)
      ..writeByte(6)
      ..write(obj.expAwarded)
      ..writeByte(7)
      ..write(obj.attributesAwarded)
      ..writeByte(8)
      ..write(obj.parentHabitId)
      ..writeByte(9)
      ..write(obj.parentHabitTitle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
