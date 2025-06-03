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
  @HiveField(4)
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
  @HiveField(10)
  bool isNonHabitTask; // New field to track if this is a non-habit task

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
  });
  
  // Helper method to get attribute changes as a list
  List<AttributeChange> getAttributeChanges() {
    List<AttributeChange> changes = [];
    attributesAwarded?.forEach((name, amount) {
      changes.add(AttributeChange(name: name, amount: amount));
    });
    return changes;
  }
}