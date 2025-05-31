import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../providers/character_provider.dart';
import '../models/character.dart';
import '../widgets/character_display.dart'; // Import the display widget

class CharacterCustomizationScreen extends StatefulWidget {
  const CharacterCustomizationScreen({super.key});

  @override
  State<CharacterCustomizationScreen> createState() =>
      _CharacterCustomizationScreenState();
}

class _CharacterCustomizationScreenState extends State<CharacterCustomizationScreen> {
  // Local state to hold temporary changes before saving
  late Character _tempCharacter;

  /* // Temporarily disabled asset lists
  final List<String> _hairStyles = ['style1', 'style2', 'style3'];
  final List<String> _eyeStyles = ['default', 'wide', 'narrow'];
  final List<String> _clothingStyles = ['shirt1', 'shirt2', 'dress1'];
  */

  @override
  void initState() {
    super.initState();
    // Initialize temporary character with current provider state
    final initialCharacter = Provider.of<CharacterProvider>(context, listen: false).character;
    _tempCharacter = Character(
      gender: initialCharacter.gender,
      // skinColor: initialCharacter.skinColor, // Removed skinColor initialization
      // hairStyle: initialCharacter.hairStyle, // Disabled
      // hairColor: initialCharacter.hairColor, // Disabled
      // eyeStyle: initialCharacter.eyeStyle, // Disabled
      // eyeColor: initialCharacter.eyeColor, // Disabled
      // clothingStyle: initialCharacter.clothingStyle, // Disabled
      // clothingColor: initialCharacter.clothingColor, // Disabled
    );
  }

  void _showColorPicker(Function(Color) onColorChanged, Color initialColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onColorChanged,
            enableAlpha: false,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Character'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Save only the available temporary changes
              characterProvider.updateCharacter(_tempCharacter);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Top half: Preview
          Expanded(
            flex: 1, // Adjust flex as needed, maybe 1 for equal split or more for preview
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // Use the CharacterDisplay widget for preview
              child: CharacterDisplay(
                 character: _tempCharacter,
                 backgroundAsset: 'assets/images/backgrounds/farm.png' // Example background
              ),
            ),
          ),
          // Bottom half: Customization Options
          Expanded(
            flex: 1, // Adjust flex as needed, maybe 1 for equal split
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Body Section
                _buildSectionTitle('Body'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SegmentedButton<Gender>(
                    segments: const <ButtonSegment<Gender>>[
                      ButtonSegment<Gender>(
                        value: Gender.male,
                        icon: Icon(Icons.male),
                        label: Text('Male'),
                      ),
                      ButtonSegment<Gender>(
                        value: Gender.female,
                        icon: Icon(Icons.female),
                        label: Text('Female'),
                      ),
                    ],
                    selected: <Gender>{_tempCharacter.gender},
                    onSelectionChanged: (Set<Gender> newSelection) {
                      setState(() {
                        _tempCharacter.gender = newSelection.first;
                      });
                    },
                    multiSelectionEnabled: false,
                    emptySelectionAllowed: false,
                    showSelectedIcon: false,
                     style: SegmentedButton.styleFrom(),
                  ),
                ),

                /* // Removed Skin Color ListTile
                ListTile(
                  title: const Text('Skin Color'),
                  trailing: CircleAvatar(backgroundColor: _tempCharacter.skinColor),
                  onTap: () => _showColorPicker((color) {
                    setState(() => _tempCharacter.skinColor = color);
                  }, _tempCharacter.skinColor),
                ),
                */
                const Divider(),

                /* // Temporarily disabled Hair Section
                _buildSectionTitle('Hair'),
                _buildStyleSelector('Style', _hairStyles, _tempCharacter.hairStyle,
                    (style) => setState(() => _tempCharacter.hairStyle = style)),
                ListTile(
                  title: const Text('Color'),
                  trailing: CircleAvatar(backgroundColor: _tempCharacter.hairColor),
                  onTap: () => _showColorPicker((color) {
                    setState(() => _tempCharacter.hairColor = color);
                  }, _tempCharacter.hairColor),
                ),
                const Divider(),
                */

                /* // Temporarily disabled Eyes Section
                _buildSectionTitle('Eyes'),
                 _buildStyleSelector('Style', _eyeStyles, _tempCharacter.eyeStyle,
                    (style) => setState(() => _tempCharacter.eyeStyle = style)),
                ListTile(
                  title: const Text('Color'),
                  trailing: CircleAvatar(backgroundColor: _tempCharacter.eyeColor),
                  onTap: () => _showColorPicker((color) {
                    setState(() => _tempCharacter.eyeColor = color);
                  }, _tempCharacter.eyeColor),
                ),
                const Divider(),
                */

                /* // Temporarily disabled Clothing Section
                _buildSectionTitle('Clothing'),
                 _buildStyleSelector('Style', _clothingStyles, _tempCharacter.clothingStyle,
                    (style) => setState(() => _tempCharacter.clothingStyle = style)),
                 ListTile(
                  title: const Text('Color'),
                  trailing: CircleAvatar(backgroundColor: _tempCharacter.clothingColor),
                  onTap: () => _showColorPicker((color) {
                    setState(() => _tempCharacter.clothingColor = color);
                  }, _tempCharacter.clothingColor),
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  /* // Temporarily disabled style selector helper
  Widget _buildStyleSelector(
      String label, List<String> options, String currentSelection, ValueChanged<String> onChanged) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: currentSelection,
        items: options
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ))
            .toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
  */
} 