import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../models/enums/habit_type.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HabitType? _selectedFilter; // null means show all

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

    // Apply filter
    final filteredHabits = _selectedFilter == null
        ? historicalHabits
        : historicalHabits.where((h) => h.habitType == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<HabitType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (HabitType? result) {
              setState(() {
                _selectedFilter = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<HabitType?>>[
              const PopupMenuItem<HabitType?>(
                value: null,
                child: Text('Show All'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<HabitType?>(
                value: HabitType.goal,
                child: Text('Goals Only'),
              ),
              const PopupMenuItem<HabitType?>(
                value: HabitType.habit,
                child: Text('Habits Only'),
              ),
            ],
          ),
        ],
      ),
      body: filteredHabits.isEmpty
          ? const Center(child: Text('No historical items found.'))
          : ListView.builder(
              itemCount: filteredHabits.length,
              itemBuilder: (context, index) {
                final habit = filteredHabits[index];
                // Determine status text
                String status = '';
                if (!habit.isActive) {
                  status = '(Ended ${habit.endDate?.toLocal().toString().split(' ')[0] ?? 'N/A'})';
                } else if (habit.habitType == HabitType.goal && habit.areAllTasksCompleted) {
                    status = '(Completed)';
                }

                return ListTile(
                  title: Text('${habit.concisePromptTitle} ${habit.habitType == HabitType.goal ? '[Goal]' : '[Habit]'}'),
                  subtitle: Text('Originally Added: ${habit.createdAt.toLocal().toString().split(' ')[0]}\n$status'),
                  isThreeLine: status.isNotEmpty,
                  // TODO: Add onTap to view details? (Original prompt, tasks etc.)
                  // onTap: () => _showHistoryDetail(context, habit),
                );
              },
            ),
    );
  }
} 