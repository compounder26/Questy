import 'package:flutter/foundation.dart';
import './reward.dart'; // Import the new Reward class
import '../services/user_service.dart'; // Import the UserService
import './attribute_stats.dart'; // Import the new AttributeStats class
import './user_reward_purchase_status.dart'; // Import for consumable reward status
import './reward_persistence.dart'; // Import our new dedicated persistence system

// New class for purchase history items
class PurchaseHistoryItem {
  final String itemId;
  final String itemName;
  final DateTime purchaseDate;
  final bool isCollectible;
  final String? iconAsset;

  PurchaseHistoryItem({
    required this.itemId,
    required this.itemName,
    required this.purchaseDate,
    required this.isCollectible,
    this.iconAsset,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'itemName': itemName,
    'purchaseDate': purchaseDate.toIso8601String(),
    'isCollectible': isCollectible,
    'iconAsset': iconAsset,
  };

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> json) => PurchaseHistoryItem(
    itemId: json['itemId'],
    itemName: json['itemName'],
    purchaseDate: DateTime.parse(json['purchaseDate']),
    isCollectible: json['isCollectible'] ?? false, // Default to false if missing
    iconAsset: json['iconAsset'],
  );
}

class User extends ChangeNotifier {
  final String id;
  final String name;
  int starCurrency; // Renamed from points to starCurrency
  int level;
  int exp; // New experience points separate from star currency
  List<String> ownedRewardIds; // Store IDs of owned rewards
  AttributeStats attributeStats; // New attribute stats
  List<PurchaseHistoryItem> purchaseHistory; // New field for purchase history
  Map<String, UserRewardPurchaseStatus> consumableRewardStatus; // Tracks status of consumable rewards

  User({
    required this.id,
    required this.name,
    this.starCurrency = 0, // Renamed from points
    this.level = 1,
    this.exp = 0, // New property
    List<String>? ownedRewardIds,
    AttributeStats? attributeStats, // New parameter
    List<PurchaseHistoryItem>? purchaseHistory, // New parameter
    Map<String, UserRewardPurchaseStatus>? consumableRewardStatus, // New parameter
  }) : 
    ownedRewardIds = ownedRewardIds ?? [],
    attributeStats = attributeStats ?? AttributeStats(),
    purchaseHistory = purchaseHistory ?? [], // Initialize new field
    consumableRewardStatus = consumableRewardStatus ?? {}; // Initialize new field

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'starCurrency': starCurrency, // Renamed from points
      'level': level,
      'exp': exp, // New field in JSON
      'ownedRewardIds': ownedRewardIds,
      'attributeStats': attributeStats.toJson(), // Serialize attribute stats
      'purchaseHistory': purchaseHistory.map((item) => item.toJson()).toList(), // Serialize purchase history
      'consumableRewardStatus': consumableRewardStatus.map((key, value) => MapEntry(key, value.toJson())), // Serialize consumable reward status
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // First parse the basic user data
    final user = User(
      id: json['id'] ?? 'default_user_id',
      name: json['name'] ?? 'Default User',
      starCurrency: json['starCurrency'] ?? json['points'] ?? 0, // Handle both new and old field names
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0, // Parse new field
      ownedRewardIds: List<String>.from(json['ownedRewardIds'] ?? []),
      attributeStats: json['attributeStats'] != null 
          ? AttributeStats.fromJson(json['attributeStats']) 
          : AttributeStats(), // Parse attributes if available
      purchaseHistory: (json['purchaseHistory'] as List<dynamic>?)
          ?.map((item) => PurchaseHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      consumableRewardStatus: (json['consumableRewardStatus'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, UserRewardPurchaseStatus.fromJson(value as Map<String, dynamic>))) 
          ?? {},
    );
    
    // Process reward statuses to check for expired cooldowns
    user._refreshRewardStatuses();
    
    return user;
  }

  // Method to add star currency (previously points)
  void addStarCurrency(int amount) {
    starCurrency += amount;
    notifyListeners();
    
    // Save user data to persistent storage
    UserService.saveUser(this);
  }

