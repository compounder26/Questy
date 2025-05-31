import 'package:flutter/foundation.dart';

@immutable
class UserRewardPurchaseStatus {
  final String rewardId;
  final int purchaseCount;
  final DateTime? cooldownStartTime;

  const UserRewardPurchaseStatus({
    required this.rewardId,
    this.purchaseCount = 0,
    this.cooldownStartTime,
  });

  UserRewardPurchaseStatus copyWith({
    int? purchaseCount,
    DateTime? cooldownStartTime,
    bool setCooldownStartTimeToNull = false,
  }) {
    return UserRewardPurchaseStatus(
      rewardId: rewardId,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      cooldownStartTime: setCooldownStartTimeToNull ? null : cooldownStartTime ?? this.cooldownStartTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'purchaseCount': purchaseCount,
        'cooldownStartTime': cooldownStartTime?.toIso8601String(),
      };

  factory UserRewardPurchaseStatus.fromJson(Map<String, dynamic> json) {
    return UserRewardPurchaseStatus(
      rewardId: json['rewardId'] as String,
      purchaseCount: json['purchaseCount'] as int? ?? 0,
      cooldownStartTime: json['cooldownStartTime'] != null
          ? DateTime.parse(json['cooldownStartTime'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRewardPurchaseStatus &&
          runtimeType == other.runtimeType &&
          rewardId == other.rewardId &&
          purchaseCount == other.purchaseCount &&
          cooldownStartTime == other.cooldownStartTime;

  @override
  int get hashCode =>
      rewardId.hashCode ^
      purchaseCount.hashCode ^
      cooldownStartTime.hashCode;
}
