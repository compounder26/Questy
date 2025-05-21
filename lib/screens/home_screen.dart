import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/user.dart';
import '../models/reward.dart';
import '../models/attribute_stats.dart';
import '../services/ai_service.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../providers/habit_provider.dart';
import '../providers/character_provider.dart';
import '../widgets/character_display.dart';
import 'package:uuid/uuid.dart';
import './character_customization_screen.dart';
import 'package:questy/models/enums/habit_type.dart';
import 'package:questy/models/enums/recurrence.dart';
import './history_screen.dart';
import '../models/habit_task.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_checkbox.dart';
import '../widgets/attribute_stats_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _carouselItems = [];
  bool _isAddingHabit = false;
  final TextEditingController _habitController = TextEditingController();
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '1', firstName: 'User');
  final PageController _pageController = PageController(viewportFraction: 1.0);
  bool _characterIsAnimating = false;  

  @override
  void initState() {
    super.initState();
    _initializeCarouselItems();
  }

  void _initializeCarouselItems() {
    _carouselItems.addAll([
      _buildStatisticsCard(),
      _buildHabitsCard(),
      _buildRewardsCard(),
    ]);
  }

  Widget _buildStatisticsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: AppTheme.woodenFrameDecoration.copyWith(
          image: const DecorationImage(
            image: AssetImage(AppTheme.woodBackgroundPath),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Consumer<User>(
          builder: (context, user, child) {
            final stats = user.attributeStats;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level and Star count in one row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Level indicator
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.brown[700],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.brown[900]!, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Level ${user.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Star count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user.starCurrency}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PixelFont',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/Items/star.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.star, color: Colors.amber, size: 20);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Experience bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${user.exp}/${user.getExpNeededForNextLevel()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                
                // EXP Progress bar
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Filled portion
                    FractionallySizedBox(
                      widthFactor: user.getLevelProgress().clamp(0.0, 1.0),
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.amber.shade300,
                              Colors.amber.shade600,
                            ],
                          ),
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Health attribute
                _buildAttributeRow('H', 'Health', stats.health, stats.healthLevel, Colors.red.shade600),
                
                // Intelligence attribute
                _buildAttributeRow('I', 'Intelligence', stats.intelligence, stats.intelligenceLevel, Colors.blue.shade600),
                
                // Cleanliness attribute
                _buildAttributeRow('C', 'Cleanliness', stats.cleanliness, stats.cleanlinessLevel, Colors.yellow.shade600),
                
                // Charisma attribute
                _buildAttributeRow('C', 'Charisma', stats.charisma, stats.charismaLevel, Colors.cyan.shade600),
                
                // Unity attribute
                _buildAttributeRow('U', 'Unity', stats.unity, stats.unityLevel, Colors.green.shade600),
                
                // Power attribute
                _buildAttributeRow('P', 'Power', stats.power, stats.powerLevel, Colors.purple.shade600),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildAttributeRow(String shortName, String fullName, double value, AttributeLevel level, Color color) {
    // Calculate percentage filled (max value for display purposes is 60)
    final double percentage = (value / 60.0).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Attribute initial in box
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  border: Border.all(color: Colors.brown[900]!, width: 1),
                ),
                child: Text(
                  shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              
              // Level text
              Text(
                level.displayName,
                style: TextStyle(
                  color: _getLevelColor(level),
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Spacer(),
              
              // Value display
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          
          // Progress bar
          Stack(
            children: [
              // Background
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
              
              // Filled portion
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Get color based on attribute level
  Color _getLevelColor(AttributeLevel level) {
    switch (level) {
      case AttributeLevel.novice:
        return Colors.grey[400]!;
      case AttributeLevel.apprentice:
        return Colors.green[400]!;
      case AttributeLevel.adept:
        return Colors.blue[400]!;
      case AttributeLevel.expert:
        return Colors.purple[400]!;
      case AttributeLevel.master:
        return Colors.orange[400]!;
      case AttributeLevel.sage:
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!; // Default case to satisfy non-nullable return type
    }
  }

  // Helper function to determine color based on habit properties
  Color _getHabitColor(Habit habit) {
    if (habit.habitType == HabitType.goal) {
      return AppTheme.blueHighlight.withOpacity(0.2); // Color for Goals
    }
    // It's a habit
    if (habit.endDate != null) {
      // Time-limited habit
      return AppTheme.redHighlight.withOpacity(0.2); // Color for Time-Limited Habits
    }
    // Permanent habit
    switch (habit.recurrence) {
      case Recurrence.daily:
        return AppTheme.greenHighlight.withOpacity(0.2); // Color for Daily Habits
      case Recurrence.weekly:
        return Colors.purple.withOpacity(0.2); // Color for Weekly Habits
      case Recurrence.none: // Should ideally not happen for type=habit, but handle anyway
      default:
        return Colors.grey[200] ?? Colors.grey; // Default/fallback color
    }
  }

  Widget _buildHabitsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: AppTheme.woodenFrameDecoration.copyWith(
          image: const DecorationImage(
            image: AssetImage(AppTheme.woodBackgroundPath),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Center(
                child: Text(
                  'TASKS & GOALS',
                  style: AppTheme.pixelHeadingStyle,
                ),
              ),
            ),
            Expanded(
              child: Consumer<HabitProvider>(
                builder: (context, habitProvider, child) {
                  // Filter for active habits/goals that are not completed
                  final activeHabits = habitProvider.habits.where((h) {
                    // Only show active habits
                    if (!h.isActive) return false;
                    
                    // For goals, don't show completed ones
                    if (h.habitType == HabitType.goal && h.areAllTasksCompleted) {
                      return false;
                    }
                    
                    return true;
                  }).toList();

                  if (activeHabits.isEmpty) {
                    return Center(
                      child: Text(
                        'No active goals or habits.\nTap + to add one!',
                        style: AppTheme.pixelBodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // Use ListView.separated for better visual grouping by habit
                  return ListView.separated(
                    // Add padding to the ListView for extra space at the bottom
                    padding: const EdgeInsets.only(bottom: 15.0),
                    itemCount: activeHabits.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final habit = activeHabits[index];
                      // final color = _getHabitColor(habit); // Color might be handled differently now

                      // Using a simpler Container for habit items, or a differently styled PixelCard
                      return Card( // Using Material Card for a modern feel
                        elevation: 2.0, // Subtle shadow
                        margin: const EdgeInsets.only(bottom: 12.0),
                        color: AppTheme.darkSurface.withOpacity(0.7), // Dark card that works with wooden bg
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      habit.concisePromptTitle,
                                      style: AppTheme.pixelBodyStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String result) {
                                      switch (result) {
                                        case 'delete':
                                          _confirmAndDeleteHabit(context, habit);
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    tooltip: 'Options',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Add details based on type/recurrence
                              if (habit.habitType == HabitType.habit)
                                Text(
                                  'Type: ${habit.recurrence.toString().split('.').last.capitalize()} Habit ${habit.endDate == null ? "(Permanent)" : "(Ends ${habit.endDate!.toLocal().toString().split(' ')[0]})"}',
                                  style: AppTheme.pixelBodyStyle.copyWith(fontSize: 12),
                                )
                              else
                                Text(
                                  'Type: Goal ${habit.areAllTasksCompleted ? "(Completed)" : "(In Progress)"}',
                                  style: AppTheme.pixelBodyStyle.copyWith(fontSize: 12),
                                ),

                              // Display weekly progress if applicable
                              if (habit.recurrence == Recurrence.weekly && habit.weeklyTarget != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Weekly Progress: ${habit.weeklyProgress} / ${habit.weeklyTarget}',
                                    style: AppTheme.pixelBodyStyle.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),
                              // List the tasks for this habit
                              if (habit.tasks.isEmpty)
                                const Text(
                                  '  - No specific tasks defined.',
                                  style: AppTheme.pixelBodyStyle,
                                )
                              else
                                ...habit.tasks.map((task) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: InkWell(
                                      onTap: task.isCompleted ? null : () => _verifyTaskCompletion(task, habit),
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          PixelCheckbox(
                                            value: task.isCompleted,
                                            onChanged: task.isCompleted
                                                ? null
                                                : (_) => _verifyTaskCompletion(task, habit),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task.description,
                                                  style: AppTheme.pixelBodyStyle.copyWith(
                                                    decoration: task.isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                Text(
                                                  '${task.difficulty} - ${task.estimatedTimeMinutes} min',
                                                  style: AppTheme.pixelBodyStyle.copyWith(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: AppTheme.woodenFrameDecoration.copyWith(
          image: const DecorationImage(
            image: AssetImage(AppTheme.woodBackgroundPath),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'REWARD SHOP',
                style: AppTheme.pixelHeadingStyle,
              ),
            ),
            Consumer<User>(
              builder: (context, user, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  child: Center(
                    child: Text(
                      'Your Stars: ${user.starCurrency}',
                      style: AppTheme.pixelBodyStyle.copyWith(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Consumer<User>(
                builder: (context, user, child) {
                  final available = Reward.availableRewards;
                  final ownedIds = user.ownedRewardIds;

                  if (available.isEmpty) {
                    return Center(
                      child: Text(
                        'No rewards available in the shop yet!',
                        style: AppTheme.pixelBodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final reward = available[index];
                      final bool isOwned = ownedIds.contains(reward.id);
                      final bool canAfford = user.starCurrency >= reward.cost;

                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        color: AppTheme.darkSurface.withOpacity(0.7), // Dark card that works with wooden bg
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      reward.name,
                                      style: AppTheme.pixelBodyStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reward.description,
                                      style: AppTheme.pixelBodyStyle.copyWith(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                                    ),
                                    const SizedBox(height: 8),
                                    if (isOwned)
                                      Text(
                                        'OWNED',
                                        style: AppTheme.pixelBodyStyle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.greenHighlight,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Cost: ${reward.cost} stars',
                                        style: AppTheme.pixelBodyStyle.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: canAfford ? Colors.yellowAccent : Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: PixelButton(
                                  onPressed: isOwned ? null : (canAfford ? () {
                                    bool success = user.purchaseReward(reward);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.greenHighlight,
                                          content: Text('${reward.name} purchased!', style: AppTheme.pixelBodyStyle)
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.redHighlight,
                                          content: Text('Purchase failed. Not enough stars or already owned.', style: AppTheme.pixelBodyStyle)
                                        ),
                                      );
                                    }
                                  } : null),
                                  backgroundColor: isOwned ? Colors.grey.withOpacity(0.3) : (canAfford ? AppTheme.darkWood : Colors.grey.withOpacity(0.5)),
                                  padding: EdgeInsets.zero,
                                  child: isOwned 
                                      ? Center(child: Icon(Icons.check_circle, color: AppTheme.greenHighlight, size: 30)) 
                                      : (canAfford 
                                          ? Image.asset('assets/images/Items/diamond.png', fit: BoxFit.contain)
                                          : Center(child: Icon(Icons.lock_outline, color: Colors.white70, size: 30))
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyTaskCompletion(HabitTask task, Habit parentHabit) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final user = context.read<User>();
    final habitProvider = context.read<HabitProvider>();
    final aiService = context.read<AIService>();
    String completionDesc = '';
    XFile? imageXFile;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                    minWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage(AppTheme.woodBackgroundPath),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkWood,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Verify Task Completion',
                        style: AppTheme.pixelHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.darkWood,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Task: ${task.description}',
                          style: AppTheme.pixelBodyStyle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Describe your completion:',
                        style: AppTheme.pixelBodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.darkWood,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) => completionDesc = value,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter description...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Or provide image proof:',
                        style: AppTheme.pixelBodyStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: PixelButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final source = await showDialog<ImageSource>(
                              context: context,
                              useSafeArea: true,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                child: SingleChildScrollView(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.7,
                                    margin: const EdgeInsets.only(bottom: 40),
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage(AppTheme.woodBackgroundPath),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.darkWood,
                                        width: 3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Select Image Source',
                                          style: AppTheme.pixelHeadingStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            PixelButton(
                                              width: 105,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              onPressed: () => Navigator.pop(context, ImageSource.camera),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Camera'),
                                                ],
                                              ),
                                            ),
                                            PixelButton(
                                              width: 105,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              onPressed: () => Navigator.pop(context, ImageSource.gallery),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.photo_library, color: Colors.white, size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Gallery'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );

                            if (source != null) {
                              final XFile? pickedFile = await picker.pickImage(source: source);
                              if (pickedFile != null) {
                                setDialogState(() {
                                  imageXFile = pickedFile;
                                });
                              }
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_search, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Select Image'),
                            ],
                          ),
                        ),
                      ),
                      if (imageXFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Selected: ${imageXFile!.name}',
                            style: AppTheme.pixelBodyStyle.copyWith(
                              color: AppTheme.greenHighlight,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            PixelButton(
                              width: 110,
                              backgroundColor: AppTheme.redHighlight,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              onPressed: () => Navigator.pop(context, {'confirmed': false}),
                              child: const Text('Cancel'),
                            ),
                            PixelButton(
                              width: 110,
                              backgroundColor: AppTheme.greenHighlight,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              onPressed: () {
                                if (completionDesc.isNotEmpty || imageXFile != null) {
                                  Navigator.pop(context, {
                                    'confirmed': true,
                                    'description': completionDesc,
                                    'image': imageXFile
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a description or select an image.')),
                                  );
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Handle the result - keep the rest of the method unchanged
    if (result != null && result['confirmed'] == true) {
      final String currentDescription = result['description'] ?? '';
      final XFile? currentImageXFile = result['image'];
      Uint8List? imageData;

      try {
        if (currentImageXFile != null) {
          imageData = await currentImageXFile.readAsBytes();
        }

        final verificationResult = await aiService.verifyTaskCompletion(
          taskDescription: task.description,
          completionDescription: currentDescription.isEmpty ? null : currentDescription,
          imageData: imageData,
        );

        final bool isValid = verificationResult['isValid'] ?? false;
        final String? reason = verificationResult['reason'];
        final String? suggestedAttribute = verificationResult['suggestedAttribute'];

        if (isValid) {
          // Mark task complete & Award Stars and EXP
          task.isCompleted = true;
          task.lastCompletedDate = DateTime.now();
          
          // Award stars and EXP based on difficulty
          int starsAwarded = 0;
          int expAwarded = 0;
          
          switch (task.difficulty.toLowerCase()) {
            case 'easy': 
              starsAwarded = 10; 
              expAwarded = 5;
              break;
            case 'medium': 
              starsAwarded = 25;
              expAwarded = 10;
              break;
            case 'hard': 
              starsAwarded = 50;
              expAwarded = 20;
              break;
            default: 
              starsAwarded = 15;
              expAwarded = 8;
          }
          
          // Store stars awarded in the task
          task.pointsAwarded = starsAwarded;
          user.addStarCurrency(starsAwarded);
          user.addExp(expAwarded);
          
          // Increase the appropriate attribute based on the AI suggestion or fallback to task analysis
          if (suggestedAttribute != null) {
            // Use the AI's suggested attribute
            user.increaseAttribute(suggestedAttribute.toLowerCase(), task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                                   task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
          } else {
            // Fallback to analyzing the task content
            if (parentHabit.habitType == HabitType.goal) {
              // Goals typically increase Intelligence
              user.increaseAttribute('intelligence', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                   task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
            } else {
              // Regular habits increase based on their tags or name (simplified example)
              final String habitDescription = parentHabit.description.toLowerCase();
              if (habitDescription.contains('exercise') || habitDescription.contains('workout') || habitDescription.contains('gym')) {
                user.increaseAttribute('power', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                 task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else if (habitDescription.contains('read') || habitDescription.contains('study') || habitDescription.contains('learn')) {
                user.increaseAttribute('intelligence', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                     task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else if (habitDescription.contains('clean') || habitDescription.contains('tidy') || habitDescription.contains('organize')) {
                user.increaseAttribute('cleanliness', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                    task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else if (habitDescription.contains('meditate') || habitDescription.contains('reflect') || habitDescription.contains('journal')) {
                user.increaseAttribute('unity', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                              task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else if (habitDescription.contains('socialize') || habitDescription.contains('talk') || habitDescription.contains('friend')) {
                user.increaseAttribute('charisma', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                                task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else if (habitDescription.contains('health') || habitDescription.contains('sleep') || habitDescription.contains('eat')) {
                user.increaseAttribute('health', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                              task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              } else {
                // Default to increasing unity if no specific match
                user.increaseAttribute('unity', task.difficulty.toLowerCase() == 'easy' ? 0.5 : 
                                              task.difficulty.toLowerCase() == 'medium' ? 1.0 : 2.0);
              }
            }
          }

          // Update Weekly Progress & Habit Last Updated
          bool habitStateChanged = false;
          if (parentHabit.recurrence == Recurrence.weekly && parentHabit.weeklyTarget != null) {
            if (!parentHabit.isWeeklyGoalMet) {
              parentHabit.weeklyProgress++;
              habitStateChanged = true;
            } else {
              print("Weekly goal already met for: ${parentHabit.concisePromptTitle}");
            }
          }
          parentHabit.lastUpdated = DateTime.now();
          habitStateChanged = true;

          // Update Habit State
          if (habitStateChanged) {
            await habitProvider.updateHabit(parentHabit);
          } else {
            await habitProvider.updateHabit(parentHabit);
          }

          // Show Success Message
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Task verified! +$starsAwarded stars and +$expAwarded EXP.')),
          );
        } else {
          // Show rejection reason from AI
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Verification Failed: ${reason ?? "No specific reason provided."}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () { scaffoldMessenger.hideCurrentSnackBar(); },
              ),
            ),
          );
        }
      } catch (e) {
        print("Error verifying task: $e");
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Error verifying task. Please try again.')),
        );
      }
    }
  }

  void _showAddHabitDialog() {
    setState(() {
      _isAddingHabit = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (dialogContext) {
        bool _isLoadingInDialog = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                    minWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage(AppTheme.woodBackgroundPath),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkWood,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'New Goal or Habit',
                        style: AppTheme.pixelHeadingStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_isLoadingInDialog)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Creating your goal/habit...',
                              style: AppTheme.pixelBodyStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.darkWood,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _habitController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Describe your goal or habit...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              contentPadding: const EdgeInsets.all(12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (!_isLoadingInDialog)
                        Container(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              PixelButton(
                                width: 120,
                                backgroundColor: AppTheme.redHighlight,
                                onPressed: () {
                                  setState(() {
                                    _isAddingHabit = false;
                                    _habitController.clear();
                                  });
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Cancel'),
                              ),
                              PixelButton(
                                width: 120,
                                backgroundColor: AppTheme.greenHighlight,
                                onPressed: () async {
                                  final originalDescription = _habitController.text;
                                  if (originalDescription.isNotEmpty) {
                                    setDialogState(() {
                                      _isLoadingInDialog = true;
                                    });

                                    final aiService = context.read<AIService>();
                                    final habitProvider = context.read<HabitProvider>();
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    const uuid = Uuid();

                                    try {
                                      final habitData = await aiService.breakDownHabit(originalDescription);

                                      if (habitData != null) {
                                        final String conciseTitle = habitData['concisePromptTitle'] ?? originalDescription;
                                        final String habitTypeString = habitData['habitType'] ?? 'goal';
                                        final String recurrenceString = habitData['recurrence'] ?? 'none';
                                        final String? endDateString = habitData['endDate'];
                                        final int? weeklyTarget = habitData['weeklyTarget'];
                                        final List<dynamic> tasksData = habitData['tasks'] ?? [];

                                        final HabitType habitType = HabitType.values.firstWhere(
                                          (e) => e.toString() == 'HabitType.$habitTypeString',
                                          orElse: () => HabitType.goal
                                        );
                                        final Recurrence recurrence = Recurrence.values.firstWhere(
                                          (e) => e.toString() == 'Recurrence.$recurrenceString',
                                          orElse: () => Recurrence.none
                                        );
                                        final DateTime? endDate = endDateString != null ? DateTime.tryParse(endDateString) : null;

                                        final List<HabitTask> habitTasks = tasksData.map((taskMap) {
                                          if (taskMap is Map<String, dynamic>) {
                                              int estimatedMinutes = 0;
                                              if (taskMap['estimatedTime'] is int) {
                                                estimatedMinutes = taskMap['estimatedTime'];
                                              } else if (taskMap['estimatedTime'] is String) {
                                                estimatedMinutes = int.tryParse(taskMap['estimatedTime'].toString()) ?? 0;
                                              }

                                              return HabitTask(
                                                id: uuid.v4(),
                                                description: taskMap['task']?.toString() ?? 'Unnamed Task',
                                                difficulty: taskMap['difficulty']?.toString() ?? 'Medium',
                                                estimatedTimeMinutes: estimatedMinutes,
                                              );
                                          } else {
                                            print("Skipping invalid task data: $taskMap");
                                            return null;
                                          }
                                        }).whereType<HabitTask>().toList();

                                        final newHabit = Habit(
                                          id: uuid.v4(),
                                          description: originalDescription,
                                          concisePromptTitle: conciseTitle,
                                          tasks: habitTasks,
                                          createdAt: DateTime.now(),
                                          habitType: habitType,
                                          recurrence: recurrence,
                                          endDate: endDate,
                                          weeklyTarget: weeklyTarget,
                                        );

                                        await habitProvider.addHabit(newHabit);
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                      } else {
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not break down goal/habit. AI service might be unavailable. Please try again.')),
                                          );
                                        }
                                      }
                                    } catch (e, stacktrace) {
                                      print("Error during habit creation: $e");
                                      print("Stacktrace: $stacktrace");
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('An error occurred while creating the goal/habit. Please try again.')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setDialogState(() {
                                          _isLoadingInDialog = false;
                                        });
                                        setState(() {
                                          _isAddingHabit = false;
                                          _habitController.clear();
                                        });
                                      } else {
                                        _isAddingHabit = false;
                                        _habitController.clear();
                                      }
                                    }
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Confirmation Dialog for Deleting Habit/Goal
  Future<void> _confirmAndDeleteHabit(BuildContext context, Habit habit) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                minWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage(AppTheme.woodBackgroundPath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.darkWood,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Delete ${habit.habitType == HabitType.goal ? "Goal" : "Habit"}?',
                    style: AppTheme.pixelHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete "${habit.concisePromptTitle}"?\nThis action cannot be undone.',
                    style: AppTheme.pixelBodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      PixelButton(
                        width: 120,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      PixelButton(
                        width: 120,
                        backgroundColor: AppTheme.redHighlight,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await habitProvider.removeHabit(habit.id);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${habit.concisePromptTitle}" deleted.')),
            );
        }
      } catch (e) {
         print("Error deleting habit: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting ${habit.habitType == HabitType.goal ? "goal" : "habit"}. Please try again.')),
            );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Questy Home',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            children: [
              Expanded(
                flex: 0, 
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CharacterCustomizationScreen(),
                      ),
                    );
                  },
                  child: CharacterDisplay(
                    character: characterProvider.character,
                    animate: _characterIsAnimating,
                    background: characterProvider.selectedBackground,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: PageView(
                  controller: _pageController,
                  children: _carouselItems,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PixelButton(
            width: 60,
            height: 60,
            padding: EdgeInsets.zero,
            onPressed: _showAddHabitDialog,
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 12),
          PixelButton(
            width: 60,
            height: 60,
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _characterIsAnimating = !_characterIsAnimating;
              });
            },
            child: Icon(
              _characterIsAnimating ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Add String extension for capitalization
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
} 