  // Method to add experience points
  void addExp(int expToAdd) {
    exp += expToAdd;
    
    // Level calculation based on exponential curve: 100 * level^2
    int expNeededForNextLevel = 100 * (level * level);
    
    if (exp >= expNeededForNextLevel) {
      level += 1;
      // Optional: add a reward or notification for leveling up
    }
    
    notifyListeners();
    
    // Save user data to persistent storage
    UserService.saveUser(this);
  }

  // Method to increase a specific attribute
  void increaseAttribute(String attributeName, double amount) {
    attributeStats.increaseAttribute(attributeName, amount);
    notifyListeners();
    
    // Save user data to persistent storage
    UserService.saveUser(this);
  }

  // Get the exp needed for the next level
  int getExpNeededForNextLevel() {
    return 100 * (level * level);
  }

  // Get the progress percentage towards the next level (0.0 to 1.0)
  double getLevelProgress() {
    int expNeededForCurrentLevel = level <= 1 ? 0 : 100 * ((level - 1) * (level - 1));
    int expNeededForNextLevel = 100 * (level * level);
    int expForThisLevel = exp - expNeededForCurrentLevel;
    int expRangeForThisLevel = expNeededForNextLevel - expNeededForCurrentLevel;
    
    return expForThisLevel / expRangeForThisLevel;
  }

  // Method to attempt purchasing a reward
  bool purchaseReward(Reward reward, {Function? onTaskEraserPurchased}) {
    print('PURCHASE ATTEMPT: ${reward.name} (ID: ${reward.id})');
    
    // Directly check availability using our persistence system
    if (!RewardPersistence.isRewardAvailable(this, reward)) {
      print('PURCHASE BLOCKED: ${reward.name} is not available for purchase');
      return false;
    }

    // Check if user has enough currency
    if (starCurrency < reward.cost) {
      print('PURCHASE FAILED: Insufficient star currency');
      return false; // Insufficient funds
    }

    // Process purchase based on item type
    starCurrency -= reward.cost;
    
    // Handle collectible items
    if (reward.isCollectible) {
      // Mark as owned
      ownedRewardIds.add(reward.id);
      print('COLLECTIBLE PURCHASED: ${reward.name} (ID: ${reward.id})');
    } 
    // Handle consumable items with limits
    else if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
      // Get or create status for this reward
      UserRewardPurchaseStatus status = consumableRewardStatus[reward.id] ?? 
                                    UserRewardPurchaseStatus(rewardId: reward.id);
      
      // Update purchase count
      int newCount = status.purchaseCount + 1;
      DateTime? newCooldownStartTime = status.cooldownStartTime;
      
      // Set cooldown if limit reached
      if (newCount >= reward.purchaseLimitPerPeriod!) {
        newCooldownStartTime = DateTime.now();
        print('COOLDOWN STARTED: ${reward.name} - next available in ${reward.purchasePeriodHours} hours');
      }
      
      // Update status
      consumableRewardStatus[reward.id] = status.copyWith(
        purchaseCount: newCount,
        cooldownStartTime: newCooldownStartTime,
      );
      
      print('CONSUMABLE PURCHASED: ${reward.name}, count: $newCount/${reward.purchaseLimitPerPeriod}');
    }
    // Simple consumables with no limits need no special handling
    else {
      print('SIMPLE CONSUMABLE PURCHASED: ${reward.name}');
    }
    
    // Always add to purchase history
    purchaseHistory.add(PurchaseHistoryItem(
      itemId: reward.id,
      itemName: reward.name,
      purchaseDate: DateTime.now(),
      isCollectible: reward.isCollectible,
      iconAsset: reward.iconAsset,
    ));
    
    // Apply any special effects
    _applyRewardEffects(reward, onTaskEraserPurchased: onTaskEraserPurchased);
    
    // Save changes through both systems to ensure consistency
    notifyListeners();
    UserService.saveUser(this);
    
