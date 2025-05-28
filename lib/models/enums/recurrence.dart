import 'package:hive/hive.dart';

part 'recurrence.g.dart'; // Add part directive

@HiveType(typeId: 2) // Assign unique typeId
enum Recurrence {
  @HiveField(0)
  none, // For one-off goals or tasks
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
} 