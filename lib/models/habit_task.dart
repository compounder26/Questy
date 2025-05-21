import 'package:hive/hive.dart';

part 'habit_task.g.dart'; // Part directive for generated code

@HiveType(typeId: 3) // Unique typeId for HabitTask
class HabitTask extends HiveObject { // Extend HiveObject
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String description;
  @HiveField(2)
  final String difficulty;
  @HiveField(3)
  final int estimatedTimeMinutes;
  @HiveField(4)
  bool isCompleted;
  @HiveField(5)
  DateTime? lastCompletedDate;
  @HiveField(6)
  int? pointsAwarded;

  HabitTask({
    required this.id,
    required this.description,
    required this.difficulty,
    required this.estimatedTimeMinutes,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.pointsAwarded,
  });
} 