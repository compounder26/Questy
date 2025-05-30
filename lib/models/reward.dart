import 'package:uuid/uuid.dart';

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String? type; // Optional reward type for special handling
  final Map<String, dynamic>? effectData; // Data for special effects

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    this.type,
    this.effectData,
  });

  // Static list of available rewards
  static final List<Reward> availableRewards = [
    Reward(
      id: const Uuid().v4(),
      name: 'Relaxation Token',
      description: 'Redeem for 30 minutes of guilt-free relaxation time.',
      cost: 50,
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Netflix Episode Pass',
      description: 'Watch one episode of your favorite show.',
      cost: 75,
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Gaming Hour Coupon',
      description: 'Enjoy one hour of uninterrupted gaming.',
      cost: 100,
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Small Snack Treat',
      description: 'Get yourself a small favorite snack.',
      cost: 40,
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Book Chapter Break',
      description: 'Read one chapter of a non-work/study book.',
      cost: 60,
    ),
    // Character attribute boosts
    Reward(
      id: const Uuid().v4(),
      name: 'Health Elixir',
      description: 'Boost your Health attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'health', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Intelligence Tome',
      description: 'Boost your Intelligence attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'intelligence', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Cleanliness Charm',
      description: 'Boost your Cleanliness attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'cleanliness', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Charisma Perfume',
      description: 'Boost your Charisma attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'charisma', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Unity Crystal',
      description: 'Boost your Unity attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'unity', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Power Gauntlet',
      description: 'Boost your Power attribute by 2.0 points.',
      cost: 120,
      type: 'attribute_boost',
      effectData: {'attribute': 'power', 'amount': 2.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'EXP Boost Scroll',
      description: 'Instantly gain 100 EXP for your character.',
      cost: 150,
      type: 'exp_boost',
      effectData: {'amount': 100},
    ),
  ];

  // Optional: Methods for JSON serialization if needed later
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cost': cost,
    'type': type,
    'effectData': effectData,
  };
  
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    cost: json['cost'],
    type: json['type'],
    effectData: json['effectData'],
  );
} 