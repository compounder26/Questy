import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'services/ai_service.dart';
import 'models/user.dart';
import 'providers/habit_provider.dart';
import 'providers/character_provider.dart';
import 'providers/inventory_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'services/user_service.dart';

// Import models and generated adapters
import 'models/habit.dart';
import 'models/habit_task.dart';
import 'models/enums/habit_type.dart';
import 'models/enums/recurrence.dart';
import 'models/inventory_item.dart';
import 'utils/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  try {
    await EnvConfig.initialize();
  } catch (e) {
    print('Failed to initialize environment config: $e');
  }

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
  if (!Hive.isAdapterRegistered(5)) {
    // TypeId 5 for InventoryItemAdapter
    Hive.registerAdapter(InventoryItemAdapter());
  }

  // Open Boxes
  await Hive.openBox<Habit>('habits'); // Open the box for Habits
  await Hive.openBox('preferences'); // Open the box for preferences
  await Hive.openBox<InventoryItem>(
      'inventory'); // Open the box for inventory items

  // Load or create the user
  User? savedUser = await UserService.loadUser();

  runApp(MyApp(savedUser: savedUser));
}

class MyApp extends StatelessWidget {
  final User? savedUser;

  const MyApp({super.key, this.savedUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AIService>(
          create: (_) => AIService(),
        ),
        ChangeNotifierProvider<User>(
          create: (_) =>
              savedUser ??
              User(
                id: '1',
                name: 'User',
              ),
        ),
        ChangeNotifierProvider<HabitProvider>(
          // Load habits when HabitProvider is created
          create: (_) {
            final provider = HabitProvider();
            provider.loadHabits(); // Load habits from Hive
            return provider;
          },
        ),
        ChangeNotifierProvider<CharacterProvider>(
          create: (_) {
            final provider = CharacterProvider();
            provider.loadPreferences(); // Load character preferences
            return provider;
          },
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (_) {
            final provider = InventoryProvider();
            // Initialize inventory provider to load items from storage
            provider.initialize();
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Questy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
          ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
          ),
        ),
        themeMode: ThemeMode.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const MainScreen(),
          '/inventory': (context) => const InventoryScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Updated to only include HomeScreen
  final List<Widget> _screens = [
    const HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _screens[0], // Always show the HomeScreen
      // Removed bottomNavigationBar since we no longer need navigation
    );
  }
}
