import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward.dart';
import '../models/user.dart';
import '../models/user_reward_purchase_status.dart';

/// A dedicated class solely responsible for reward persistence
/// This centralizes all reward state persistence logic in one place
class RewardPersistence {
  static const String _ownedRewardsKey = 'owned_rewards';
  static const String _purchaseHistoryKey = 'purchase_history';
  static const String _consumableStatusKey = 'consumable_status';

  /// Save all reward-related state in one atomic operation
  static Future<bool> saveAll(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Save owned collectibles
      final ownedJson = json.encode(user.ownedRewardIds);
      await prefs.setString(_ownedRewardsKey, ownedJson);
      
      // 2. Save purchase history
      final historyJson = json.encode(
        user.purchaseHistory.map((item) => item.toJson()).toList()
      );
      await prefs.setString(_purchaseHistoryKey, historyJson);
      
      // 3. Save consumable statuses
      final Map<String, dynamic> statusMap = {};
      user.consumableRewardStatus.forEach((key, status) {
        statusMap[key] = status.toJson();
      });
      final statusJson = json.encode(statusMap);
      await prefs.setString(_consumableStatusKey, statusJson);
      
      print('REWARD PERSISTENCE: Successfully saved all reward state');
      return true;
    } catch (e) {
      print('REWARD PERSISTENCE ERROR: Failed to save reward state: $e');
      return false;
    }
  }

  /// Load all reward-related state in one atomic operation
  static Future<bool> loadAll(User user) async {
    try {
      print('REWARD PERSISTENCE: Starting load process');
      final prefs = await SharedPreferences.getInstance();
      bool dataLoaded = false;
      
      // 1. Load owned collectibles
      final ownedJson = prefs.getString(_ownedRewardsKey);
      if (ownedJson != null) {
        final List<dynamic> ownedList = json.decode(ownedJson);
        user.ownedRewardIds.clear();
        user.ownedRewardIds.addAll(ownedList.cast<String>());
        print('REWARD PERSISTENCE: Loaded ${user.ownedRewardIds.length} owned rewards');
        dataLoaded = true;
      }
      
      // 2. Load purchase history
      final historyJson = prefs.getString(_purchaseHistoryKey);
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        user.purchaseHistory.clear();
        user.purchaseHistory.addAll(
          historyList.map((item) => PurchaseHistoryItem.fromJson(item)).toList()
        );
        print('REWARD PERSISTENCE: Loaded ${user.purchaseHistory.length} purchase history items');
        dataLoaded = true;
      }
      
      // 3. Load consumable statuses
      final statusJson = prefs.getString(_consumableStatusKey);
      if (statusJson != null) {
        final Map<String, dynamic> statusMap = json.decode(statusJson);
        user.consumableRewardStatus.clear();
        statusMap.forEach((key, value) {
          user.consumableRewardStatus[key] = UserRewardPurchaseStatus.fromJson(value);
        });
        print('REWARD PERSISTENCE: Loaded ${user.consumableRewardStatus.length} consumable statuses');
        dataLoaded = true;
      }
      
      // 4. Critical step: Validate and ensure consistency between all loaded data
      if (dataLoaded) {
        _validateAndFixConsistency(user);
      }
      
      return dataLoaded;
    } catch (e) {
      print('REWARD PERSISTENCE ERROR: Failed to load reward state: $e');
      return false;
    }
  }
  
  /// Ensure all data is consistent and valid
  static void _validateAndFixConsistency(User user) {
    print('REWARD PERSISTENCE: Validating data consistency');
    
    // Track if we need to save changes
    bool needsSave = false;
    
    // Step 1: Make sure all collectibles in purchase history are marked as owned
    for (final purchase in user.purchaseHistory) {
      if (purchase.isCollectible && !user.ownedRewardIds.contains(purchase.itemId)) {
        user.ownedRewardIds.add(purchase.itemId);
        needsSave = true;
        print('REWARD PERSISTENCE: Fixed missing collectible ${purchase.itemName}');
      }
    }
    
    // Step 2: Make sure consumable cooldowns are up to date
    final now = DateTime.now();
    for (final reward in Reward.availableRewards) {
      if (!reward.isCollectible && reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
        // Get status for this consumable
        final status = user.consumableRewardStatus[reward.id];
        if (status != null && status.cooldownStartTime != null) {
          // Calculate cooldown end time
          final cooldownEndTime = status.cooldownStartTime!.add(
            Duration(hours: reward.purchasePeriodHours!)
          );
          
          // If cooldown has expired, reset it
          if (now.isAfter(cooldownEndTime)) {
            user.consumableRewardStatus[reward.id] = UserRewardPurchaseStatus(
              rewardId: reward.id,
              purchaseCount: 0,
              cooldownStartTime: null
            );
            needsSave = true;
            print('REWARD PERSISTENCE: Reset expired cooldown for ${reward.name}');
          }
        }
      }
    }
    
    // If we made any fixes, save the changes
    if (needsSave) {
      saveAll(user).then((success) {
        if (success) {
          print('REWARD PERSISTENCE: Saved fixes to consistency issues');
        }
      });
    }
  }
  
  /// Update after a reward purchase to ensure immediate persistence
  static Future<bool> updateAfterPurchase(User user, Reward reward) async {
    print('REWARD PERSISTENCE: Saving after purchase of ${reward.name}');
    return await saveAll(user);
  }
  
  /// Check if a reward is available for purchase based on persistent state
  static bool isRewardAvailable(User user, Reward reward) {
    // For collectibles, check if already owned
    if (reward.isCollectible) {
      return !user.ownedRewardIds.contains(reward.id);
    }
    
    // For consumables with purchase limits, check cooldown
    if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
      final status = user.consumableRewardStatus[reward.id];
      if (status == null) return true;
      
      // Check cooldown
      if (status.cooldownStartTime != null) {
        final cooldownEndTime = status.cooldownStartTime!.add(
          Duration(hours: reward.purchasePeriodHours!)
        );
        return DateTime.now().isAfter(cooldownEndTime);
      }
      
      // Check purchase count limit
      return status.purchaseCount < reward.purchaseLimitPerPeriod!;
    }
    
    // No restrictions
    return true;
  }
}
