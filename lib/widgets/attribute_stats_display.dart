import 'package:flutter/material.dart';
import '../models/attribute_stats.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class AttributeStatsDisplay extends StatelessWidget {
  final User user;
  
  const AttributeStatsDisplay({
    super.key, 
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final stats = user.attributeStats;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: AppTheme.woodenFrameDecoration.copyWith(
        image: const DecorationImage(
          image: AssetImage(AppTheme.woodBackgroundPath),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level and EXP bar in one row
          _buildLevelAndExpBar(),
          const SizedBox(height: 6),
          
          // Attribute bars in a compact format
          _buildAttributeBar('H', 'Health', stats.health, stats.healthLevel),
          _buildAttributeBar('I', 'Intelligence', stats.intelligence, stats.intelligenceLevel),
          _buildAttributeBar('C', 'Cleanliness', stats.cleanliness, stats.cleanlinessLevel),
          _buildAttributeBar('C', 'Charisma', stats.charisma, stats.charismaLevel),
          _buildAttributeBar('U', 'Unity', stats.unity, stats.unityLevel),
          _buildAttributeBar('P', 'Power', stats.power, stats.powerLevel),
        ],
      ),
    );
  }

  Widget _buildLevelAndExpBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level and Star count in one row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Level indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.brown[900]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Text(
                'Level ${user.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            
            // Star count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${user.starCurrency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'assets/images/Items/star.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.star, color: Colors.amber, size: 20);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // Experience bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
            Text(
              '${user.exp}/${user.getExpNeededForNextLevel()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            // Background
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black45,
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Filled portion
            FractionallySizedBox(
              widthFactor: user.getLevelProgress().clamp(0.0, 1.0),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.amber.shade300,
                      Colors.amber.shade600,
                    ],
                  ),
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttributeBar(
    String shortName, 
    String fullName, 
    double value, 
    AttributeLevel level,
  ) {
    // Calculate percentage filled (max value for display purposes is 60)
    final double percentage = (value / 60.0).clamp(0.0, 1.0);
    final Color barColor = _getAttributeBarColor(shortName, fullName);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Attribute initial in box
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  border: Border.all(color: Colors.brown[900]!, width: 1),
                ),
                child: Text(
                  shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              
              // Level text
              Text(
                level.displayName,
                style: TextStyle(
                  color: _getLevelColor(level),
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Spacer(),
              
              // Value display
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PixelFont',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          
          // Progress bar (simplified)
          Stack(
            children: [
              // Background
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
              
              // Filled portion
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: barColor,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Get the specific color for each attribute bar
  Color _getAttributeBarColor(String shortName, String fullName) {
    if (shortName == 'H') return Colors.red.shade600; // Health - Red
    if (shortName == 'I') return Colors.blue.shade600; // Intelligence - Blue
    if (shortName == 'C') {
      if (fullName == 'Cleanliness') {
        return Colors.yellow.shade600; // Cleanliness - Yellow
      } else {
        return Colors.cyan.shade600; // Charisma - Cyan
      }
    }
    if (shortName == 'U') return Colors.green.shade600; // Unity - Green
    if (shortName == 'P') return Colors.purple.shade600; // Power - Purple
    return Colors.grey.shade500; // Default
  }
  
  // Get color based on attribute level
  Color _getLevelColor(AttributeLevel level) {
    switch (level) {
      case AttributeLevel.novice:
        return Colors.grey[400]!;
      case AttributeLevel.apprentice:
        return Colors.green[400]!;
      case AttributeLevel.adept:
        return Colors.blue[400]!;
      case AttributeLevel.expert:
        return Colors.purple[400]!;
      case AttributeLevel.master:
        return Colors.orange[400]!;
      case AttributeLevel.sage:
        return Colors.red[400]!;
    }
  }
} 