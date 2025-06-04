import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/ai_service.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'models/user.dart';
import 'models/attribute_stats.dart';
import 'models/reward_persistence.dart'; // Import our new dedicated persistence system
import 'providers/habit_provider.dart';
import 'providers/character_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/reward_provider.dart'; // Import the new provider
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'services/user_service.dart';

// Import models and generated adapters
import 'models/habit.dart';
import 'models/habit_task.dart';
import 'models/enums/habit_type.dart';
import 'models/enums/recurrence.dart';
import 'models/inventory_item.dart';
// Reward model is accessed indirectly through RewardPersistence
import 'utils/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and AIService
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // AIService is now initialized via Provider, no local instance needed here.

  } catch (e) {
    print('Failed to initialize Firebase or AIService: $e');
  }

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
  await Hive.openBox<Habit>('archived_habits');
  await Hive.openBox('preferences'); // Open the box for preferences
  await Hive.openBox<InventoryItem>(
      'inventory'); // Open the box for inventory items

  // Load or create the user
  User? savedUser = await UserService.loadUser();
  
  // If we have a saved user, ensure it's properly persisted
  if (savedUser != null) {
    await UserService.saveUser(savedUser);
    print('User data reloaded and saved on app start');
  }

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
                starCurrency: 2000, // Start with 2000 stars
                exp: 500, // Start with some initial EXP
                attributeStats: AttributeStats(
                  health: 5,
                  intelligence: 5,
                  charisma: 5,
                  power: 5,
                  cleanliness: 5,
                  unity: 5,
                ),
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
        ChangeNotifierProvider<RewardProvider>(
          create: (context) {
            final provider = RewardProvider();
            // We'll load reward state after user is initialized
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
          fontFamily: 'ArcadeClassic',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
          ),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
          ),
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'ArcadeClassic'),
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

  late InventoryProvider _inventoryProvider;
  late User _user;

  @override
  void initState() {
    super.initState();
    // Get providers
    _user = Provider.of<User>(context, listen: false);
    _inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    
    // Initialize app state synchronization
    _initializeAppState();
  }
  
  // Initialize all app state in the correct order
  Future<void> _initializeAppState() async {
    try {
      print('========== APP RESTART: INITIALIZING STATE ==========');
      
      // Step 1: First load the user data from persistent storage
      final freshUser = await UserService.loadUser();
      if (freshUser != null) {
        // Update our user instance with the fresh data including purchase history
        _user.updateFromUser(freshUser);
        print('Loaded user data: ${_user.ownedRewardIds.length} owned rewards, ${_user.purchaseHistory.length} purchase records');
      } else {
        print('No saved user found, using default user');
      }
      
      // Step 2: SIMPLIFIED: Use our dedicated persistence system to load all reward state
      final rewardStateLoaded = await RewardPersistence.loadAll(_user);
      print('Reward persistence system loaded state: $rewardStateLoaded');
      
      // Step 3: SIMPLIFIED: Ensure inventory is synced with user's owned collectibles
      await _inventoryProvider.syncWithUser(_user);
      print('Inventory synced with user data');
      
      // Step 4: SIMPLIFIED: Final save of all state to ensure perfect consistency
      await UserService.saveUser(_user);
      print('User state saved after initialization');
      
      print('APP STATE INITIALIZATION COMPLETE WITH SIMPLIFIED REWARD PERSISTENCE');
      print('========== INITIALIZATION COMPLETE ==========');
    } catch (e) {
      print('ERROR during app state initialization: $e');
    }
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
