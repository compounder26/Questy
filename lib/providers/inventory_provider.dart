import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/inventory_item.dart';
import '../models/reward.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];
  late Box<InventoryItem> _inventoryBox;
  bool _isInitialized = false;

  // Getter for inventory items
  List<InventoryItem> get items => [..._items];
  
  // Initialize inventory from Hive
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _inventoryBox = await Hive.openBox<InventoryItem>('inventory');
      _loadInventory();
      _isInitialized = true;
      print('Inventory provider initialized successfully with ${_items.length} items');
    } catch (e) {
      print('Error initializing inventory provider: $e');
    }
  }
  
  /// Synchronize inventory with User's owned collectibles and consumable statuses
  /// This ensures bidirectional synchronization between inventory and User model
  Future<void> syncWithUser(User user) async {
    try {
      // Ensure initialization
      await initialize();
      print('Starting inventory synchronization with user ${user.name}');
      
      // Step 1: Add any collectibles owned by the user that are not in the inventory
      for (final rewardId in user.ownedRewardIds) {
        // Find the reward in available rewards
        final reward = Reward.availableRewards.firstWhere(
          (r) => r.id == rewardId,
          orElse: () => throw Exception('Reward with ID $rewardId not found in available rewards'),
        );
        
        // Check if this reward is already in inventory
        bool alreadyInInventory = _items.any((item) => item.id == rewardId);
        
        // If not in inventory, add it
        if (!alreadyInInventory) {
          await addItem(reward, notify: false);
          print('Added missing collectible ${reward.name} to inventory during sync');
        }
      }
      
      // Step 2: Ensure User's ownedRewardIds contains all collectibles in inventory
      // This handles the case where inventory has items that aren't in ownedRewardIds
      bool userModelUpdated = false;
      
      for (final item in _items) {
        // Find if this inventory item corresponds to a collectible reward
        final matchingReward = Reward.availableRewards.where(
          (r) => r.id == item.id && r.isCollectible
        ).toList();
        
        // If it's a collectible and not in user's ownedRewardIds, add it
        if (matchingReward.isNotEmpty && !user.ownedRewardIds.contains(item.id)) {
          user.ownedRewardIds.add(item.id);
          userModelUpdated = true;
          print('Added missing collectible ${item.name} to user.ownedRewardIds during sync');
        }
      }
      
      // Step 3: Process all available rewards to ensure consumable cooldowns are properly tracked
      for (final reward in Reward.availableRewards) {
        // Skip collectibles as they're handled above
        if (reward.isCollectible) continue;
        
        // Focus on consumables with purchase limits and cooldowns
        if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
          final status = user.consumableRewardStatus[reward.id];
          
          // If we have a status for this reward, check if cooldown has expired
          if (status != null && status.cooldownStartTime != null) {
            final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: reward.purchasePeriodHours!));
            
            if (DateTime.now().isAfter(cooldownEndTime)) {
              // Cooldown expired, reset purchase count
              user.consumableRewardStatus[reward.id] = status.copyWith(
                purchaseCount: 0,
                setCooldownStartTimeToNull: true,
              );
              userModelUpdated = true;
              print('Reset expired cooldown for ${reward.name} during sync');
            }
          }
        }
      }
      
      // Step 4: Clean up any consumableRewardStatus entries for rewards that no longer exist
      final allRewardIds = Reward.availableRewards.map((r) => r.id).toSet();
      final statusesToRemove = user.consumableRewardStatus.keys.where(
        (rewardId) => !allRewardIds.contains(rewardId)
      ).toList();
      
      for (final rewardId in statusesToRemove) {
        user.consumableRewardStatus.remove(rewardId);
        userModelUpdated = true;
        print('Removed obsolete consumable status for reward ID $rewardId');
      }
      
      // Save user if changes were made
      if (userModelUpdated) {
        await UserService.saveUser(user);
        user.notifyListeners();
        print('User model updated during sync, changes saved');
      }
      
      // Notify listeners after all synchronization is complete
      notifyListeners();
      print('Inventory synchronization completed successfully');
    } catch (e) {
      print('Error synchronizing inventory with user: $e');
    }
  }
  
  // Load inventory items from Hive
  void _loadInventory() {
    _items = _inventoryBox.values.toList();
    notifyListeners();
  }
  
  // Save inventory items to Hive
  Future<void> _saveInventory() async {
    await _inventoryBox.clear();
    for (var item in _items) {
      await _inventoryBox.put(item.id, item);
    }
  }

  // Add item to inventory
  Future<void> addItem(Reward reward, {bool notify = true}) async {
    await initialize(); // Ensure initialized
    
    // Check if this item already exists in the inventory
    bool itemExists = _items.any((item) => item.id == reward.id);
    
    // If the item already exists, don't add it again
    if (itemExists) {
      print('Item ${reward.name} (ID: ${reward.id}) already exists in inventory, skipping add');
      return;
    }
    
    // Create a new inventory item using the reward's ID to ensure consistency
    final item = InventoryItem(
      id: reward.id, // Use the reward's ID instead of generating a new UUID
      name: reward.name,
      description: reward.description,
      iconAsset: reward.iconAsset,
      type: reward.type,
      effectData: reward.effectData,
      purchaseDate: DateTime.now(),
    );
    
    _items.add(item);
    await _saveInventory();
    print('Added item ${reward.name} (ID: ${reward.id}) to inventory');
    
    if (notify) {
      notifyListeners();
    }
  }

  // Remove item from inventory
  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveInventory();
    notifyListeners();
  }

  // Check if inventory has an item by name
  bool hasItemByName(String name) {
    return _items.any((item) => item.name == name);
  }

  // Get items by type
  List<InventoryItem> getItemsByType(String type) {
    return _items.where((item) => item.type == type).toList();
  }
}
