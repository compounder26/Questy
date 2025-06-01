import 'package:flutter/material.dart';
import '../models/attribute_stats.dart';
import '../theme/app_theme.dart';

class ActiveEffectsDisplay extends StatelessWidget {
  final AttributeStats stats;

  const ActiveEffectsDisplay({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activeEffects = [];

    // Check for currency multiplier
    if (stats.isCurrencyMultiplierActive) {
      activeEffects.add({
        'name': 'Coin Doubler',
        'multiplier': stats.currencyMultiplier,
        'remainingMinutes': stats.currencyMultiplierRemainingMinutes,
        'color': Colors.amber,
        'icon': 'assets/images/Items/Consumables/coin_doubler.png',
      });
    }

    // Check for focus mode
    if (stats.isFocusModeActive) {
      activeEffects.add({
        'name': 'Focus Mode',
        'multiplier': stats.focusModeMultiplier,
        'remainingMinutes': stats.focusModeRemainingMinutes,
        'color': Colors.blue,
        'icon': 'assets/images/Items/Consumables/focus_booster.png',
      });
    }

    if (activeEffects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkWood, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: activeEffects.map((effect) {
          final minutes = effect['remainingMinutes'] as int?;
          final hours = minutes != null ? minutes ~/ 60 : 0;
          final remainingMinutes = minutes != null ? minutes % 60 : 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  effect['icon'] as String,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.star,
                    color: effect['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${hours}h${remainingMinutes}m',
                  style: TextStyle(
                    color: effect['color'] as Color,
                    fontFamily: 'PixelFont',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
} 