import 'package:uuid/uuid.dart';
import './user_reward_purchase_status.dart'; // Required for getters

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String? type; // Optional reward type for special handling
  final String? iconAsset; // Path to the icon image
  final bool isCollectible; // Whether item is a collectible or consumable
  final Map<String, dynamic>? effectData; // Data for special effects
  final int? purchaseLimitPerPeriod; // Max times this can be bought within the period
  final int? purchasePeriodHours; // Cooldown period in hours (null means no cooldown)

  // purchaseCount and lastPurchaseTime are removed as they are user-specific

  // Getter for availability, now requires user-specific status
  bool isAvailableForUser(UserRewardPurchaseStatus? status, bool isOwnedCollectible) {
    if (isCollectible) {
      return !isOwnedCollectible;
    }
    if (purchaseLimitPerPeriod == null) {
      return true; // Always available if no limit
    }
    if (status == null) {
      return true; // No purchase history, so available
    }
    // Check cooldown
    if (status.cooldownStartTime != null && purchasePeriodHours != null) {
      final cooldownEndTime = status.cooldownStartTime!.add(Duration(hours: purchasePeriodHours!));
      if (DateTime.now().isBefore(cooldownEndTime)) {
        return false; // On cooldown
      }
    }
    return status.purchaseCount < purchaseLimitPerPeriod!;
  }

  // Getter for availability text, requires user-specific status
  String getAvailabilityTextForUser(UserRewardPurchaseStatus? status, bool isOwnedCollectible) {
    if (isCollectible) {
      return isOwnedCollectible ? 'Owned' : 'Available';
    }
    if (purchaseLimitPerPeriod == null || purchasePeriodHours == null) {
      return 'Available';
    }
    
    int currentPurchaseCount = status?.purchaseCount ?? 0;
    String limitText = '${purchaseLimitPerPeriod!} per ${purchasePeriodHours}h';

    if (status?.cooldownStartTime != null) {
        final cooldownEndTime = status!.cooldownStartTime!.add(Duration(hours: purchasePeriodHours!));
        if (DateTime.now().isBefore(cooldownEndTime)) {
            // Cooldown active, timer will be shown separately by UI
            // Text should still reflect the underlying limit, e.g., 3/3 purchased, now cooling down
            return '${purchaseLimitPerPeriod!}/${limitText}'; 
        }
        // Cooldown finished, count should have been reset by purchase logic or will be on next attempt
        currentPurchaseCount = 0; // Reflects that it's available again post-cooldown
    }
    
    return '${purchaseLimitPerPeriod! - currentPurchaseCount}/${limitText}';
  }

  Reward({
    String? id,
    required this.name,
    required this.description,
    required this.cost,
    this.type,
    this.iconAsset,
    this.isCollectible = false,
    this.effectData,
    this.purchaseLimitPerPeriod,
    this.purchasePeriodHours,
    // purchaseCount and lastPurchaseTime constructor params removed
  }) : 
    id = id ?? const Uuid().v4();

  // markAsPurchased and updateCooldown methods are removed.
  // This logic is now handled within User.purchaseReward and by checking UserRewardPurchaseStatus.

  // Static list of available rewards
  static final List<Reward> availableRewards = [
    // Consumable rewards
    Reward(
      name: 'EXP Potion (S)',
      description: 'Tambah 10 EXP',
      cost: 40,
      iconAsset: 'assets/images/Items/Consumables/small_xp_potion.png',
      isCollectible: false,
      type: 'exp_boost',
      effectData: {'expAmount': 10},
      purchaseLimitPerPeriod: 3,
      purchasePeriodHours: 24, // 3x per day
    ),
    Reward(
      name: 'EXP Potion (L)',
      description: 'Tambah 30 EXP',
      cost: 100,
      iconAsset: 'assets/images/Items/Consumables/large_xp_potion.png',
      isCollectible: false,
      type: 'exp_boost',
      effectData: {'expAmount': 30},
      purchaseLimitPerPeriod: 1,
      purchasePeriodHours: 24, // 1x per day
    ),
    Reward(
      name: 'Task Eraser',
      description: 'Hapus 1 task aktif tanpa penalti (tidak dapat digunakan pada task Hard)',
      cost: 30,
      iconAsset: 'assets/images/Items/Consumables/task_eraser.png',
      isCollectible: false,
      type: 'task_eraser',
      effectData: {'removeCount': 1},
      purchaseLimitPerPeriod: 2,
      purchasePeriodHours: 24, // 2x per day
    ),
    Reward(
      name: 'Focus Booster',
      description: 'Mengaktifkan "Focus Mode" 30 menit: reward task ditingkatkan 1.5x',
      cost: 50,
      iconAsset: 'assets/images/Items/Consumables/focus_booster.png',
      isCollectible: false,
      type: 'reward_multiplier',
      effectData: {'multiplier': 1.5, 'duration': 30}, // 30 minutes
      purchaseLimitPerPeriod: 1,
      purchasePeriodHours: 6, // 1x per 6 hours
    ),
    Reward(
      name: 'Daily Reset Ticket',
      description: 'Reset seluruh task harian (digunakan jika user ingin re-roll task)',
      cost: 15,
      iconAsset: 'assets/images/Items/Consumables/ticket.png',
      isCollectible: false,
      type: 'daily_reset',
      purchaseLimitPerPeriod: 1,
      purchasePeriodHours: 24, // 1x per day
    ),
    Reward(
      name: 'Coin Doubler (3 jam)',
      description: 'Coin dari task selama 3 jam berikutnya dikalikan 2',
      cost: 30,
      iconAsset: 'assets/images/Items/Consumables/coin_doubler.png',
      isCollectible: false,
      type: 'currency_multiplier',
      effectData: {'multiplier': 2, 'duration': 3}, // 3 hours
      purchaseLimitPerPeriod: 1,
      purchasePeriodHours: 24, // 1x per day
    ),
    
    // Collectible rewards (can only be purchased once)
    Reward(
      name: 'Excalibur',
      description: 'A sword of kings, risen from a mysterious lake',
      cost: 450,
      iconAsset: 'assets/images/Items/Collectibles/excalibur.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Pirate Patch',
      description: 'A pirate\'s mark, covers an eye that never misses its prey',
      cost: 400,
      iconAsset: 'assets/images/Items/Collectibles/eyepatch.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Old Picture',
      description: 'A faded portrait that whispers forgotten tales',
      cost: 300,
      iconAsset: 'assets/images/Items/Collectibles/old_picture.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Antique Stopwatch',
      description: 'Said to glimpse moments yet to come',
      cost: 400,
      iconAsset: 'assets/images/Items/Collectibles/antique_stopwatch.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Lucky Coin',
      description: 'Whispers say luck follows those who carry this charm',
      cost: 300,
      iconAsset: 'assets/images/Items/Collectibles/lucky_coin.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Crystal Orb',
      description: 'A glowing orb said to hold the secrets of the unseen',
      cost: 450,
      iconAsset: 'assets/images/Items/Collectibles/magic_ball.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Warrior\'s Trophy',
      description: 'A symbol of victory, forged from sweat and valor',
      cost: 450,
      iconAsset: 'assets/images/Items/Collectibles/trophy.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Teddy Bear Doll',
      description: 'Once a gift of warmth, now a silent guardian',
      cost: 400,
      iconAsset: 'assets/images/Items/Collectibles/teddy_bear.png',
      isCollectible: true,
      type: 'collectible',
    ),
    Reward(
      name: 'Witch\'s Hat',
      description: 'Worn by witches, heavy with old magic',
      cost: 450,
      iconAsset: 'assets/images/Items/Collectibles/magic_hat.png',
      isCollectible: true,
      type: 'collectible',
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
        'purchaseLimitPerPeriod': purchaseLimitPerPeriod,
        'purchasePeriodHours': purchasePeriodHours,
        // purchaseCount and lastPurchaseTime removed from JSON as they are not static reward properties
      };

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      cost: json['cost'],
      type: json['type'],
      iconAsset: json['iconAsset'],
      isCollectible: json['isCollectible'] ?? false,
      effectData: json['effectData'],
      purchaseLimitPerPeriod: json['purchaseLimitPerPeriod'],
      purchasePeriodHours: json['purchasePeriodHours'],
      // purchaseCount and lastPurchaseTime removed from fromJson
    );
  }
}
