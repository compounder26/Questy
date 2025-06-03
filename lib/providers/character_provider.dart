import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/character.dart';
import '../models/background.dart';

class CharacterProvider extends ChangeNotifier {
  Character _character = Character.defaultCharacter();
  Background _selectedBackground = Background.availableBackgrounds[0]; // Default background
  int _backgroundId = 1; // Default background ID

  Character get character => _character;
  Background get selectedBackground => _selectedBackground;

  void updateGender(Gender gender) {
    _character = Character(
      gender: gender,
      variant: _character.variant,
    );
    notifyListeners();
  }

  /* // Temporarily disabled
  void updateHairStyle(String style) {
    _character.hairStyle = style;
    notifyListeners();
  }

  void updateHairColor(Color color) {
    _character.hairColor = color;
    notifyListeners();
  }

  void updateEyeStyle(String style) {
    _character.eyeStyle = style;
    notifyListeners();
  }

  void updateEyeColor(Color color) {
    _character.eyeColor = color;
    notifyListeners();
  }

  void updateClothingStyle(String style) {
    _character.clothingStyle = style;
    notifyListeners();
  }

  void updateClothingColor(Color color) {
    _character.clothingColor = color;
    notifyListeners();
  }
  */

  // Method to update multiple attributes at once if needed
  void updateCharacter(Character newCharacter) {
    _character = newCharacter;
    _saveCharacterPreferences();
    notifyListeners();
  }

  // Update just the background
  void updateBackground(Background newBackground) {
    _selectedBackground = newBackground;
    _backgroundId = newBackground.id;
    _saveBackgroundPreferences();
    notifyListeners();
  }

  // Initialize preferences - call in main or app startup
  Future<void> loadPreferences() async {
    try {
      // Get character preferences
      final prefs = Hive.box('preferences');
      final genderIndex = prefs.get('character_gender', defaultValue: 0) as int;
      final variant = prefs.get('character_variant', defaultValue: 1) as int;
      
      // Set character data
      _character = Character(
        gender: Gender.values[genderIndex],
        variant: variant,
      );
      
      // Get background preference
      final backgroundId = prefs.get('background_id', defaultValue: 1) as int;
      _backgroundId = backgroundId;
      
      _selectedBackground = Background.availableBackgrounds.firstWhere(
        (bg) => bg.id == backgroundId,
        orElse: () => Background.availableBackgrounds[0],
      );
      
      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
      // Continue with defaults
    }
  }

  // Save character preferences
  Future<void> _saveCharacterPreferences() async {
    try {
      final prefs = await Hive.openBox('preferences');
      await prefs.put('character_gender', _character.gender.index);
      await prefs.put('character_variant', _character.variant);
    } catch (e) {
      print('Error saving character preferences: $e');
    }
  }
  
  // Save background preferences
  Future<void> _saveBackgroundPreferences() async {
    try {
      final prefs = await Hive.openBox('preferences');
      await prefs.put('background_id', _backgroundId);
    } catch (e) {
      print('Error saving background preferences: $e');
    }
  }
} 