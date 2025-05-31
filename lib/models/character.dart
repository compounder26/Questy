
// Enum for gender clarity
enum Gender { male, female }

class Character {
  final Gender gender;
  final int variant; // Added variant property for different character appearances
  // Color skinColor; // Removed skinColor property
  // String hairStyle; // Identifier like 'style1', 'style2'
  // Color hairColor; // Actual color
  // String eyeStyle; // Identifier like 'default', 'wide'
  // Color eyeColor; // Actual color
  // String clothingStyle; // Identifier like 'shirt1', 'dress1'
  // Color clothingColor; // Actual color

  // We'll derive asset paths from these properties
  String get bodyAsset {
    // Ensure variant is not null, defaulting to 1 if it somehow is
    final safeVariant = variant > 0 ? variant : 1;
    
    // Variant-specific asset paths
    if (gender == Gender.male) {
      return 'assets/images/Character/male$safeVariant.png';
    } else {
      // Handle typo in femal1.png vs female naming
      return safeVariant == 1 
          ? 'assets/images/Character/femal1.png' 
          : 'assets/images/Character/female$safeVariant.png';
    }
  }
  
  // Get available variants for each gender
  static List<int> getVariantsForGender(Gender gender) {
    if (gender == Gender.male) {
      return [1, 2]; // Male variants
    } else {
      return [1, 2, 3, 4, 5]; // Female variants
    }
  }

  // Simple hair asset naming convention for now
  // String get hairAsset => 'assets/images/character/hair/${hairStyle}_${hairColor.value.toRadixString(16)}.png'; // Placeholder naming
  // String get eyeAsset => 'assets/images/character/eyes/${eyeStyle}_${eyeColor.value.toRadixString(16)}.png'; // Placeholder naming
  // String get clothingAsset => 'assets/images/character/clothes/${clothingStyle}_${clothingColor.value.toRadixString(16)}.png'; // Placeholder naming

  // Constructor with required values to prevent null
  const Character({
    required this.gender,
    required this.variant,
    // this.skinColor = const Color(0xFFE0AC69), // Removed default skin color
    // this.hairStyle = 'style1',
    // this.hairColor = Colors.black,
    // this.eyeStyle = 'default',
    // this.eyeColor = Colors.blue,
    // this.clothingStyle = 'shirt1',
    // this.clothingColor = Colors.red,
  });
  
  // Factory constructor with defaults
  factory Character.defaultCharacter() {
    return const Character(
      gender: Gender.male,
      variant: 1,
    );
  }
} 