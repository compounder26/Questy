import 'package:flutter/material.dart';

/// Model for character attribute stats following the HICCUP system
class AttributeStats {
  // Primary HICCUP attributes
  double health;
  double intelligence;
  double cleanliness;
  double charisma;
  double unity;
  double power;
  
  // Level information for each attribute
  AttributeLevel healthLevel;
  AttributeLevel intelligenceLevel;
  AttributeLevel cleanlinessLevel;
  AttributeLevel charismaLevel;
  AttributeLevel unityLevel;
  AttributeLevel powerLevel;

  AttributeStats({
    this.health = 0.0,
    this.intelligence = 0.0,
    this.cleanliness = 0.0,
    this.charisma = 0.0,
    this.unity = 0.0,
    this.power = 0.0,
    AttributeLevel? healthLevel,
    AttributeLevel? intelligenceLevel,
    AttributeLevel? cleanlinessLevel,
    AttributeLevel? charismaLevel,
    AttributeLevel? unityLevel,
    AttributeLevel? powerLevel,
  }) : 
    healthLevel = healthLevel ?? AttributeLevel.novice,
    intelligenceLevel = intelligenceLevel ?? AttributeLevel.novice,
    cleanlinessLevel = cleanlinessLevel ?? AttributeLevel.novice,
    charismaLevel = charismaLevel ?? AttributeLevel.novice,
    unityLevel = unityLevel ?? AttributeLevel.novice,
    powerLevel = powerLevel ?? AttributeLevel.novice;

  // Get total stats value (useful for overall strength calculation)
  double get totalValue => health + intelligence + cleanliness + charisma + unity + power;

  // Helper method to get a specific attribute value by name
  double getAttributeValue(String attributeName) {
    switch (attributeName.toLowerCase()) {
      case 'health': return health;
      case 'intelligence': return intelligence;
      case 'cleanliness': return cleanliness;
      case 'charisma': return charisma;
      case 'unity': return unity;
      case 'power': return power;
      default: return 0.0;
    }
  }

  // Helper method to increase a specific attribute
  void increaseAttribute(String attributeName, double amount) {
    switch (attributeName.toLowerCase()) {
      case 'health': 
        health += amount;
        checkAndUpdateLevel(attributeName);
        break;
      case 'intelligence': 
        intelligence += amount;
        checkAndUpdateLevel(attributeName);
        break;
      case 'cleanliness': 
        cleanliness += amount;
        checkAndUpdateLevel(attributeName);
        break;
      case 'charisma': 
        charisma += amount;
        checkAndUpdateLevel(attributeName);
        break;
      case 'unity': 
        unity += amount;
        checkAndUpdateLevel(attributeName);
        break;
      case 'power': 
        power += amount;
        checkAndUpdateLevel(attributeName);
        break;
    }
  }

  // Check and update the level for a given attribute
  void checkAndUpdateLevel(String attributeName) {
    final double value = getAttributeValue(attributeName);
    AttributeLevel newLevel;
    
    // Determine new level based on attribute value
    if (value >= 50) {
      newLevel = AttributeLevel.sage;
    } else if (value >= 40) {
      newLevel = AttributeLevel.master;
    } else if (value >= 30) {
      newLevel = AttributeLevel.expert;
    } else if (value >= 20) {
      newLevel = AttributeLevel.adept;
    } else if (value >= 10) {
      newLevel = AttributeLevel.apprentice;
    } else {
      newLevel = AttributeLevel.novice;
    }
    
    // Update appropriate level
    switch (attributeName.toLowerCase()) {
      case 'health': healthLevel = newLevel; break;
      case 'intelligence': intelligenceLevel = newLevel; break;
      case 'cleanliness': cleanlinessLevel = newLevel; break;
      case 'charisma': charismaLevel = newLevel; break;
      case 'unity': unityLevel = newLevel; break;
      case 'power': powerLevel = newLevel; break;
    }
  }

  // Get color for a specific attribute
  Color getAttributeColor(String attributeName) {
    switch (attributeName.toLowerCase()) {
      case 'health': return Colors.red;
      case 'intelligence': return Colors.blue;
      case 'cleanliness': return Colors.yellow;
      case 'charisma': return Colors.cyan;
      case 'unity': return Colors.green;
      case 'power': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Convert to JSON format for storage
  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'intelligence': intelligence,
      'cleanliness': cleanliness,
      'charisma': charisma,
      'unity': unity,
      'power': power,
      'healthLevel': healthLevel.index,
      'intelligenceLevel': intelligenceLevel.index,
      'cleanlinessLevel': cleanlinessLevel.index,
      'charismaLevel': charismaLevel.index,
      'unityLevel': unityLevel.index,
      'powerLevel': powerLevel.index,
    };
  }

  // Create from JSON for retrieval
  factory AttributeStats.fromJson(Map<String, dynamic> json) {
    return AttributeStats(
      health: json['health'] ?? 0.0,
      intelligence: json['intelligence'] ?? 0.0,
      cleanliness: json['cleanliness'] ?? 0.0,
      charisma: json['charisma'] ?? 0.0,
      unity: json['unity'] ?? 0.0,
      power: json['power'] ?? 0.0,
      healthLevel: AttributeLevel.values[json['healthLevel'] ?? 0],
      intelligenceLevel: AttributeLevel.values[json['intelligenceLevel'] ?? 0],
      cleanlinessLevel: AttributeLevel.values[json['cleanlinessLevel'] ?? 0],
      charismaLevel: AttributeLevel.values[json['charismaLevel'] ?? 0],
      unityLevel: AttributeLevel.values[json['unityLevel'] ?? 0],
      powerLevel: AttributeLevel.values[json['powerLevel'] ?? 0],
    );
  }
}

/// Enum for attribute levels
enum AttributeLevel {
  novice,      // Starting level
  apprentice,  // Basic proficiency
  adept,       // Competent understanding
  expert,      // High skill level
  master,      // Near-complete mastery
  sage         // Ultimate mastery
}

/// Extension to get string representation of attribute levels
extension AttributeLevelExtension on AttributeLevel {
  String get displayName {
    switch (this) {
      case AttributeLevel.novice: return 'Novice';
      case AttributeLevel.apprentice: return 'Apprentice';
      case AttributeLevel.adept: return 'Adept';
      case AttributeLevel.expert: return 'Expert';
      case AttributeLevel.master: return 'Master';
      case AttributeLevel.sage: return 'Sage';
    }
  }
} 