// App reset test for simulating a fresh install
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:questy/models/habit.dart';
import 'package:questy/models/habit_task.dart';
import 'package:questy/models/attribute_stats.dart';
import 'package:questy/models/enums/habit_type.dart';
import 'package:questy/models/enums/recurrence.dart';

// Create a custom adapter for AttributeStats to fix the lint error
class AttributeStatsAdapter extends TypeAdapter<AttributeStats> {
  @override
  final int typeId = 4; // Use a unique type ID

  @override
  AttributeStats read(BinaryReader reader) {
    // Read AttributeStats from binary
    // This is simplified - in a real adapter you would read all fields
    return AttributeStats(
      health: reader.readDouble(),
      intelligence: reader.readDouble(),
      cleanliness: reader.readDouble(),
      charisma: reader.readDouble(),
      unity: reader.readDouble(),
      power: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, AttributeStats obj) {
    // Write AttributeStats to binary
    // This is simplified - in a real adapter you would write all fields
    writer.writeDouble(obj.health);
    writer.writeDouble(obj.intelligence);
    writer.writeDouble(obj.cleanliness);
    writer.writeDouble(obj.charisma);
    writer.writeDouble(obj.unity);
    writer.writeDouble(obj.power);
  }
}

void main() {
  // Initialize the Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Reset Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing with a temporary directory
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitTypeAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(RecurrenceAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(HabitTaskAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(AttributeStatsAdapter());
    });

    test('App reset - fresh start simulation', () async {
      // Open boxes
      final habitsBox = await Hive.openBox<Habit>('habits');
      final tasksBox = await Hive.openBox<HabitTask>('tasks');
      final attributeStatsBox = await Hive.openBox<AttributeStats>('attribute_stats');
      
      // Simulate app reset by clearing all boxes
      await habitsBox.clear();
      await tasksBox.clear();
      await attributeStatsBox.clear();
      
      // Check if habitsBox is empty
      expect(habitsBox.length, 0);
      
      // Check if tasksBox is empty
      expect(tasksBox.length, 0);
      
      // Check if attributeStatsBox is empty
      expect(attributeStatsBox.length, 0);
      
      // Add default AttributeStats with zeroed values
      final defaultStats = AttributeStats(
        health: 0.0,
        intelligence: 0.0,
        cleanliness: 0.0,
        charisma: 0.0,
        unity: 0.0,
        power: 0.0
      );
      await attributeStatsBox.add(defaultStats);
      
      // Verify attributeStats are reset to 0
      final stats = attributeStatsBox.getAt(0);
      expect(stats?.health, 0.0);
      expect(stats?.intelligence, 0.0);
      expect(stats?.cleanliness, 0.0);
      expect(stats?.charisma, 0.0);
      expect(stats?.unity, 0.0);
      expect(stats?.power, 0.0);
      
      // Verify levels are set to novice
      expect(stats?.healthLevel, AttributeLevel.novice);
      expect(stats?.intelligenceLevel, AttributeLevel.novice);
      expect(stats?.cleanlinessLevel, AttributeLevel.novice);
      expect(stats?.charismaLevel, AttributeLevel.novice);
      expect(stats?.unityLevel, AttributeLevel.novice);
      expect(stats?.powerLevel, AttributeLevel.novice);
      
      // Close all boxes
      await habitsBox.close();
      await tasksBox.close();
      await attributeStatsBox.close();
    });
  });
}
