import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/habit_provider.dart'; // Needed for habit deletion
import '../models/inventory_item.dart';
import '../models/enums/habit_type.dart'; // Import for HabitType enum
import '../models/habit.dart'; // Add import for Habit model
import '../theme/app_theme.dart';
import '../widgets/pixel_button.dart';
import '../utils/string_extensions.dart'; // Add import for string extensions

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/appLogo.jpg',
                height: 32,
                width: 32,
              ),
            ),
            const Text(
              'Inventory',
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
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventoryProvider, child) {
          final items = inventoryProvider.items;
          
          if (items.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.woodenFrameDecoration.copyWith(
                  image: const DecorationImage(
                    image: AssetImage(AppTheme.woodBackgroundPath),
                    fit: BoxFit.cover,
                    opacity: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Your inventory is empty.\nPurchase collectible items from the Reward Shop!',
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelBodyStyle.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: AppTheme.woodenFrameDecoration.copyWith(
                image: const DecorationImage(
                  image: AssetImage(AppTheme.woodBackgroundPath),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR ITEMS',
                    style: AppTheme.pixelHeadingStyle.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildInventoryItem(context, item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInventoryItem(BuildContext context, InventoryItem item) {
    // Determine if this is a consumable item that can be used
    final bool isConsumable = item.type != null && !item.type!.contains('collectible');
    final bool isTaskEraser = item.type == 'task_eraser';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.brown.shade800,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item Icon with enhanced decoration
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.brown.shade900, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: item.iconAsset != null
                    ? Image.asset(
                        item.iconAsset!,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.inventory_2,
                          color: Colors.white70,
                          size: 34,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        color: Colors.white70,
                        size: 34,
                      ),
              ),
              const SizedBox(width: 16),
              // Item Name with fancy style
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.pixelHeadingStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'COLLECTIBLE',
                        style: AppTheme.pixelBodyStyle.copyWith(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Item Description with enhanced style
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.brown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              item.description,
              style: AppTheme.pixelBodyStyle.copyWith(
                fontSize: 14,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Acquisition date with icon
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.amber,
              ),
              const SizedBox(width: 5),
              Text(
                'Acquired: ${_formatDate(item.purchaseDate)}',
                style: AppTheme.pixelBodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          
          // Add "Use" button for consumable items
          if (isConsumable) ...[  
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.touch_app),
              label: const Text('Use'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (isTaskEraser) {
                  _showTaskEraserDialog(context, item);
                } else {
                  // Handle other consumable types
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This item type is not yet implemented')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Show task eraser dialog to select which task/goal/habit to delete
  void _showTaskEraserDialog(BuildContext context, InventoryItem item) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    
    // Only get active habits (exclude completed habits and completed goals)
    final activeHabits = habitProvider.habits.where((h) => 
      h.isActive && // Must be active (no end date or end date hasn't passed)
      !h.areAllTasksCompleted && // Exclude completed habits
      (h.habitType == HabitType.habit || // Show habits
       (h.habitType == HabitType.goal && !h.areAllTasksCompleted)) // Show goals only if not all tasks are completed
    ).toList();

    // Create a filtered list of habits with only incomplete tasks
    final filteredHabits = activeHabits.map((habit) {
      // Create a copy of the habit with only incomplete tasks
      final incompleteTasks = habit.tasks.where((task) => 
        !task.isNonHabitTask && // Exclude non-habit tasks
        !task.isCompleted && // Exclude completed tasks
        task.difficulty.toLowerCase() != 'hard' // Exclude hard difficulty tasks
      ).toList();
      
      if (incompleteTasks.isEmpty) return null;
      
      // Return a new habit object with only incomplete tasks
      return Habit(
        id: habit.id,
        description: habit.description,
        concisePromptTitle: habit.concisePromptTitle,
        tasks: incompleteTasks,
        createdAt: habit.createdAt,
        habitType: habit.habitType,
        recurrence: habit.recurrence,
        endDate: habit.endDate,
        weeklyTarget: habit.weeklyTarget,
        weeklyProgress: habit.weeklyProgress,
        lastUpdated: habit.lastUpdated,
        cooldownDurationInMinutes: habit.cooldownDurationInMinutes,
      );
    }).whereType<Habit>().toList();
    
    if (filteredHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No incomplete habits to erase')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              minWidth: MediaQuery.of(context).size.width * 0.6,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Habit to Erase',
                  style: AppTheme.pixelHeadingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which incomplete habit to delete:',
                  style: AppTheme.pixelBodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = filteredHabits[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.brown.shade800),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.concisePromptTitle,
                                    style: AppTheme.pixelBodyStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${habit.habitType.toString().split('.').last.toUpperCase()} ${habit.recurrence.toString().split('.').last.toUpperCase()}',
                                    style: AppTheme.pixelBodyStyle.copyWith(
                                      fontSize: 12,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PixelButton(
                              width: 80,
                              height: 36,
                              backgroundColor: AppTheme.redHighlight,
                              onPressed: () async {
                                // Close the dialog
                                Navigator.of(context).pop();
                                
                                // Delete the habit
                                try {
                                  await habitProvider.removeHabit(habit.id);
                                  
                                  // Remove the item from inventory after use
                                  await inventoryProvider.removeItem(item.id);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('"${habit.concisePromptTitle}" was erased successfully!')),
                                  );
                                } catch (e) {
                                  print("Error erasing habit: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error erasing habit. Please try again.'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Erase'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                PixelButton(
                  width: 120,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
