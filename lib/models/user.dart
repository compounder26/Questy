import 'package:flutter/foundation.dart';
import './reward.dart'; // Import the new Reward class
import '../services/user_service.dart'; // Import the UserService
import './attribute_stats.dart'; // Import the new AttributeStats class

class User extends ChangeNotifier {
  final String id;
  final String name;
  int starCurrency; // Renamed from points to starCurrency
  int level;
  int exp; // New experience points separate from star currency
  List<String> ownedRewardIds; // Store IDs of owned rewards
  AttributeStats attributeStats; // New attribute stats

  User({
    required this.id,
    required this.name,
    this.starCurrency = 0, // Renamed from points
    this.level = 1,
    this.exp = 0, // New property
    List<String>? ownedRewardIds,
    AttributeStats? attributeStats, // New parameter
  }) : 
    ownedRewardIds = ownedRewardIds ?? [],
    attributeStats = attributeStats ?? AttributeStats(); // Initialize with default stats

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'starCurrency': starCurrency, // Renamed from points
      'level': level,
      'exp': exp, // New field in JSON
      'ownedRewardIds': ownedRewardIds,
      'attributeStats': attributeStats.toJson(), // Serialize attribute stats
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
    // Only check if user has enough stars - removed ownership check to allow multiple purchases
    if (starCurrency >= reward.cost) {
      starCurrency -= reward.cost;
      
      // Handle special rewards with effects
      if (reward.type != null) {
        if (reward.type == 'attribute_boost' && reward.effectData != null) {
          // Apply attribute boost
          final String? attribute = reward.effectData!['attribute'] as String?;
          final double? amount = reward.effectData!['amount'] as double?;
          
          if (attribute != null && amount != null) {
            increaseAttribute(attribute, amount);
          }
        } else if (reward.type == 'exp_boost' && reward.effectData != null) {
          // Apply EXP boost
          final int? expAmount = reward.effectData!['amount'] as int?;
          
          if (expAmount != null) {
            addExp(expAmount);
          }
        }
      }
      
      // For permanent items, we still track that the item has been purchased at least once
      // but don't prevent repurchasing
      if (!ownedRewardIds.contains(reward.id)) {
        ownedRewardIds.add(reward.id);
      }
      
      notifyListeners(); // Notify listeners about the change in starCurrency and rewards
      
      // Save user data to persistent storage
      UserService.saveUser(this);
      return true; // Purchase successful
    } else {
      // Only fails if not enough stars
      return false; // Purchase failed - insufficient funds
    }
  }

  // Optional: Method to get the actual Reward objects the user owns
  List<Reward> get ownedRewards {
    return Reward.availableRewards
        .where((reward) => ownedRewardIds.contains(reward.id))
        .toList();
  }
} 