import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../models/enums/habit_type.dart';
import '../theme/app_theme.dart';
import '../models/habit_task.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    // Get all habits, then filter for inactive/completed ones
    // A habit is considered historical if it's inactive OR if it's a goal and all its tasks are completed
    final historicalHabits = habitProvider.habits.where((habit) {
      bool isHistorical = !habit.isActive; // Inactive habits are historical
      if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
        isHistorical = true; // Completed goals are historical
      }
      return isHistorical;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text(
          'History',
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
      ),
      body: Container(
        color: AppTheme.darkBackground,
        child: historicalHabits.isEmpty
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
                itemCount: historicalHabits.length,
                itemBuilder: (context, index) {
                  final habit = historicalHabits[index];
                  // Determine status text
                  String status = '';
                  if (!habit.isActive) {
                    status = '(Ended ${habit.endDate?.toLocal().toString().split(' ')[0] ?? 'N/A'})';
                  } else if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
                      status = '(Completed)';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
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
                      child: ExpansionTile(
                        collapsedBackgroundColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        title: Text(
                          habit.concisePromptTitle,
                          style: AppTheme.pixelBodyStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${habit.habitType == HabitType.goal ? "Goal" : "Habit"} $status',
                              style: AppTheme.pixelBodyStyle.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Added: ${habit.createdAt.toLocal().toString().split(' ')[0]}',
                              style: AppTheme.pixelBodyStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tasks:',
                                  style: AppTheme.pixelBodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...habit.tasks.map((task) => _buildTaskItem(task)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                    '+${task.pointsAwarded} pts',
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
        ],
      ),
    );
  }
} 