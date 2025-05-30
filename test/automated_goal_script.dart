import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:questy/models/habit.dart';
import 'package:questy/models/habit_task.dart';
import 'package:questy/models/enums/habit_type.dart';
import 'package:questy/models/enums/recurrence.dart';
import 'package:questy/providers/habit_provider.dart';
import 'package:questy/models/user.dart';
import 'package:questy/models/attribute_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:convert';

/// A standalone script that can be run to test creating and completing goals
/// without requiring UI interaction.
///
/// To run this script:
/// 1. Make sure your app is not running
/// 2. Run: flutter run -d <device_id> test/automated_goal_script.dart
void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting automated goal testing script...');
  
  try {
    // Initialize Hive
    await initializeHive();
    
    // Create a habit provider
    final habitProvider = HabitProvider();
    await habitProvider.loadHabits();
    
    // Create or load user
    final user = await loadOrCreateUser();
    print('Initial user star currency: ${user.starCurrency}');
    print('Initial user exp: ${user.exp}');
    print('Initial user level: ${user.level}');
    printAttributeStats(user.attributeStats);
    
    print('Initial habit count: ${habitProvider.habits.length}');
    
    // Create and add test goals
    final testGoals = createTestGoals(6); // Create 6 test goals to ensure coverage of all attributes
    for (var goal in testGoals) {
      await habitProvider.addHabit(goal);
      print('Added goal: ${goal.concisePromptTitle}');
    }
    
    print('After adding goals, habit count: ${habitProvider.habits.length}');
    
    // Complete tasks for each goal
    for (var goal in testGoals) {
      await completeGoalTasks(habitProvider, goal, user);
      print('Completed all tasks for goal: ${goal.concisePromptTitle}');
      
      // Verify the goal is now completed
      final updatedGoal = habitProvider.habits.firstWhere((h) => h.id == goal.id);
      print('Goal "${updatedGoal.concisePromptTitle}" completion status: ${updatedGoal.areAllTasksCompleted}');
    }
    
    // Save user data to make sure points persist
    await saveUserData(user);
    print('Final user star currency: ${user.starCurrency}');
    print('Final user exp: ${user.exp}');
    print('Final user level: ${user.level}');
    printAttributeStats(user.attributeStats);
    print('Test completed successfully!');
  } catch (e) {
    print('Error during testing: $e');
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
  await Hive.openBox('preferences');
  
  print('Hive initialized successfully');
}

/// Create a specified number of test goals
List<Habit> createTestGoals(int count) {
  final goals = <Habit>[];
  final uuid = Uuid();
  
  // List of HICCUP attributes to cycle through
  final attributes = ['health', 'intelligence', 'cleanliness', 'charisma', 'unity', 'power'];
  // List of sample activities for each attribute to make tasks more realistic
  final attributeActivities = {
    'health': [
      'Drink 2 liters of water',
      'Eat a healthy meal with vegetables',
      'Get 8 hours of sleep',
      'Take vitamins and supplements',
      'Prepare healthy snacks for the day'
    ],
    'intelligence': [
      'Read a chapter of an educational book',
      'Complete an online course module',
      'Watch an educational video',
      'Practice a new language',
      'Solve puzzles or brain teasers'
    ],
    'cleanliness': [
      'Clean the bathroom',
      'Organize desk and workspace',
      'Do laundry and fold clothes',
      'Vacuum and dust the house',
      'Declutter a specific area'
    ],
    'charisma': [
      'Reach out to a friend',
      'Practice public speaking',
      'Attend a social event',
      'Join a group discussion',
      'Give a presentation'
    ],
    'unity': [
      'Meditate for 10 minutes',
      'Journal about your feelings',
      'Practice gratitude',
      'Take a break from social media',
      'Spend time in nature'
    ],
    'power': [
      'Do a strength workout',
      'Go for a run or jog',
      'Practice yoga or stretching',
      'Go to the gym',
      'Do bodyweight exercises'
    ]
  };
  
  // Make sure we create enough goals to have all attributes represented
  final attributesPerGoal = 1; // Each goal focuses primarily on one attribute
  final goalCount = max(count, attributes.length); // Ensure at least one goal per attribute
  
  for (int i = 0; i < goalCount; i++) {
    final primaryAttribute = attributes[i % attributes.length];
    final activityList = attributeActivities[primaryAttribute]!;
    
    // Create 5 tasks for this goal
    final tasks = <HabitTask>[];
    for (int j = 0; j < 5; j++) {
      // Cycle through difficulty levels
      final difficulty = j % 3 == 0 ? 'Easy' : (j % 3 == 1 ? 'Medium' : 'Hard');
      
      // Rotate through attributes for tasks, with majority being the primary attribute
      String taskAttribute;
      if (j < 3) {
        // First 3 tasks use the primary attribute
        taskAttribute = primaryAttribute;
      } else {
        // Last 2 tasks use different attributes
        taskAttribute = attributes[(i + j) % attributes.length];
      }
      
      // Get a random activity appropriate for this attribute
      final random = Random();
      final activityIndex = random.nextInt(attributeActivities[taskAttribute]!.length);
      final activity = attributeActivities[taskAttribute]![activityIndex];
      
      // Create the task
      tasks.add(HabitTask(
        id: uuid.v4(),
        description: activity,
        difficulty: difficulty,
        estimatedTimeMinutes: (difficulty == 'Easy' ? 10 : (difficulty == 'Medium' ? 20 : 30)),
      ));
    }
    
    // Create the goal with a title that reflects its primary attribute
    final goal = Habit(
      id: uuid.v4(),
      description: 'This is a test goal focused on improving ${primaryAttribute.toUpperCase()} created by the automated script',
      concisePromptTitle: '${primaryAttribute.substring(0, 1).toUpperCase() + primaryAttribute.substring(1)} Development Plan',
      tasks: tasks,
      createdAt: DateTime.now(),
      habitType: HabitType.goal,
      recurrence: Recurrence.none,
    );
    
    goals.add(goal);
  }
  
  return goals;
}

