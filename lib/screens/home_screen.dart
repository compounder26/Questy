import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../models/user.dart';
import '../models/reward.dart';
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
import '../models/enums/habit_type.dart';
import '../models/enums/recurrence.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

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
  final PageController _pageController = PageController(viewportFraction: 0.8);
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<User>(
              builder: (context, user, child) {
                return Column(
                  children: [
                    Text(
                      'Level ${user.level}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${user.points} Points',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to determine color based on habit properties
  Color _getHabitColor(Habit habit) {
    if (habit.habitType == HabitType.goal) {
      return Colors.blue[100] ?? Colors.blue; // Color for Goals
    }
    // It's a habit
    if (habit.endDate != null) {
      // Time-limited habit
      return Colors.orange[100] ?? Colors.orange; // Color for Time-Limited Habits
    }
    // Permanent habit
    switch (habit.recurrence) {
      case Recurrence.daily:
        return Colors.green[100] ?? Colors.green; // Color for Daily Habits
      case Recurrence.weekly:
        return Colors.purple[100] ?? Colors.purple; // Color for Weekly Habits
      case Recurrence.none: // Should ideally not happen for type=habit, but handle anyway
      default:
        return Colors.grey[200] ?? Colors.grey; // Default/fallback color
    }
  }

  Widget _buildHabitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<HabitProvider>(
          builder: (context, habitProvider, child) {
            // Filter for active habits/goals first
            final activeHabits = habitProvider.habits.where((h) => h.isActive).toList();

            // Create a list of items to display (can mix Habits and Tasks later)
            // For now, let's group by habit

            if (activeHabits.isEmpty) {
              return const Center(child: Text('No active goals or habits. Tap + to add one!'));
            }

            // Use ListView.separated for better visual grouping by habit
            return ListView.separated(
              itemCount: activeHabits.length,
              separatorBuilder: (context, index) => const Divider(height: 20, thickness: 1),
              itemBuilder: (context, index) {
                final habit = activeHabits[index];
                final color = _getHabitColor(habit);

                return Container(
                  color: color, // Apply color coding to the habit section
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row( // Wrap title and menu button in a Row
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded( // Allow title to take available space
                            child: Text(
                              habit.concisePromptTitle, // Display the AI-generated title
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // Prevent overflow
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String result) {
                              switch (result) {
                                case 'delete':
                                  _confirmAndDeleteHabit(context, habit); // Call delete confirmation
                                  break;
                                // Add other options here if needed
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'Options',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Add details based on type/recurrence
                      if (habit.habitType == HabitType.habit)
                        Text(
                          'Type: ${habit.recurrence.toString().split('.').last.capitalize()} Habit ${habit.endDate == null ? "(Permanent)" : "(Ends ${habit.endDate!.toLocal().toString().split(' ')[0]})"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else // It's a Goal
                         Text(
                           'Type: Goal ${habit.areAllTasksCompleted ? "(Completed)" : "(In Progress)"}',
                            style: Theme.of(context).textTheme.bodySmall,
                         ),

                      // Display weekly progress if applicable
                      if (habit.recurrence == Recurrence.weekly && habit.weeklyTarget != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 4.0),
                           child: Text(
                            'Weekly Progress: ${habit.weeklyProgress} / ${habit.weeklyTarget}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                          ),
                         ),

                      const SizedBox(height: 8),
                      // List the tasks for this habit
                      if (habit.tasks.isEmpty)
                        const Text('  - No specific tasks defined.')
                      else
                        ...habit.tasks.map((task) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                                task.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                                color: task.isCompleted ? Colors.green : null,
                                size: 20,
                            ),
                            title: Text(task.description),
                            subtitle: Text('${task.difficulty} - ${task.estimatedTimeMinutes} min'),
                            trailing: task.isCompleted
                              ? null // No action if already completed
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline, size: 20), // Smaller check icon
                                  tooltip: 'Mark as complete',
                                  onPressed: () => _verifyTaskCompletion(task, habit),
                                ),
                            onTap: task.isCompleted 
                              ? null // No action if already completed
                              : () => _verifyTaskCompletion(task, habit),
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRewardsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<User>(
          builder: (context, user, child) {
            final available = Reward.availableRewards;
            final owned = user.ownedRewards;
            final ownedIds = user.ownedRewardIds;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Shop',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Your Points: ${user.points}'),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final reward = available[index];
                      final bool isOwned = ownedIds.contains(reward.id);
                      final bool canAfford = user.points >= reward.cost;

                      return ListTile(
                        title: Text(reward.name),
                        subtitle: Text('${reward.description}\nCost: ${reward.cost} points'),
                        isThreeLine: true,
                        trailing: isOwned
                            ? const Icon(Icons.check, color: Colors.green)
                            : ElevatedButton(
                                onPressed: canAfford
                                    ? () {
                                        bool success = user.purchaseReward(reward);
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${reward.name} purchased!')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Purchase failed.')),
                                          );
                                        }
                                      }
                                    : null,
                                child: const Text('Buy'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
    XFile? imageXFile; // Store the selected image file (XFile from image_picker)

    // Change showDialog result type
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        // Use StatefulBuilder to manage image selection state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Verify Task Completion'),
              content: SingleChildScrollView( // Ensure content is scrollable if it overflows
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text left
                  children: [
                    Text('Task: ${task.description}'),
                    const SizedBox(height: 15),
                    const Text('Describe your completion (optional if uploading image):'),
                    TextField(
                      onChanged: (value) => completionDesc = value,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter description...',
                        border: OutlineInputBorder(), // Add border for clarity
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('Or provide image proof:'),
                    const SizedBox(height: 5),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image_search),
                      label: const Text('Select Image'),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Offer choice between camera and gallery
                        final source = await showDialog<ImageSource>(
                           context: context,
                           builder: (context) => AlertDialog(
                                title: const Text("Select Image Source"),
                                actions: [
                                    TextButton(
                                      child: const Text("Camera"),
                                      onPressed: () => Navigator.pop(context, ImageSource.camera),
                                    ),
                                    TextButton(
                                      child: const Text("Gallery"),
                                      onPressed: () => Navigator.pop(context, ImageSource.gallery),
                                    ),
                                ],
                           ),
                        );

                        if (source != null) {
                             final XFile? pickedFile = await picker.pickImage(source: source);
                             if (pickedFile != null) {
                               setDialogState(() { // Use setDialogState to update the dialog UI
                                 imageXFile = pickedFile;
                               });
                             }
                        }
                      },
                    ),
                    if (imageXFile != null) // Display selected image filename
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            'Selected: ${imageXFile!.name}',
                            style: Theme.of(context).textTheme.bodySmall
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, {'confirmed': false}), // Return confirmation false
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Allow submission if either description or image is provided
                    if (completionDesc.isNotEmpty || imageXFile != null) {
                       Navigator.pop(context, {
                           'confirmed': true,
                           'description': completionDesc,
                           'image': imageXFile // Pass the XFile object
                       });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Please enter a description or select an image.')),
                      );
                    }
                  },
                  child: const Text('Submit for Verification'),
                ),
              ],
            );
          }
        );
      },
    );

    // Check the result map
    if (result != null && result['confirmed'] == true) {
      // Show loading indicator?
      // You might want to add a loading indicator here while waiting for AI

      final String currentDescription = result['description'] ?? '';
      final XFile? currentImageXFile = result['image'];
      Uint8List? imageData;

      try {
          // Read image data if an image was selected
          if (currentImageXFile != null) {
             imageData = await currentImageXFile.readAsBytes();
          }

        // Call the updated AI service method
        final verificationResult = await aiService.verifyTaskCompletion(
          taskDescription: task.description,
          completionDescription: currentDescription.isEmpty ? null : currentDescription, // Pass null if empty
          imageData: imageData,
        );

        final bool isValid = verificationResult['isValid'] ?? false;
        final String? reason = verificationResult['reason'];

        if (isValid) {
          // --- Mark task complete & Award Points (Existing logic) ---
          task.isCompleted = true;
          task.lastCompletedDate = DateTime.now();

          int pointsAwarded = 0;
          switch (task.difficulty.toLowerCase()) {
            case 'easy': pointsAwarded = 10; break;
            case 'medium': pointsAwarded = 25; break;
            case 'hard': pointsAwarded = 50; break;
            default: pointsAwarded = 15;
          }
          user.addPoints(pointsAwarded);

          // --- Update Weekly Progress & Habit Last Updated (Existing logic) ---
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

          // --- Update Habit State (Existing logic) ---
          if (habitStateChanged) {
             await habitProvider.updateHabit(parentHabit);
          } else {
            await habitProvider.updateHabit(parentHabit);
          }

          // --- Show Success Message (Existing logic) ---
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Task verified! +$pointsAwarded points.')),
          );

        } else {
          // Show rejection reason from AI
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('Verification Failed: ${reason ?? "No specific reason provided."}'),
                duration: const Duration(seconds: 5), // Show longer for reading
                action: SnackBarAction( // Optional: Allow user to dismiss
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
      builder: (dialogContext) {
        bool _isLoadingInDialog = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Goal or Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingInDialog)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    TextField(
                      controller: _habitController,
                      decoration: const InputDecoration(
                        hintText: 'Describe your goal or habit...',
                      ),
                      maxLines: 3,
                    ),
                ],
              ),
              actions: _isLoadingInDialog
                  ? []
                  : [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isAddingHabit = false;
                            _habitController.clear();
                          });
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete ${habit.habitType == HabitType.goal ? "Goal" : "Habit"}?'),
          content: Text('Are you sure you want to delete "${habit.concisePromptTitle}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                 foregroundColor: Theme.of(context).colorScheme.error, // Use error color for delete button
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true
              },
            ),
          ],
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
      appBar: AppBar(
        title: const Text('Questy Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
      body: Column(
        children: [
          Expanded(
            flex: 1,
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
                backgroundAsset: 'assets/images/backgrounds/hd_background.jpg',
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddHabitDialog,
            tooltip: 'Add Goal/Habit',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _characterIsAnimating = !_characterIsAnimating;
              });
            },
            tooltip: 'Toggle Character Animation',
            child: Icon(
              _characterIsAnimating ? Icons.pause_circle_filled : Icons.play_circle_filled,
            ),
            heroTag: null,
          ),
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