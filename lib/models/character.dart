import 'package:flutter/material.dart';

// Enum for gender clarity
enum Gender { male, female }

class Character {
  Gender gender;
  // Color skinColor; // Removed skinColor property
  // String hairStyle; // Identifier like 'style1', 'style2'
  // Color hairColor; // Actual color
  // String eyeStyle; // Identifier like 'default', 'wide'
  // Color eyeColor; // Actual color
  // String clothingStyle; // Identifier like 'shirt1', 'dress1'
  // Color clothingColor; // Actual color

  // We'll derive asset paths from these properties
  String get bodyAsset => 'assets/images/character/body/${gender.name}.png';
  // Simple hair asset naming convention for now
  // String get hairAsset => 'assets/images/character/hair/${hairStyle}_${hairColor.value.toRadixString(16)}.png'; // Placeholder naming
  // String get eyeAsset => 'assets/images/character/eyes/${eyeStyle}_${eyeColor.value.toRadixString(16)}.png'; // Placeholder naming
  // String get clothingAsset => 'assets/images/character/clothes/${clothingStyle}_${clothingColor.value.toRadixString(16)}.png'; // Placeholder naming


  Character({
    this.gender = Gender.male,
    // this.skinColor = const Color(0xFFE0AC69), // Removed default skin color
    // this.hairStyle = 'style1',
    // this.hairColor = Colors.black,
    // this.eyeStyle = 'default',
    // this.eyeColor = Colors.blue,
    // this.clothingStyle = 'shirt1',
    // this.clothingColor = Colors.red,
  });
} 