/// Complete all tasks for a given goal and award star currency and exp
Future<void> completeGoalTasks(HabitProvider provider, Habit goal, User user) async {
  // Get the goal from the provider to ensure we have the latest version
  final currentGoal = provider.habits.firstWhere((h) => h.id == goal.id);
  
  // Map of HICCUP attributes for task attribution
  final attributes = ['health', 'intelligence', 'cleanliness', 'charisma', 'unity', 'power'];

  // Mark each task as completed and award stars and exp
  for (int i = 0; i < currentGoal.tasks.length; i++) {
    final task = currentGoal.tasks[i];
    task.isCompleted = true;
    task.lastCompletedDate = DateTime.now();
    
    // Determine which attribute to increase for this task
    // For test purposes, we're cycling through attributes to ensure each gets developed
    String attributeToIncrease;
    if (i < 3) {
      // Primary attribute for this goal (inferred from the goal title)
      attributeToIncrease = currentGoal.concisePromptTitle.split(' ')[0].toLowerCase();
      if (!attributes.contains(attributeToIncrease)) {
        // Fallback if we can't extract the attribute from the title
        attributeToIncrease = attributes[i % attributes.length];
      }
    } else {
      // Secondary attributes
      attributeToIncrease = attributes[(attributes.indexOf(currentGoal.concisePromptTitle.split(' ')[0].toLowerCase()) + i) % attributes.length];
    }
    
    // Award stars, exp, and attribute points based on difficulty
    int starsAwarded;
    int expAwarded;
    double attributePoints;
    
    switch (task.difficulty.toLowerCase()) {
      case 'easy':
        starsAwarded = 10;
        expAwarded = 5;
        attributePoints = 0.5;
        break;
      case 'medium':
        starsAwarded = 25;
        expAwarded = 10;
        attributePoints = 1.0;
        break;
      case 'hard':
        starsAwarded = 50;
        expAwarded = 20;
        attributePoints = 2.0;
        break;
      default:
        starsAwarded = 15;
        expAwarded = 8;
        attributePoints = 0.5;
    }
    
    // Award star currency and exp
    user.addStarCurrency(starsAwarded);
    user.addExp(expAwarded);
    
    // Increase the attribute
    user.increaseAttribute(attributeToIncrease, attributePoints);
    
    // Store earned points in the task
    task.pointsAwarded = starsAwarded;
    
    print('  - Completed task: ${task.description}');
    print('    - Awarded $starsAwarded stars, $expAwarded exp');
    print('    - Increased $attributeToIncrease by $attributePoints points');
    
    // Add a small delay to simulate real usage
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  // Update the goal in the provider
  await provider.updateHabit(currentGoal);
}

/// Load or create user with saved data
Future<User> loadOrCreateUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userData = prefs.getString('user_data');
  
  if (userData != null) {
    try {
      final Map<String, dynamic> userMap = json.decode(userData);
      return User.fromJson(userMap);
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  // Create default user if none exists
  return User(
    id: '1', 
    name: 'Test User',
    attributeStats: AttributeStats(), // Initialize with default stats
  );
}

/// Save user data to ensure persistence
Future<void> saveUserData(User user) async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = json.encode(user.toJson());
  await prefs.setString('user_data', userJson);
  print('User data saved successfully');
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