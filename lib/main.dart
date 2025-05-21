import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'services/ai_service.dart';
import 'models/user.dart';
import 'providers/habit_provider.dart';
import 'providers/character_provider.dart';
import 'models/character.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Import models and generated adapters
import 'models/habit.dart';
import 'models/habit_task.dart';
import 'models/enums/habit_type.dart';
import 'models/enums/recurrence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await Hive.openBox<Habit>('habits'); // Open the box for Habits

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AIService>(
          create: (_) => AIService(),
        ),
        ChangeNotifierProvider<User>(
          create: (_) => User(
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
          create: (_) => CharacterProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Questy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainScreen(),
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
