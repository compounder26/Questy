import 'package:flutter/material.dart';
import '../models/character.dart';

class CharacterProvider with ChangeNotifier {
  final Character _character = Character();

  Character get character => _character;

  void updateGender(Gender gender) {
    _character.gender = gender;
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
  void updateCharacter(Character newCharacterData) {
    _character.gender = newCharacterData.gender;
    /* // Temporarily disabled
    _character.hairStyle = newCharacterData.hairStyle;
    _character.hairColor = newCharacterData.hairColor;
    _character.eyeStyle = newCharacterData.eyeStyle;
    _character.eyeColor = newCharacterData.eyeColor;
    _character.clothingStyle = newCharacterData.clothingStyle;
    _character.clothingColor = newCharacterData.clothingColor;
    */
    notifyListeners();
  }
} 