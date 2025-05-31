import 'package:uuid/uuid.dart';

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
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
    // Add more rewards as needed
    // Example: Fictional Sword (might need different implementation if it affects character)
    // Reward(
    //   id: const Uuid().v4(),
    //   name: 'Training Sword',
    //   description: 'A basic sword for your character (cosmetic).',
    //   cost: 250,
    // ),
  ];

  // Optional: Methods for JSON serialization if needed later
  // Map<String, dynamic> toJson() => { ... };
  // factory Reward.fromJson(Map<String, dynamic> json) => { ... };
} 