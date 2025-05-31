import 'package:uuid/uuid.dart';

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String? type; // Optional reward type for special handling
  final String? iconAsset; // Path to the icon image
  final bool isCollectible; // Whether item goes to inventory or is consumed
  final Map<String, dynamic>? effectData; // Data for special effects

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    this.type,
    this.iconAsset,
    this.isCollectible = false, // Default to consumable
    this.effectData,
  });

  // Static list of available rewards
  static final List<Reward> availableRewards = [
    // Consumable rewards
    Reward(
      id: const Uuid().v4(),
      name: 'Minor Health Potion',
      description:
          'Restore 15% of your total health. A quick fix for minor injuries.',
      cost: 40,
      iconAsset: 'assets/images/Items/items/small health potion.png',
      isCollectible: false,
      type: 'consumable',
      effectData: {'healthRestore': 0.15},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Major Health Potion',
      description:
          'Restore 40% of your total health. For when battles get tough!',
      cost: 100,
      iconAsset: 'assets/images/Items/items/large health potion.png',
      isCollectible: false,
      type: 'consumable',
      effectData: {'healthRestore': 0.40},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Shield of Protection',
      description:
          'A sturdy shield that reduces damage taken by 15% for the next 3 encounters.',
      cost: 200,
      iconAsset: 'assets/images/Items/items/Shield.png',
      isCollectible: true,
      type: 'defense_boost',
      effectData: {'damageReduction': 0.15, 'duration': 3},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Excalibur',
      description:
          'The legendary sword increases your attack power by 25%. Only the worthy can wield it.',
      cost: 350,
      iconAsset: 'assets/images/Items/items/excalibur.png',
      isCollectible: true,
      type: 'attack_boost',
      effectData: {'attackBoost': 0.25},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Enchanted Teddy Bear',
      description:
          'This cuddly companion increases your charisma by 3 points and brings comfort during stressful times.',
      cost: 150,
      iconAsset: 'assets/images/Items/items/teddy bear.png',
      isCollectible: true,
      type: 'attribute_boost',
      effectData: {'attribute': 'charisma', 'amount': 3.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Magical Eraser',
      description:
          'Removes one failed task from your history. Everyone deserves a second chance!',
      cost: 120,
      iconAsset: 'assets/images/Items/items/eraser.png',
      isCollectible: false,
      type: 'task_eraser',
      effectData: {'removeCount': 1},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'XP Booster',
      description:
          'Doubles all experience gained for the next 24 hours. Level up faster!',
      cost: 250,
      iconAsset: 'assets/images/Items/items/booster.png',
      isCollectible: false,
      type: 'exp_multiplier',
      effectData: {'multiplier': 2, 'duration': 24}, // Duration in hours
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Star Coin Doubler',
      description:
          'Doubles all star currency earned for the next 48 hours. Get rich quick!',
      cost: 300,
      iconAsset: 'assets/images/Items/items/coin doubler.png',
      isCollectible: false,
      type: 'currency_multiplier',
      effectData: {'multiplier': 2, 'duration': 48}, // Duration in hours
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Magical Cap',
      description:
          'This enchanted cap increases your intelligence by 3 points and helps you focus on tasks.',
      cost: 180,
      iconAsset: 'assets/images/Items/items/topi ajaib.png',
      isCollectible: true,
      type: 'attribute_boost',
      effectData: {'attribute': 'intelligence', 'amount': 3.0},
    ),
    Reward(
      id: const Uuid().v4(),
      name: 'Time Ticker',
      description:
          'Adds an extra hour to your day - use it to complete an overdue task without penalty!',
      cost: 280,
      iconAsset: 'assets/images/Items/items/ticker.png',
      isCollectible: false,
      type: 'time_extension',
      effectData: {'extraHours': 1},
    ),
  ];

  // Methods for JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cost': cost,
        'type': type,
        'iconAsset': iconAsset,
        'isCollectible': isCollectible,
        'effectData': effectData,
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        cost: json['cost'],
        type: json['type'],
        iconAsset: json['iconAsset'],
        isCollectible: json['isCollectible'] ?? false,
        effectData: json['effectData'],
      );
}
