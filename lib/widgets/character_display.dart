// Placeholder for the CharacterDisplay widget we will create
import 'package:flutter/material.dart';
// Removed dart:async as Timer is no longer used
import '../models/character.dart'; // Import the Character model

// Define base dimensions for the character sprite
const double _baseCharacterWidth = 32.0;
const double _baseCharacterHeight = 48.0;
// Define a multiplier for the display size
const double _displaySizeMultiplier = 6.0; // Adjust this value to change character size

class CharacterDisplay extends StatefulWidget {
  final Character character;
  final bool animate;
  final String backgroundAsset; // e.g., 'assets/images/backgrounds/farm.png'
  // Removed characterScale property

  const CharacterDisplay({
    super.key,
    required this.character,
    this.animate = false,
    this.backgroundAsset = 'assets/images/backgrounds/default.png',
    // Removed characterScale = 2.0
  });

  @override
  State<CharacterDisplay> createState() => _CharacterDisplayState();
}

class _CharacterDisplayState extends State<CharacterDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation; // Keep this for horizontal movement

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Keep duration
      vsync: this,
    );

    // Keep tween values for animation movement
    _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation based on initial widget.animate state
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

 @override
  void didUpdateWidget(covariant CharacterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in the animate flag
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (!_controller.isAnimating) {
          _controller.repeat(reverse: true);
        }
      } else {
        if (_controller.isAnimating) {
          _controller.stop(canceled: false);
        }
      }
    }

    // Handle potential character changes
    if (widget.character != oldWidget.character) {
      setState(() {}); // Ensure rebuild if necessary
    }

    // No longer need to check for scale changes
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  // Helper to load images with placeholder - removed scale parameter
  Widget _buildImageLayer(String assetPath) {
    final displayWidth = _baseCharacterWidth * _displaySizeMultiplier;
    final displayHeight = _baseCharacterHeight * _displaySizeMultiplier;

    // Use a colored container as placeholder if image fails
    Image image = Image.asset(
        assetPath,
        width: displayWidth,   // Set explicit width
        height: displayHeight, // Set explicit height
        fit: BoxFit.contain, // Adjust fit as needed
        filterQuality: FilterQuality.none, // Crucial for pixel art
         errorBuilder: (context, error, stackTrace) {
           print("Error loading asset: $assetPath\n$error");
          // Placeholder if image fails
          return Container(
            width: displayWidth, // Use calculated display width
            height: displayHeight, // Use calculated display height
            color: Colors.grey[300], // Use a default placeholder color
             child: Center(child: Text('?', style: TextStyle(color: Colors.red))) // Indicate missing asset
           );
         },
      );

    return image;
  }


  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder for smooth animation
    return AnimatedBuilder(
      animation: _controller, // Animate based on controller
      builder: (context, child) {
        final currentOffset = widget.animate ? _animation.value : 0.0;

        return Container(
          // Background Image
          decoration: BoxDecoration(
             // Add fallback color in case background image fails
             color: Colors.grey[200], // Example fallback color
            image: DecorationImage(
              image: AssetImage(widget.backgroundAsset),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              onError: (error, stackTrace) {
                 print("Error loading background: ${widget.backgroundAsset}\n$error");
                 // Consider adding setState here if background failure needs UI update
              }
            ),
          ),
          // Add the Center widget back
          child: Center(
            child: Transform.translate(
              offset: Offset(currentOffset, 0), // Apply animation offset
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Body - No scale passed now
                  _buildImageLayer(widget.character.bodyAsset),

                  /* // Temporarily disable layers without assets
                  _buildImageLayer(widget.character.clothingAsset),
                  _buildImageLayer(widget.character.eyeAsset),
                  _buildImageLayer(widget.character.hairAsset),
                  */
                ],
              ),
            ),
          ), // End added Center
        );
      },
    );
  }
} 