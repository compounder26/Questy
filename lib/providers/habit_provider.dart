import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/enums/recurrence.dart';
import 'package:hive/hive.dart'; // Import Hive

// Helper function to check if two dates fall within the same week (assuming week starts on Monday)
bool _isSameWeek(DateTime date1, DateTime date2) {
  // Adjust dates to the start of the week (Monday)
  final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
  final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));
  // Compare the year and the day-of-year for the start of the week
  return startOfWeek1.year == startOfWeek2.year &&
         _dayOfYear(startOfWeek1) == _dayOfYear(startOfWeek2);
}

// Helper function to get day of the year
int _dayOfYear(DateTime date) {
  return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
}

// Helper function to check if two dates are on the same calendar day
bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

class HabitProvider extends ChangeNotifier {
  // Use late final for the box to ensure it's opened before use
  late final Box<Habit> _habitBox;
  List<Habit> _habits = []; // Keep the in-memory list

  HabitProvider() {
    // Initialize box reference - Box should be open already from main.dart
    _habitBox = Hive.box<Habit>('habits');
  }

  List<Habit> get habits {
    // Consider calling performResets() here every time habits are accessed,
    // or call it more strategically (e.g., on app load, background fetch).
    // Calling it here ensures data is always fresh but might have performance implications.
    // performResets(); // Example placement - choose strategy carefully
    return _habits;
  }

  // --- Persistence Methods ---
  Future<void> loadHabits() async {
    // Load habits from the box into the in-memory list
    _habits = _habitBox.values.toList();
    print("Loaded ${_habits.length} habits from Hive.");
    // Perform resets *after* loading
    performResets();
    // No need to notify listeners here usually, as this happens on init
    // unless you want UI to react immediately to loaded/reset state.
    // notifyListeners(); // Optional: depends on initial UI state needs
  }

  // Private save method
  Future<void> _saveHabits() async {
    // Hive boxes with HiveObjects might not need explicit saving for field updates
    // if the objects themselves are managed by Hive. However, adding/deleting
    // requires box operations. Let's stick to a clear put/delete pattern for now.

    // Clear the box and re-add all current habits.
    // This is simpler than tracking individual changes but potentially less efficient.
    await _habitBox.clear();
    // Use putAll for efficiency
    await _habitBox.putAll({ for (var habit in _habits) habit.id : habit });
    print("Saved ${_habits.length} habits to Hive.");

    // Alternative (more complex, potentially faster for updates): Use put/delete individually
    // for (var habit in _habits) {
    //    await _habitBox.put(habit.id, habit); // Use habit.id as key
    // }
    // Need to handle deletions separately if not clearing first.
  }

  // --- Reset Logic (Modified to save after changes) ---
  void performResets() {
    final now = DateTime.now();
    bool didChange = false;

    // Use index-based loop or create a copy if modifying HiveObjects directly during iteration
    final List<Habit> habitsToUpdate = [];
    for (int i = 0; i < _habits.length; i++) {
        var habit = _habits[i];
        bool habitUpdated = false;

        // 1. Weekly Reset Check
        if (habit.recurrence == Recurrence.weekly) {
          if (!_isSameWeek(habit.lastUpdated, now)) {
            if (habit.weeklyProgress > 0) { // Only reset if there was progress
               print("Resetting weekly progress for: ${habit.concisePromptTitle}");
               habit.weeklyProgress = 0;
               habitUpdated = true;
            }
          }
        }

        // 2. Daily Task Reset Check
        if (habit.recurrence == Recurrence.daily) {
          for (var task in habit.tasks) {
            if (task.isCompleted && task.lastCompletedDate != null) {
              if (!_isSameDay(task.lastCompletedDate!, now)) {
                print("Resetting daily task: ${task.description} for habit: ${habit.concisePromptTitle}");
                task.isCompleted = false;
                task.lastCompletedDate = null; // Clear completion date
                habitUpdated = true; // Mark habit as updated because a task changed
              }
            }
          }
        }

        if (habitUpdated) {
            habit.lastUpdated = now;
            didChange = true;
            // Since we extended HiveObject, Hive might track changes, but explicit save is safer
            // Add to list for explicit save later
             habitsToUpdate.add(habit);
        }
    }

    if (didChange) {
        print("Habit resets performed. Saving changes and notifying listeners.");
        // Save changes to Hive
        _saveHabits().then((_) {
            // Notify listeners *after* saving is complete
            notifyListeners();
        }).catchError((error) {
             print("Error saving habits after reset: $error");
             // Optionally notify listeners even if save failed?
        });
    }
  }

  // --- CRUD Methods (Modified to save) ---

  Future<void> addHabit(Habit habit) async {
    habit.lastUpdated = DateTime.now();
    _habits.add(habit); // Add to in-memory list
    await _saveHabits(); // Save the updated list to Hive
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      habit.lastUpdated = DateTime.now();
      _habits[index] = habit; // Update in-memory list
      // If using HiveObject.save(), could do: await _habits[index].save();
      await _saveHabits(); // Save the updated list to Hive
      notifyListeners();
    } else {
       print("Attempted to update non-existent habit with id: ${habit.id}");
       // Optionally add it if it doesn't exist?
       // await addHabit(habit);
    }
  }

  Future<void> removeHabit(String id) async {
    final initialLength = _habits.length;
    _habits.removeWhere((habit) => habit.id == id); // Remove from in-memory list
    if (_habits.length < initialLength) { // Check if removal happened
       await _saveHabits(); // Save the updated list to Hive
       notifyListeners();
    } else {
       print("Attempted to remove non-existent habit with id: $id");
    }
  }

  // Added for compatibility with home_screen.dart which calls deleteHabit
  Future<void> deleteHabit(String id) async {
    // Simply delegate to removeHabit for consistent implementation
    await removeHabit(id);
  }

  // TODO: Add methods for loading/saving habits from persistence
  // e.g., Future<void> loadHabits();
  // e.g., Future<void> saveHabits();
} 