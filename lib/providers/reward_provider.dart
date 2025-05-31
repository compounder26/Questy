import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward.dart';
import '../models/user.dart';
import '../models/user_reward_purchase_status.dart';
import '../services/user_service.dart';

/// A dedicated provider for managing reward shop state persistence
class RewardProvider with ChangeNotifier {
  static const String _rewardStatusKey = 'reward_status_data';
  static const String _ownedRewardsKey = 'owned_rewards_data';

  // Called when the app starts to load reward state
  Future<void> loadRewardState(User user) async {
    print('BEGIN REWARD STATE LOAD PROCESS ====================');
    final prefs = await SharedPreferences.getInstance();
    
    // Load consumable status data
    final statusData = prefs.getString(_rewardStatusKey);
    if (statusData != null) {
      try {
        final Map<String, dynamic> statusMap = json.decode(statusData);
        
        // Convert the map to UserRewardPurchaseStatus objects
        final Map<String, UserRewardPurchaseStatus> loadedStatus = {};
        statusMap.forEach((key, value) {
          loadedStatus[key] = UserRewardPurchaseStatus.fromJson(value);
        });
        
        // Update user's consumableRewardStatus with the loaded data
        user.consumableRewardStatus.clear();
        user.consumableRewardStatus.addAll(loadedStatus);
        print('Loaded ${loadedStatus.length} reward status entries from local storage');
      } catch (e) {
        print('Error parsing reward status data: $e');
      }
    }
    
    // Load owned rewards data
    final ownedData = prefs.getString(_ownedRewardsKey);
    if (ownedData != null) {
      try {
        final List<dynamic> ownedList = json.decode(ownedData);
        final List<String> loadedOwned = ownedList.cast<String>();
        
        // Update user's ownedRewardIds with the loaded data
        user.ownedRewardIds.clear();
        user.ownedRewardIds.addAll(loadedOwned);
        print('Loaded ${loadedOwned.length} owned rewards from local storage');
      } catch (e) {
        print('Error parsing owned rewards data: $e');
      }
    }
    
    // Step 1: First, enforce collectible ownership based on purchase history
    // This is the most critical step - ensuring users can't repurchase collectibles
    bool ownershipUpdated = false;
    for (final purchase in user.purchaseHistory) {
      if (purchase.isCollectible && !user.ownedRewardIds.contains(purchase.itemId)) {
        user.ownedRewardIds.add(purchase.itemId);
        ownershipUpdated = true;
        print('CRITICAL FIX: Added missing collectible ${purchase.itemName} to owned items');
      }
    }
    
    // Step 2: Force-validate each consumable's status against purchase history
    bool consumableStatusUpdated = false;
    
    // We'll process each available reward to ensure proper setup
    for (final reward in Reward.availableRewards) {
      if (reward.isCollectible) {
        // Make double-sure collectibles from purchase history are marked as owned
        final wasPurchased = user.purchaseHistory.any(
          (purchase) => purchase.itemId == reward.id && purchase.isCollectible
        );
        
        if (wasPurchased && !user.ownedRewardIds.contains(reward.id)) {
          user.ownedRewardIds.add(reward.id);
          ownershipUpdated = true;
          print('CRITICAL FIX: Force-added collectible ${reward.name} to owned items');
        }
      } 
      else if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
        // Handle consumables with purchase limits and cooldowns
        
        // Get purchases of this item from history
        final purchases = user.purchaseHistory.where(
          (purchase) => purchase.itemId == reward.id && !purchase.isCollectible
        ).toList();
        
        if (purchases.isNotEmpty) {
          // Find most recent purchase for cooldown calculation
          DateTime mostRecentPurchase = purchases.first.purchaseDate;
          for (var purchase in purchases) {
            if (purchase.purchaseDate.isAfter(mostRecentPurchase)) {
              mostRecentPurchase = purchase.purchaseDate;
            }
          }
          
          // Calculate cooldown end time
          final cooldownEndTime = mostRecentPurchase.add(Duration(hours: reward.purchasePeriodHours!));
          final now = DateTime.now();
          
          // Get or create status for this reward
          UserRewardPurchaseStatus status = user.consumableRewardStatus[reward.id] ?? 
                                        UserRewardPurchaseStatus(rewardId: reward.id);
          
          // Determine purchase count based on history and cooldown
          int updatedPurchaseCount;
          DateTime? updatedCooldownStartTime;
          
          if (now.isAfter(cooldownEndTime)) {
            // Cooldown has expired, reset purchase count
            updatedPurchaseCount = 0;
            updatedCooldownStartTime = null;
            print('COOLDOWN EXPIRED: Reset cooldown for ${reward.name}');
          } else {
            // Still in cooldown period, set count based on purchases in this period
            updatedPurchaseCount = purchases.where(
              (p) => p.purchaseDate.isAfter(cooldownEndTime.subtract(Duration(hours: reward.purchasePeriodHours!)))
            ).length;
            updatedPurchaseCount = updatedPurchaseCount.clamp(0, reward.purchaseLimitPerPeriod!);
            updatedCooldownStartTime = mostRecentPurchase;
            print('ENFORCING COOLDOWN: ${reward.name} cooldown active until ${cooldownEndTime}');
          }
          
          // Update status if needed
          if (status.purchaseCount != updatedPurchaseCount || 
              status.cooldownStartTime != updatedCooldownStartTime) {
            user.consumableRewardStatus[reward.id] = UserRewardPurchaseStatus(
              rewardId: reward.id,
              purchaseCount: updatedPurchaseCount,
              cooldownStartTime: updatedCooldownStartTime,
            );
            consumableStatusUpdated = true;
            print('CRITICAL FIX: Updated status for ${reward.name} - count: $updatedPurchaseCount, cooldown: ${updatedCooldownStartTime != null}');
          }
        }
      }
    }
    
