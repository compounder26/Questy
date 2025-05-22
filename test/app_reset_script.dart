import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:questy/models/habit.dart';
import 'package:questy/models/habit_task.dart';
import 'package:questy/models/enums/habit_type.dart';
import 'package:questy/models/enums/recurrence.dart';
import 'package:questy/models/user.dart';
import 'package:questy/models/attribute_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A standalone script that simulates a fresh app installation by clearing all data
/// and resetting the app state.
///
/// To run this script:
/// 1. Make sure your app is not running
/// 2. Run: flutter run -d <device_id> test/app_reset_script.dart
void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting app reset script...');
  print('This will simulate a fresh app installation by clearing all data.');

  try {
    // Initialize Hive
    await initializeHive();

    // Clear all data from Hive boxes
    await resetAllData();

    // Create default user with zero attributes
    final user = await createNewUser();
    
    // Verify the reset was successful
    await verifyReset();
    
    // Save the new user data
    await saveUserData(user);
    
    print('App reset completed successfully!');
    print('The app is now in a fresh state as if it was just installed.');
  } catch (e) {
    print('Error during app reset: $e');
  } finally {
    // Clean up Hive
    await Hive.close();
  }
}

/// Initialize Hive with all required adapters
Future<void> initializeHive() async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Adapters
  if (!Hive.isAdapterRegistered(HabitTypeAdapter().typeId)) {
    Hive.registerAdapter(HabitTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(RecurrenceAdapter().typeId)) {
    Hive.registerAdapter(RecurrenceAdapter());
  }
  if (!Hive.isAdapterRegistered(HabitTaskAdapter().typeId)) {
    Hive.registerAdapter(HabitTaskAdapter());
  }
  if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
    Hive.registerAdapter(HabitAdapter());
  }

  // Open Boxes
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<HabitTask>('tasks');
  await Hive.openBox('preferences');

  print('Hive initialized successfully');
}

/// Reset all data by clearing Hive boxes and SharedPreferences
Future<void> resetAllData() async {
  // Clear Hive boxes
  final habitsBox = Hive.box<Habit>('habits');
  final tasksBox = Hive.box<HabitTask>('tasks');
  final prefsBox = Hive.box('preferences');
  
  print('Before reset:');
  print('- Habits count: ${habitsBox.length}');
  print('- Tasks count: ${tasksBox.length}');
  
  // Clear all boxes
  await habitsBox.clear();
  await tasksBox.clear();
  await prefsBox.clear();
  
  // Clear SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  print('After reset:');
  print('- Habits count: ${habitsBox.length}');
  print('- Tasks count: ${tasksBox.length}');
  print('- SharedPreferences cleared');
}

/// Create a new user with zero attribute stats
Future<User> createNewUser() async {
  // Create new attribute stats with all zeros
  final newStats = AttributeStats(
    health: 0.0,
    intelligence: 0.0,
    cleanliness: 0.0,
    charisma: 0.0,
    unity: 0.0,
    power: 0.0,
    // All levels default to novice
  );
  
  // Create a new user with the zeroed stats
  final newUser = User(
    id: '1',
    name: 'New User',
    attributeStats: newStats,
    // Starting with zero currency and exp
  );
  
  print('Created new user with zero attributes:');
  printAttributeStats(newUser.attributeStats);
  print('User star currency: ${newUser.starCurrency}');
  print('User exp: ${newUser.exp}');
  print('User level: ${newUser.level}');
  
  return newUser;
}

/// Verify that the reset was successful
Future<void> verifyReset() async {
  // Check Hive boxes are empty
  final habitsBox = Hive.box<Habit>('habits');
  final tasksBox = Hive.box<HabitTask>('tasks');
  
  if (habitsBox.length > 0) {
    print('WARNING: Habits box still contains ${habitsBox.length} items after reset');
  } else {
    print('Verified: Habits box is empty');
  }
  
  if (tasksBox.length > 0) {
    print('WARNING: Tasks box still contains ${tasksBox.length} items after reset');
  } else {
    print('Verified: Tasks box is empty');
  }
  
  // Check SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  
  if (userData != null) {
    print('WARNING: User data still exists in SharedPreferences after reset');
  } else {
    print('Verified: No user data in SharedPreferences');
  }
}

/// Save user data to ensure persistence
Future<void> saveUserData(User user) async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = json.encode(user.toJson());
  await prefs.setString('user_data', userJson);
  print('New user data saved successfully');
}

/// Print the current attribute stats
void printAttributeStats(AttributeStats stats) {
  print('HICCUP Attribute Stats:');
  print('  - Health: ${stats.health.toStringAsFixed(1)} (${stats.healthLevel.displayName})');
  print('  - Intelligence: ${stats.intelligence.toStringAsFixed(1)} (${stats.intelligenceLevel.displayName})');
  print('  - Cleanliness: ${stats.cleanliness.toStringAsFixed(1)} (${stats.cleanlinessLevel.displayName})');
  print('  - Charisma: ${stats.charisma.toStringAsFixed(1)} (${stats.charismaLevel.displayName})');
  print('  - Unity: ${stats.unity.toStringAsFixed(1)} (${stats.unityLevel.displayName})');
  print('  - Power: ${stats.power.toStringAsFixed(1)} (${stats.powerLevel.displayName})');
}