    // CRITICAL: Use our dedicated persistence system for reward data
    RewardPersistence.updateAfterPurchase(this, reward);
    
    print('PURCHASE COMPLETE: ${reward.name}');
    return true;
  }

  // Helper method to apply reward effects, extracted for clarity
  void _applyRewardEffects(Reward reward, {Function? onTaskEraserPurchased}) {
    if (reward.type != null && reward.effectData != null) {
      switch (reward.type) {
        case 'attribute_boost':
          final String? attribute = reward.effectData!['attribute'] as String?;
          final double? amount = reward.effectData!['amount'] as double?;
          if (attribute != null && amount != null) {
            increaseAttribute(attribute, amount);
          }
          break;
        case 'exp_boost':
          final int? expAmount = reward.effectData!['expAmount'] as int?;
          if (expAmount != null) {
            addExp(expAmount);
          }
          break;
        case 'task_eraser':
          // Task Eraser should be used immediately upon purchase
          if (onTaskEraserPurchased != null) {
            onTaskEraserPurchased();
          }
          break;
        // Add other effect types here if necessary
        // case 'reward_multiplier':
        // case 'daily_reset':
        // case 'currency_multiplier':
      }
    }
  }

  // Refresh reward statuses when loading the user - check for expired cooldowns
  void _refreshRewardStatuses() {
    final now = DateTime.now();
    bool needsSave = false;
    
    // Process all consumable reward statuses to check for expired cooldowns
    for (final entry in consumableRewardStatus.entries.toList()) {
      final rewardId = entry.key;
      final status = entry.value;
      
      // Skip if no cooldown is set
      if (status.cooldownStartTime == null) continue;
      
      // Find the corresponding reward
      final matchingRewards = Reward.availableRewards.where(
        (r) => r.id == rewardId && r.purchasePeriodHours != null && !r.isCollectible
      ).toList();
      
      // Skip if reward not found
      if (matchingRewards.isEmpty) continue;
      
      final reward = matchingRewards.first;
      
      // Check if cooldown has expired
      final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: reward.purchasePeriodHours!));
      
      if (now.isAfter(cooldownEndTime)) {
        // Cooldown expired, reset purchase count
        consumableRewardStatus[rewardId] = status.copyWith(
          purchaseCount: 0,
          setCooldownStartTimeToNull: true,
        );
        needsSave = true;
        print('Reset expired cooldown for reward ID ${rewardId} during user load');
      }
    }
    
    // If changes were made, save the user
    if (needsSave) {
      UserService.saveUser(this);
      print('User data saved after refreshing reward statuses');
    }
  }
  
  // Optional: Method to get the actual Reward objects the user owns
  List<Reward> get ownedRewards {
    return Reward.availableRewards
        .where((reward) => ownedRewardIds.contains(reward.id))
        .toList();
  }
  
  // Method to update user data from another user instance
  // This ensures consistent state when loading from persistence
  void updateFromUser(User other) {
    // Update basic properties
    starCurrency = other.starCurrency;
    level = other.level;
    exp = other.exp;
    
    // Update reward-related properties (deep copy to avoid reference issues)
    ownedRewardIds = List<String>.from(other.ownedRewardIds);
    
    // Deep copy the purchase history
    purchaseHistory = other.purchaseHistory.map((item) => PurchaseHistoryItem(
      itemId: item.itemId,
      itemName: item.itemName,
      purchaseDate: item.purchaseDate,
      isCollectible: item.isCollectible,
      iconAsset: item.iconAsset,
    )).toList();
    
    // Deep copy the consumable reward status
    consumableRewardStatus = {};
    other.consumableRewardStatus.forEach((key, value) {
      consumableRewardStatus[key] = UserRewardPurchaseStatus(
        rewardId: value.rewardId,
        purchaseCount: value.purchaseCount,
        cooldownStartTime: value.cooldownStartTime,
      );
    });
    
    // Update attribute stats
    attributeStats = AttributeStats.fromJson(other.attributeStats.toJson());
    
    // Notify listeners of the update
    notifyListeners();
  }
} 