    // If we made critical fixes, save immediately
    if (ownershipUpdated || consumableStatusUpdated) {
      print('CRITICAL FIXES APPLIED - Saving user and reward state');
      await saveRewardState(user);
      await UserService.saveUser(user);
    }
    
    // Final safety check - validate all rewards one more time
    for (final reward in Reward.availableRewards) {
      final status = user.consumableRewardStatus[reward.id];
      final isOwned = user.ownedRewardIds.contains(reward.id);
      final bool isAvailable = reward.isAvailableForUser(status, isOwned);
      
      print('VALIDATION: ${reward.name} (${reward.id}) - Available: $isAvailable, ' +
            (reward.isCollectible ? 'Owned: $isOwned' : 'In cooldown: ${status?.cooldownStartTime != null}'));
    }
    
    print('END REWARD STATE LOAD PROCESS ====================');
    
    // Final save to ensure consistency
    await UserService.saveUser(user);
  }

  // Called whenever reward state changes to save it immediately
  Future<void> saveRewardState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Save consumable reward status data
      final Map<String, dynamic> statusMap = {};
      user.consumableRewardStatus.forEach((key, status) {
        statusMap[key] = status.toJson();
      });
      final String statusJson = json.encode(statusMap);
      await prefs.setString(_rewardStatusKey, statusJson);
      
      // Save owned rewards data
      final String ownedJson = json.encode(user.ownedRewardIds);
      await prefs.setString(_ownedRewardsKey, ownedJson);
      
      print('Saved reward state to local storage: ${user.consumableRewardStatus.length} status entries, ${user.ownedRewardIds.length} owned rewards');
    } catch (e) {
      print('Error saving reward state: $e');
    }
    
    // Also save the user to ensure consistency
    await UserService.saveUser(user);
  }
  
  // Process and update reward statuses, checking for expired cooldowns
  void _refreshRewardStatuses(User user) {
    final now = DateTime.now();
    bool needsSave = false;
    
    // Ensure all available rewards have correct status entries
    for (final reward in Reward.availableRewards) {
      // Skip collectibles as they're handled by _syncCollectiblesWithPurchaseHistory
      if (reward.isCollectible) continue;
      
      // Only process consumables with purchase limits
      if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
        // Get or create status for this reward
        final status = user.consumableRewardStatus[reward.id] ?? 
                      UserRewardPurchaseStatus(rewardId: reward.id);
        
        // Skip if no cooldown is set
        if (status.cooldownStartTime == null) {
          // Ensure status is saved even if no cooldown
          if (!user.consumableRewardStatus.containsKey(reward.id)) {
            user.consumableRewardStatus[reward.id] = status;
            needsSave = true;
          }
          continue;
        }
        
        // Check if cooldown has expired
        final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: reward.purchasePeriodHours!));
        
        if (now.isAfter(cooldownEndTime)) {
          // Cooldown expired, reset purchase count
          user.consumableRewardStatus[reward.id] = status.copyWith(
            purchaseCount: 0,
            setCooldownStartTimeToNull: true,
          );
          needsSave = true;
          print('Reset expired cooldown for reward ID ${reward.id} during refresh');
        }
      }
    }
    
    // If changes were made, save the reward state
    if (needsSave) {
      saveRewardState(user);
      print('Reward state saved after refreshing statuses');
    }
  }
  
  // Only expose the single comprehensive updateRewardPurchase method at the end of this class
  // No placeholder needed here as we've consolidated to avoid duplicates
  
  // Synchronize collectible ownership with purchase history
  void _syncCollectiblesWithPurchaseHistory(User user) {
    bool needsSave = false;
    Set<String> collectedIds = Set.from(user.ownedRewardIds);
    
    // Check purchase history for collectibles that should be marked as owned
    for (final purchase in user.purchaseHistory) {
      if (purchase.isCollectible && !collectedIds.contains(purchase.itemId)) {
        // Found a collectible in purchase history that's not in ownedRewardIds
        user.ownedRewardIds.add(purchase.itemId);
        collectedIds.add(purchase.itemId);
        needsSave = true;
        print('Added missing collectible ${purchase.itemName} (${purchase.itemId}) to owned items from purchase history');
      }
    }
    
    // Also verify all owned rewards exist in purchase history
    for (final rewardId in user.ownedRewardIds.toList()) {
      // Find the reward definition
      final matchingRewards = Reward.availableRewards.where(
        (r) => r.id == rewardId && r.isCollectible
      ).toList();
      
      if (matchingRewards.isEmpty) continue; // Skip if not found in available rewards
      
      final reward = matchingRewards.first;
      
      // Check if this owned reward is missing from purchase history
      bool isInHistory = user.purchaseHistory.any((item) => item.itemId == rewardId);
      
      if (!isInHistory) {
        // Add missing entry to purchase history for consistency
        user.purchaseHistory.add(PurchaseHistoryItem(
          itemId: rewardId,
          itemName: reward.name,
          purchaseDate: DateTime.now(), // Use current time as we don't know the actual purchase time
          isCollectible: true,
          iconAsset: reward.iconAsset,
        ));
        needsSave = true;
        print('Added missing purchase history entry for owned collectible ${reward.name}');
      }
    }
    
    if (needsSave) {
      saveRewardState(user);
      print('Reward state saved after syncing collectibles with purchase history');
    }
  }
  
  // Public method to refresh reward statuses and check for expired cooldowns
  // This comprehensive method handles both collectible synchronization and cooldown refreshes
  Future<void> refreshRewardStatuses(User user) async {
    _syncCollectiblesWithPurchaseHistory(user);
    _refreshRewardStatuses(user);
    await saveRewardState(user);
  }
  
  // Update reward purchase tracking comprehensively
  // This ensures proper synchronization between purchase history and reward state
  // wasPurchased: true if this is a new purchase that just happened, false if we're just validating consistency
  Future<void> updateRewardPurchase(User user, Reward reward, bool wasPurchased) async {
    bool needsUpdate = false;
    
    // If this is a successful purchase, ensure immediate state persistence
    if (wasPurchased) {
      await saveRewardState(user);
      print('Reward state saved after purchase of ${reward.name}');
      return;
    }
    
    // Otherwise, perform deep validation and synchronization for this specific reward
    
    // For collectibles, ensure ownership is correctly tracked
    if (reward.isCollectible) {
      // Check if user should own this collectible based on purchase history
      bool hasEverPurchased = user.purchaseHistory.any(
        (purchase) => purchase.itemId == reward.id && purchase.isCollectible
      );
      
      // Ensure consistency between purchase history and owned items
      if (hasEverPurchased && !user.ownedRewardIds.contains(reward.id)) {
        // If purchased but not owned, add to owned items
        user.ownedRewardIds.add(reward.id);
        needsUpdate = true;
        print('Fixed missing collectible ownership for ${reward.name} (${reward.id})');
      } else if (!hasEverPurchased && user.ownedRewardIds.contains(reward.id) && !wasPurchased) {
        // If not purchased but owned, remove from owned items
        // But only if this isn't a current purchase (wasPurchased = false)
        user.ownedRewardIds.remove(reward.id);
        needsUpdate = true;
        print('Fixed incorrect collectible ownership for ${reward.name} (${reward.id})');
      }
    }
    // For consumables with purchase limits, ensure cooldown status is correct
    else if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
      // Get current status or create a new one
      UserRewardPurchaseStatus status = user.consumableRewardStatus[reward.id] ?? 
                                    UserRewardPurchaseStatus(rewardId: reward.id);
      
      // Count purchases of this item in history
      int purchaseCount = user.purchaseHistory.where(
        (purchase) => purchase.itemId == reward.id && !purchase.isCollectible
      ).length;
      
      // Find the most recent purchase for cooldown calculation
      DateTime? mostRecentPurchase;
      for (var purchase in user.purchaseHistory) {
        if (purchase.itemId == reward.id && !purchase.isCollectible) {
          if (mostRecentPurchase == null || purchase.purchaseDate.isAfter(mostRecentPurchase)) {
            mostRecentPurchase = purchase.purchaseDate;
          }
        }
      }
      
      // Check if cooldown has expired
      bool cooldownExpired = false;
      if (status.cooldownStartTime != null) {
        final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: reward.purchasePeriodHours!));
        if (DateTime.now().isAfter(cooldownEndTime)) {
          cooldownExpired = true;
        }
      }
      
      // Determine if status needs an update
      bool statusNeedsUpdate = false;
      
      // If this is a new purchase, don't override the status as it's already been set correctly
      if (!wasPurchased) {
        if (cooldownExpired) {
          // Reset purchase count if cooldown expired
          if (status.purchaseCount > 0) {
            status = status.copyWith(purchaseCount: 0, setCooldownStartTimeToNull: true);
            statusNeedsUpdate = true;
          }
        } else if (mostRecentPurchase != null && (status.cooldownStartTime == null || 
                 !status.cooldownStartTime!.isAtSameMomentAs(mostRecentPurchase))) {
          // Fix cooldown start time if inconsistent with most recent purchase
          status = status.copyWith(cooldownStartTime: mostRecentPurchase);
          statusNeedsUpdate = true;
        }
        
        // Ensure purchase count matches with history if within cooldown period
        if (!cooldownExpired && status.purchaseCount != purchaseCount && purchaseCount > 0) {
          status = status.copyWith(purchaseCount: purchaseCount);
          statusNeedsUpdate = true;
        }
      }
      
      // Update status if needed
      if (statusNeedsUpdate) {
        user.consumableRewardStatus[reward.id] = status;
        needsUpdate = true;
        print('Updated consumable status for ${reward.name} (${reward.id})');
      }
    }
    
    // Save changes if needed
    if (needsUpdate) {
      await saveRewardState(user);
      user.notifyListeners();
    }
  }
}
