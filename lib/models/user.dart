import 'package:flutter/foundation.dart';
import './reward.dart'; // Import the new Reward class

class User extends ChangeNotifier {
  final String id;
  final String name;
  int points;
  int level;
  List<String> ownedRewardIds; // Store IDs of owned rewards

  User({
    required this.id,
    required this.name,
    this.points = 0,
    this.level = 1,
    List<String>? ownedRewardIds, // New parameter
  }) : ownedRewardIds = ownedRewardIds ?? []; // New initialization

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'level': level,
      'ownedRewardIds': ownedRewardIds, // New field in JSON
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 'default_user_id', // Add null checks/defaults
      name: json['name'] ?? 'Default User',
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      ownedRewardIds: List<String>.from(json['ownedRewardIds'] ?? []), // New field parsing
    );
  }

  void addPoints(int pointsToAdd) {
    points += pointsToAdd;
    // Level up every 1000 points
    int newLevel = (points ~/ 1000) + 1;
    if (newLevel > level) {
      level = newLevel;
      // Optionally add a notification or effect for leveling up here
    }
    notifyListeners();
  }

  // Method to attempt purchasing a reward
  bool purchaseReward(Reward reward) {
    if (points >= reward.cost && !ownedRewardIds.contains(reward.id)) {
      points -= reward.cost;
      ownedRewardIds.add(reward.id);
      notifyListeners(); // Notify listeners about the change in points and rewards
      return true; // Purchase successful
    } else {
      // Consider showing feedback why purchase failed (insufficient points or already owned)
      return false; // Purchase failed
    }
  }

  // Optional: Method to get the actual Reward objects the user owns
  List<Reward> get ownedRewards {
    return Reward.availableRewards
        .where((reward) => ownedRewardIds.contains(reward.id))
        .toList();
  }
} 