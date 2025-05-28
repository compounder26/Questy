import 'package:hive/hive.dart';

part 'habit_type.g.dart'; // Add part directive

@HiveType(typeId: 1) // Assign unique typeId
enum HabitType {
  @HiveField(0)
  goal, // A one-off objective with specific tasks
  @HiveField(1)
  habit, // A recurring activity
} 