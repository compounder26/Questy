import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import flutter_animate
import '../providers/character_provider.dart';
import '../models/character.dart';
import '../models/background.dart';
import '../widgets/character_display.dart'; // Import the display widget
import '../theme/app_theme.dart';

class CharacterCustomizationScreen extends StatefulWidget {
  const CharacterCustomizationScreen({super.key});

  @override
  State<CharacterCustomizationScreen> createState() =>
      _CharacterCustomizationScreenState();
}

class _CharacterCustomizationScreenState extends State<CharacterCustomizationScreen> {
  // Local state to hold temporary changes before saving
  late Character _tempCharacter;
  late Background _tempBackground;
  late int _currentGenderTabIndex;

  @override
  void initState() {
    super.initState();
    // Initialize temporary character and background with current provider state
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    _tempCharacter = Character(
      gender: characterProvider.character.gender,
      variant: characterProvider.character.variant,
    );
    _tempBackground = characterProvider.selectedBackground;
    _currentGenderTabIndex = _tempCharacter.gender == Gender.male ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/appLogo.jpg',
                height: 32,
                width: 32,
              ),
            ),
            const Text('Customize Character'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Save changes
              characterProvider.updateCharacter(_tempCharacter);
              characterProvider.updateBackground(_tempBackground);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Top half: Preview with selected background
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CharacterDisplay(
                character: _tempCharacter,
                background: _tempBackground,
                animate: true,
                showInventoryButton: false, // Hide inventory button in customization screen
              ),
            ),
          ),
          // Bottom half: Character selection tabs
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2, // Two tabs: Male and Female
              initialIndex: _currentGenderTabIndex,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.male),
                        text: 'Male',
                      ),
                      Tab(
                        icon: Icon(Icons.female),
                        text: 'Female',
                      ),
                    ],
                    onTap: (index) {
                      setState(() {
                        _currentGenderTabIndex = index;
                        _tempCharacter = Character(
                          gender: index == 0 ? Gender.male : Gender.female,
                          variant: 1, // Reset to first variant when switching gender
                        );
                      });
                    },
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe
                      children: [
                        // Male Characters Tab
                        _buildCharacterGrid(Gender.male),
                        
                        // Female Characters Tab
                        _buildCharacterGrid(Gender.female),
                      ],
                    ),
                  ),
                  
                  // Background selection section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Background',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: Background.availableBackgrounds.length,
                            itemBuilder: (context, index) {
                              final background = Background.availableBackgrounds[index];
                              final isSelected = _tempBackground.id == background.id;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tempBackground = background;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.asset(
                                      background.assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build character selection grid
  Widget _buildCharacterGrid(Gender gender) {
    // Get variants for this gender
    final List<int> variants = Character.getVariantsForGender(gender);
    
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        final isSelected = _tempCharacter.gender == gender && _tempCharacter.variant == variant;
        
        // Create a temporary character for this grid item
        final gridCharacter = Character(gender: gender, variant: variant);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _tempCharacter = gridCharacter;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            ),
            child: Column(
              children: [
                Expanded(
                  child: CharacterDisplay(
                    character: gridCharacter,
                    animate: isSelected,
                    showInventoryButton: false, // Hide inventory button in grid items
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${gender.name.toUpperCase()} $variant',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 