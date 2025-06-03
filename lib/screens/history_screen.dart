import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/enums/habit_type.dart';
import '../theme/app_theme.dart';
import '../models/habit_task.dart';
import '../utils/string_extensions.dart';
import '../models/user.dart'; // Added for User and PurchaseHistoryItem
import '../models/habit.dart'; // Ensure Habit is imported for type checking
import 'package:hive/hive.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Helper to get a display date for sorting and display
  DateTime _getDisplayDateForHabit(Habit habit) {
    if (!habit.isActive && habit.endDate != null) {
      return habit.endDate!;
    }
    if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
      if (habit.tasks.isNotEmpty) {
        DateTime? latestCompletion;
        for (var task in habit.tasks) {
          if (task.isCompleted && task.lastCompletedDate != null) {
            if (latestCompletion == null || task.lastCompletedDate!.isAfter(latestCompletion)) {
              latestCompletion = task.lastCompletedDate;
            }
          }
        }
        if (latestCompletion != null) return latestCompletion;
      }
    }
    // Fallback for active habits or goals not fully completed, or if no specific date found
    // These might not typically appear in "history" unless logic changes, but good to have a fallback
    return habit.createdAt; // Corrected: Was habit.creationDate. Or DateTime(1900) if you prefer to push them to the bottom
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final user = Provider.of<User>(context); // Get User object, assumes User is provided directly
    // Get all habits, then filter for inactive/completed ones
    // Only completed goals or inactive habits are historical
    final historicalHabits = habitProvider.habits.where((habit) {
      if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
        return true;
      }
      if (habit.habitType == HabitType.habit && !habit.isActive) {
        return true;
      }
      return false;
    }).toList();

    // Load archived habits from Hive
    final archivedHabitBox = Hive.box<Habit>('archived_habits');
    final archivedHabits = archivedHabitBox.values.toList();

    // Get purchase history
    final purchaseHistory = user.purchaseHistory;

    // Combine and sort history items
    List<dynamic> combinedHistory = [];
    combinedHistory.addAll(historicalHabits);
    combinedHistory.addAll(archivedHabits);
    combinedHistory.addAll(purchaseHistory);

    combinedHistory.sort((a, b) {
      DateTime dateA, dateB;
      if (a is Habit) {
        dateA = _getDisplayDateForHabit(a);
      } else if (a is PurchaseHistoryItem) {
        dateA = a.purchaseDate;
      } else {
        return 0; // Should not happen
      }

      if (b is Habit) {
        dateB = _getDisplayDateForHabit(b);
      } else if (b is PurchaseHistoryItem) {
        dateB = b.purchaseDate;
      } else {
        return 0; // Should not happen
      }
      return dateB.compareTo(dateA); // Sort descending (most recent first)
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                AppTheme.appLogoPath, // Corrected logo path
                height: 32,
                width: 32,
              ),
            ),
            const Text('History', style: AppTheme.pixelHeadingStyle), // Corrected style
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.darkBackground,
        child: combinedHistory.isEmpty
            ? Center(
                child: Text(
                  'No historical items found.',
                  style: AppTheme.pixelBodyStyle.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: combinedHistory.length,
                itemBuilder: (context, index) {
                  final item = combinedHistory[index];
                  if (item is Habit) {
                    return _buildHistoricalHabitItem(item); 
                  } else if (item is PurchaseHistoryItem) {
                    return _buildPurchaseHistoryEntry(item);
                  }
                  return const SizedBox.shrink(); // Should not happen
                },
              ),
      ),
    );
  }
  
  Widget _buildTaskItem(HabitTask task) {
    // Get proper color for difficulty level
    Color difficultyColor;
    switch (task.difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = Colors.green;
        break;
      case 'medium':
        difficultyColor = Colors.orange;
        break;
      case 'hard':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.blue;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppTheme.darkWood, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: task.isCompleted ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.description,
                  style: AppTheme.pixelBodyStyle.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: difficultyColor),
                    ),
                    child: Text(
                      task.difficulty,
                      style: AppTheme.pixelBodyStyle.copyWith(
                        fontSize: 12,
                        color: difficultyColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${task.estimatedTimeMinutes} min',
                    style: AppTheme.pixelBodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
              if (task.isCompleted && task.pointsAwarded != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text(
                    '+${task.pointsAwarded} ✯',
                    style: AppTheme.pixelBodyStyle.copyWith(
                      fontSize: 12,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          if (task.isCompleted && task.lastCompletedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Completed: ${task.lastCompletedDate!.toLocal().toString().split(' ')[0]}',
                style: AppTheme.pixelBodyStyle.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (task.isCompleted && task.expAwarded != null && task.expAwarded! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.lightBlue),
                ),
                child: Text(
                  'EXP: +${task.expAwarded}',
                  style: AppTheme.pixelBodyStyle.copyWith(
                    fontSize: 12,
                    color: Colors.lightBlue,
                  ),
                ),
              ),
            ),
          if (task.isCompleted && task.attributesAwarded != null && task.attributesAwarded!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attributes gained:',
                    style: AppTheme.pixelBodyStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: task.getAttributeChanges().map((attr) {
                      // Get color for attribute
                      Color attrColor = _getAttributeColor(attr.name);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: attrColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: attrColor),
                        ),
                        child: Text(
                          '${attr.name.capitalize()}: +${attr.amount}',
                          style: AppTheme.pixelBodyStyle.copyWith(
                            fontSize: 12,
                            color: attrColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricalHabitItem(Habit habit) {
    String statusText = '';
    DateTime displayDate = _getDisplayDateForHabit(habit);

    if (!habit.isActive && habit.endDate != null) {
        statusText = '(Ended ${habit.endDate!.toLocal().toString().split(' ')[0]})';
    } else if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
        statusText = '(Completed ${displayDate.toLocal().toString().split(' ')[0]})';
    } else {
        // Fallback for other cases, e.g. ongoing habits if they were to be included by mistake
        statusText = '(Created ${habit.createdAt.toLocal().toString().split(' ')[0]})'; // Corrected: Was habit.creationDate
    }

    return Card(
      color: AppTheme.darkCardBackground, // Corrected theme color
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.concisePromptTitle, // Corrected field name
              style: AppTheme.pixelHeadingStyle.copyWith(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${habit.habitType.toString().split('.').last.capitalize()} ${statusText}',
              style: AppTheme.pixelBodyStyle.copyWith(color: Colors.grey[400], fontSize: 14),
            ),
            if (habit.description.isNotEmpty) ...[ // Check directly on description
              const SizedBox(height: 8),
              Text(
                habit.description, // Use description directly
                style: AppTheme.pixelBodyStyle.copyWith(color: Colors.white70, fontSize: 14),
              ),
            ],
            if (habit.habitType == HabitType.goal && habit.tasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Tasks:', style: AppTheme.pixelBodyStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              ),
              ...habit.tasks.map((task) => _buildTaskItem(task)).toList(), // Use the main _buildTaskItem method
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryEntry(PurchaseHistoryItem item) {
    return Card(
      color: AppTheme.darkCardBackground, // Corrected theme color 
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (item.iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Image.asset(
                  item.iconAsset!,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 40, color: Colors.white70),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.shopping_bag, size: 40, color: Colors.white70),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: AppTheme.pixelHeadingStyle.copyWith(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purchased: ${item.purchaseDate.toLocal().toString().split(' ')[0]}',
                    style: AppTheme.pixelBodyStyle.copyWith(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.isCollectible ? Colors.purple.withOpacity(0.7) : Colors.orange.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.isCollectible ? 'COLLECTIBLE' : 'CONSUMABLE',
                style: AppTheme.pixelBodyStyle.copyWith(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getAttributeColor(String attributeName) {
    switch (attributeName.toLowerCase()) {
      case 'health': return Colors.red;
      case 'intelligence': return Colors.blue;
      case 'cleanliness': return Colors.yellow;
      case 'charisma': return Colors.cyan;
      case 'unity': return Colors.green;
      case 'power': return Colors.purple;
      default: return Colors.grey;
    }
  }
}