import 'package:flutter/foundation.dart';
import './reward.dart'; // Import the new Reward class
import '../services/user_service.dart'; // Import the UserService
import './attribute_stats.dart'; // Import the new AttributeStats class
import './user_reward_purchase_status.dart'; // Import for consumable reward status

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
    return User(
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
  bool purchaseReward(Reward reward) {
    // Check if user has enough currency
    if (starCurrency < reward.cost) {
      print('Purchase failed: Insufficient star currency.');
      return false; // Insufficient funds
    }

    // Handle collectible items
    if (reward.isCollectible) {
      if (ownedRewardIds.contains(reward.id)) {
        print('Purchase failed: Collectible item already owned.');
        return false; // Already owned
      }
      starCurrency -= reward.cost;
      ownedRewardIds.add(reward.id);
      // Add to general purchase history
      purchaseHistory.add(PurchaseHistoryItem(
        itemId: reward.id,
        itemName: reward.name,
        purchaseDate: DateTime.now(),
        isCollectible: true,
        iconAsset: reward.iconAsset,
      ));
      // Apply effects if any (though collectibles might not have immediate use effects like consumables)
      _applyRewardEffects(reward);
      notifyListeners();
      UserService.saveUser(this);
      return true;
    }

    // Handle consumable items (or items without specific collectible status but with limits)
    if (reward.purchaseLimitPerPeriod != null && reward.purchasePeriodHours != null) {
      UserRewardPurchaseStatus status = consumableRewardStatus[reward.id] ?? 
                                      UserRewardPurchaseStatus(rewardId: reward.id);

      // Check cooldown status
      if (status.cooldownStartTime != null) {
        final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: reward.purchasePeriodHours!));
        if (DateTime.now().isBefore(cooldownEndTime)) {
          print('Purchase failed: Item is on cooldown.');
          return false; // Item on cooldown
        } else {
          // Cooldown has passed, reset status
          status = status.copyWith(purchaseCount: 0, setCooldownStartTimeToNull: true);
        }
      }

      // Check purchase limit
      if (status.purchaseCount >= reward.purchaseLimitPerPeriod!) {
        // This case should ideally be caught by cooldown, but as a safeguard:
        // If limit is met, and not on cooldown (e.g. first time hitting limit after reset)
        // We should initiate cooldown here if not already done.
        // However, the purchase itself should be denied if count is already at limit.
        print('Purchase failed: Purchase limit reached for the period.');
        // Ensure cooldown is set if it wasn't (e.g., if data was manually changed or an edge case)
        if (status.cooldownStartTime == null) {
            consumableRewardStatus[reward.id] = status.copyWith(cooldownStartTime: DateTime.now());
            notifyListeners();
            UserService.saveUser(this);
        }
        return false; 
      }

      // Process the purchase for consumable
      starCurrency -= reward.cost;
      int newPurchaseCount = status.purchaseCount + 1;
      DateTime? newCooldownStartTime = status.cooldownStartTime;

      if (newPurchaseCount >= reward.purchaseLimitPerPeriod!) {
        newCooldownStartTime = DateTime.now(); // Start cooldown as limit is now hit
      }
      
      consumableRewardStatus[reward.id] = status.copyWith(
        purchaseCount: newPurchaseCount,
        cooldownStartTime: newCooldownStartTime,
      );
      
      // Add to general purchase history
      purchaseHistory.add(PurchaseHistoryItem(
        itemId: reward.id,
        itemName: reward.name,
        purchaseDate: DateTime.now(),
        isCollectible: false,
        iconAsset: reward.iconAsset,
      ));
      _applyRewardEffects(reward);
      notifyListeners();
      UserService.saveUser(this);
      return true;

    } else {
      // Consumable item without a specific limit/cooldown (behaves like a simple purchase)
      starCurrency -= reward.cost;
      // Add to general purchase history
      purchaseHistory.add(PurchaseHistoryItem(
        itemId: reward.id,
        itemName: reward.name,
        purchaseDate: DateTime.now(),
        isCollectible: false, // Assuming if not collectible and no limit, it's a generic consumable
        iconAsset: reward.iconAsset,
      ));
      _applyRewardEffects(reward);
      notifyListeners();
      UserService.saveUser(this);
      return true;
    }
  }

  // Helper method to apply reward effects, extracted for clarity
  void _applyRewardEffects(Reward reward) {
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
          final int? expAmount = reward.effectData!['amount'] as int?;
          if (expAmount != null) {
            addExp(expAmount);
          }
          break;
        // Add other effect types here if necessary
        // e.g., case 'task_eraser':
        // case 'reward_multiplier':
        // case 'daily_reset':
        // case 'currency_multiplier':
      }
    }
  }

  // Optional: Method to get the actual Reward objects the user owns
  List<Reward> get ownedRewards {
    return Reward.availableRewards
        .where((reward) => ownedRewardIds.contains(reward.id))
        .toList();
  }
} 