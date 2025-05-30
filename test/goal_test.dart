import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:questy/main.dart';
import 'package:questy/models/habit.dart';
import 'package:questy/models/habit_task.dart';
import 'package:questy/models/enums/habit_type.dart';
import 'package:questy/models/enums/recurrence.dart';
import 'package:questy/providers/habit_provider.dart';
import 'package:questy/models/user.dart';
import 'package:questy/models/attribute_stats.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUp(() async {
    // Initialize Hive for testing
    WidgetsFlutterBinding.ensureInitialized();
    
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register Adapters exactly as in main.dart
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
  });

  tearDown(() async {
    // Close and delete the test boxes
    await Hive.deleteBoxFromDisk('habits');
    await Hive.deleteBoxFromDisk('preferences');
    await Hive.close();
  });

  testWidgets('Create and complete a goal with HICCUP attributes test', (WidgetTester tester) async {
    // Create a test app with the HabitProvider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HabitProvider()),
          ChangeNotifierProvider(create: (_) => User(
            id: 'test-user',
            name: 'Test User',
            attributeStats: AttributeStats(),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: Text('Test'))),
        ),
      ),
    );
    
    // Get the HabitProvider and User
    final habitProvider = tester.element(find.text('Test')).read<HabitProvider>();
    final user = tester.element(find.text('Test')).read<User>();
    
    await habitProvider.loadHabits(); // Load habits from Hive
    
    // Create a test goal with tasks for each HICCUP attribute
    final goal = createTestGoalWithHICCUP();
    
    // Add the goal to the provider
    await habitProvider.addHabit(goal);
    
    // Verify the goal was added
    expect(habitProvider.habits.length, 1);
    expect(habitProvider.habits[0].concisePromptTitle, 'HICCUP Development Plan');
    
    // Record initial values
    final initialStarCurrency = user.starCurrency;
    final initialExp = user.exp;
    final initialHealth = user.attributeStats.health;
    final initialIntelligence = user.attributeStats.intelligence;
    final initialCleanliness = user.attributeStats.cleanliness;
    final initialCharisma = user.attributeStats.charisma;
    final initialUnity = user.attributeStats.unity;
    final initialPower = user.attributeStats.power;
    
    // Complete all tasks in the goal
    await completeGoalTasks(habitProvider, goal, user);
    
    // Verify all tasks are completed
    final updatedGoal = habitProvider.habits.firstWhere((h) => h.id == goal.id);
    expect(updatedGoal.areAllTasksCompleted, true);
    
    // Verify star currency and exp increased
    expect(user.starCurrency, greaterThan(initialStarCurrency));
    expect(user.exp, greaterThan(initialExp));
    
    // Verify all HICCUP attributes increased
    expect(user.attributeStats.health, greaterThan(initialHealth));
    expect(user.attributeStats.intelligence, greaterThan(initialIntelligence));
    expect(user.attributeStats.cleanliness, greaterThan(initialCleanliness));
    expect(user.attributeStats.charisma, greaterThan(initialCharisma));
    expect(user.attributeStats.unity, greaterThan(initialUnity));
    expect(user.attributeStats.power, greaterThan(initialPower));
    
    // Print verification message
    print('Successfully created and completed a test goal with HICCUP attributes');
    print('Star Currency: $initialStarCurrency → ${user.starCurrency}');
    print('EXP: $initialExp → ${user.exp}');
    print('Health: ${initialHealth.toStringAsFixed(1)} → ${user.attributeStats.health.toStringAsFixed(1)}');
    print('Intelligence: ${initialIntelligence.toStringAsFixed(1)} → ${user.attributeStats.intelligence.toStringAsFixed(1)}');
    print('Cleanliness: ${initialCleanliness.toStringAsFixed(1)} → ${user.attributeStats.cleanliness.toStringAsFixed(1)}');
    print('Charisma: ${initialCharisma.toStringAsFixed(1)} → ${user.attributeStats.charisma.toStringAsFixed(1)}');
    print('Unity: ${initialUnity.toStringAsFixed(1)} → ${user.attributeStats.unity.toStringAsFixed(1)}');
    print('Power: ${initialPower.toStringAsFixed(1)} → ${user.attributeStats.power.toStringAsFixed(1)}');
  });
}

// Helper function to create a test goal with HICCUP attributes
Habit createTestGoalWithHICCUP() {
  final uuid = Uuid();
  
  // Create tasks for the goal, one for each HICCUP attribute
  final tasks = [
    HabitTask(
      id: uuid.v4(),
      description: 'Drink 2 liters of water daily',
      difficulty: 'Easy', // +0.5 attribute points, +5 EXP, +10 stars
      estimatedTimeMinutes: 10,
    ),
    HabitTask(
      id: uuid.v4(),
      description: 'Read a chapter of an educational book',
      difficulty: 'Medium', // +1.0 attribute points, +10 EXP, +25 stars
      estimatedTimeMinutes: 20,
    ),
    HabitTask(
      id: uuid.v4(),
      description: 'Clean and organize your workspace',
      difficulty: 'Easy', // +0.5 attribute points, +5 EXP, +10 stars
      estimatedTimeMinutes: 15,
    ),
    HabitTask(
      id: uuid.v4(),
      description: 'Practice public speaking for 15 minutes',
      difficulty: 'Medium', // +1.0 attribute points, +10 EXP, +25 stars
      estimatedTimeMinutes: 15,
    ),
    HabitTask(
      id: uuid.v4(),
      description: 'Meditate for 10 minutes',
      difficulty: 'Easy', // +0.5 attribute points, +5 EXP, +10 stars
      estimatedTimeMinutes: 10,
    ),
    HabitTask(
      id: uuid.v4(),
      description: 'Complete a 30-minute workout',
      difficulty: 'Hard', // +2.0 attribute points, +20 EXP, +50 stars
      estimatedTimeMinutes: 30,
    ),
  ];
  
  // Create and return the goal
  return Habit(
    id: uuid.v4(),
    description: 'This is a comprehensive test goal that develops all HICCUP attributes',
    concisePromptTitle: 'HICCUP Development Plan',
    tasks: tasks,
    createdAt: DateTime.now(),
    habitType: HabitType.goal,
    recurrence: Recurrence.none,
  );
}

// Helper function to complete all tasks in a goal and increase HICCUP attributes
Future<void> completeGoalTasks(HabitProvider provider, Habit goal, User user) async {
  // Get the goal from the provider to ensure we have the latest version
  final currentGoal = provider.habits.firstWhere((h) => h.id == goal.id);
  
  // The HICCUP attributes in order
  final attributes = ['health', 'intelligence', 'cleanliness', 'charisma', 'unity', 'power'];
  
  // Mark each task as completed and award stars, exp, and attribute points
  for (int i = 0; i < currentGoal.tasks.length; i++) {
    final task = currentGoal.tasks[i];
    task.isCompleted = true;
    task.lastCompletedDate = DateTime.now();
    
    // Determine which attribute to increase based on task index
    // We're cycling through the HICCUP attributes in order
    final attributeToIncrease = attributes[i % attributes.length];
    
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
    
    // Store earned stars in the task
    task.pointsAwarded = starsAwarded;
  }
  
  // Update the goal in the provider
  await provider.updateHabit(currentGoal);
} 