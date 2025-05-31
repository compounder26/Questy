// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      description: fields[1] as String,
      concisePromptTitle: fields[2] as String,
      tasks: (fields[3] as List).cast<HabitTask>(),
      createdAt: fields[4] as DateTime,
      habitType: fields[5] as HabitType,
      recurrence: fields[6] as Recurrence,
      endDate: fields[7] as DateTime?,
      weeklyTarget: fields[8] as int?,
      weeklyProgress: fields[9] as int,
      lastUpdated: fields[10] as DateTime?,
      cooldownDurationInMinutes: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.concisePromptTitle)
      ..writeByte(3)
      ..write(obj.tasks)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.habitType)
      ..writeByte(6)
      ..write(obj.recurrence)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.weeklyTarget)
      ..writeByte(9)
      ..write(obj.weeklyProgress)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.cooldownDurationInMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
