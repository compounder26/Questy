import 'package:flutter/material.dart';

/// A collection of UI constants and theme settings for the pixel art style
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Asset paths
  static const String woodBackgroundPath =
      'assets/images/Accesories/wood bg.png';
  static const String borderFramePath =
      'assets/images/Accesories/ChatGPT Image May 20, 2025, 01_32_10 PM.png';
  static const String headerBackgroundPath =
      'assets/images/border/headerBackground.png';
  static const String checkboxPath = 'assets/images/border/checkkbox.png';
  static const String checkedBoxPath =
      'assets/images/border/checkkbox.png'; // Will need an actual checked version
  static const String appLogoPath = 'assets/images/appLogo.jpg';

  // Colors
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color lightWood = Color(0xFFDEB887);
  static const Color darkWood = Color(0xFF6D4C41);
  static const Color greenHighlight = Color(0xFF4CAF50);
  static const Color redHighlight = Color(0xFFF44336);
  static const Color blueHighlight = Color(0xFF2196F3);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2A2A2A);

  // Text styles
  static const TextStyle pixelHeadingStyle = TextStyle(
    fontFamily: 'ArcadeClassic',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black,
        offset: Offset(1, 1),
        blurRadius: 2,
      ),
    ],
  );

  static const TextStyle pixelBodyStyle = TextStyle(
    fontFamily: 'ArcadeClassic',
    fontSize: 16,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black54,
        offset: Offset(1, 1),
        blurRadius: 1,
      ),
    ],
  );

  // Decorations
  static BoxDecoration woodenFrameDecoration = BoxDecoration(
    image: const DecorationImage(
      image: AssetImage(woodBackgroundPath),
      fit: BoxFit.cover,
    ),
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(
      color: darkWood,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 5,
        offset: const Offset(2, 2),
      ),
    ],
  );

  // Paddings
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets contentPadding = EdgeInsets.all(8.0);
}
