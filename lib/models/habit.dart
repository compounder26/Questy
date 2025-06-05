import 'package:hive/hive.dart';
import 'enums/habit_type.dart';
import 'enums/recurrence.dart';
import 'habit_task.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String description;
  @HiveField(2)
  final String concisePromptTitle;
  @HiveField(3)
  List<HabitTask> tasks;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final HabitType habitType;
  @HiveField(6)
  final Recurrence recurrence;
  @HiveField(7)
  final DateTime? endDate;
  @HiveField(8)
  final int? weeklyTarget;
  @HiveField(9)
  int weeklyProgress;
  @HiveField(10)
  DateTime lastUpdated;
  // HiveField(11) was cooldownDurationInMinutes, now removed for per-task cooldown

  Habit({
    required this.id,
    required this.description,
    required this.concisePromptTitle,
    required this.tasks,
    required this.createdAt,
    required this.habitType,
    required this.recurrence,
    this.endDate,
    this.weeklyTarget,
    this.weeklyProgress = 0,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  bool get isWeeklyGoalMet {
    if (recurrence != Recurrence.weekly || weeklyTarget == null) {
      return false;
    }
    return weeklyProgress >= weeklyTarget!;
  }

  bool get areAllTasksCompleted {
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task.isCompleted);
  }

  // isCoolingDown and cooldownTimeRemaining getters removed as cooldown is now per-task
}
