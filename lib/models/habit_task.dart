import 'package:hive/hive.dart';

part 'habit_task.g.dart'; // Part directive for generated code

// Simple class to track attribute changes
class AttributeChange {
  final String name; // attribute name (health, intelligence, etc.)
  final double amount; // amount increased
  
  AttributeChange({required this.name, required this.amount});
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }
  
  factory AttributeChange.fromMap(Map<String, dynamic> map) {
    return AttributeChange(
      name: map['name'],
      amount: map['amount'],
    );
  }
}

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
  @HiveField(4, defaultValue: false)
  bool isCompleted;
  @HiveField(5)
  DateTime? lastCompletedDate; // Field 5: Last completion date
  @HiveField(6)
  int? pointsAwarded;
  @HiveField(7)
  int? expAwarded;
  @HiveField(8)
  Map<String, double>? attributesAwarded; // Map of attribute name to amount
  @HiveField(9)
  DateTime? lastVerifiedTimestamp; // For per-task cooldown tracking
  @HiveField(10, defaultValue: false)
  bool isNonHabitTask; // New field to track if this is a non-habit task
  @HiveField(11)
  final String? detailedDescription; // Detailed description from AI
  @HiveField(12)
  int? cooldownDurationInMinutes; // Cooldown duration for this specific task

  HabitTask({
    required this.id,
    required this.description,
    required this.difficulty,
    required this.estimatedTimeMinutes,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.pointsAwarded,
    this.expAwarded,
    this.attributesAwarded,
    this.lastVerifiedTimestamp,
    this.isNonHabitTask = false, // Default to false
    this.detailedDescription,
    this.cooldownDurationInMinutes,
  });
  
  // Helper method to get attribute changes as a list
  List<AttributeChange> getAttributeChanges() {
    List<AttributeChange> changes = [];
    attributesAwarded?.forEach((name, amount) {
      changes.add(AttributeChange(name: name, amount: amount));
    });
    return changes;
  }

  // Cooldown logic for individual tasks
  bool get isCoolingDown {
    if (lastVerifiedTimestamp == null || cooldownDurationInMinutes == null || cooldownDurationInMinutes == 0) {
      return false;
    }
    final cooldownEndTime = lastVerifiedTimestamp!.add(Duration(minutes: cooldownDurationInMinutes!));
    return DateTime.now().isBefore(cooldownEndTime);
  }

  Duration get cooldownTimeRemaining {
    if (!isCoolingDown || lastVerifiedTimestamp == null || cooldownDurationInMinutes == null) {
      return Duration.zero;
    }
    final cooldownEndTime = lastVerifiedTimestamp!.add(Duration(minutes: cooldownDurationInMinutes!));
    return cooldownEndTime.difference(DateTime.now());
  }

  HabitTask copyWith({
    String? id,
    String? description,
    String? difficulty,
    int? estimatedTimeMinutes,
    bool? isCompleted,
    DateTime? lastCompletedDate,
    bool setLastCompletedDateToNull = false,
    int? pointsAwarded,
    bool setPointsAwardedToNull = false,
    int? expAwarded,
    bool setExpAwardedToNull = false,
    Map<String, double>? attributesAwarded,
    bool setAttributesAwardedToNull = false,
    DateTime? lastVerifiedTimestamp,
    bool setLastVerifiedTimestampToNull = false,
    bool? isNonHabitTask,
    String? detailedDescription,
    bool setDetailedDescriptionToNull = false,
    int? cooldownDurationInMinutes,
    bool setCooldownDurationInMinutesToNull = false,
  }) {
    return HabitTask(
      id: id ?? this.id,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      lastCompletedDate: setLastCompletedDateToNull ? null : (lastCompletedDate ?? this.lastCompletedDate),
      pointsAwarded: setPointsAwardedToNull ? null : (pointsAwarded ?? this.pointsAwarded),
      expAwarded: setExpAwardedToNull ? null : (expAwarded ?? this.expAwarded),
      attributesAwarded: setAttributesAwardedToNull 
          ? null 
          : (attributesAwarded ?? (this.attributesAwarded != null ? Map.from(this.attributesAwarded!) : null)),
      lastVerifiedTimestamp: setLastVerifiedTimestampToNull ? null : (lastVerifiedTimestamp ?? this.lastVerifiedTimestamp),
      isNonHabitTask: isNonHabitTask ?? this.isNonHabitTask,
      detailedDescription: setDetailedDescriptionToNull ? null : (detailedDescription ?? this.detailedDescription),
      cooldownDurationInMinutes: setCooldownDurationInMinutesToNull ? null : (cooldownDurationInMinutes ?? this.cooldownDurationInMinutes),
    );
  }
}