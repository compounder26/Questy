// Placeholder for the CharacterDisplay widget we will create
import 'package:flutter/material.dart';
// Removed dart:async as Timer is no longer used
import '../models/character.dart'; // Import the Character model
import '../models/background.dart'; // Import the Background model

// Define base dimensions for the character sprite
const double _baseCharacterWidth = 120.0; // Increased for actual character images
const double _baseCharacterHeight = 150.0; // Increased for actual character images
// Define a multiplier for the display size
const double _displaySizeMultiplier = 2.0; // Adjusted multiplier

class CharacterDisplay extends StatefulWidget {
  final Character character;
  final bool animate;
  final String? backgroundAsset; // Optional specific background path
  final Background? background; // Optional background model

  const CharacterDisplay({
    super.key,
    required this.character,
    this.animate = false,
    this.backgroundAsset, // Made optional
    this.background, // Added background model
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
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  // Helper to load character images
  Widget _buildCharacterImage(String assetPath) {
    const displayWidth = _baseCharacterWidth * _displaySizeMultiplier;
    const displayHeight = _baseCharacterHeight * _displaySizeMultiplier;

    return Image.asset(
      assetPath,
      width: displayWidth,
      height: displayHeight,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high, // Changed to high for detailed character images
      errorBuilder: (context, error, stackTrace) {
        print("Error loading asset: $assetPath\n$error");
        // Placeholder if image fails
        return Container(
          width: displayWidth,
          height: displayHeight,
          color: Colors.grey[300],
          child: const Center(child: Text('Character image not found', style: TextStyle(color: Colors.red)))
        );
      },
    );
  }

  // Get the background asset path
  String get _effectiveBackgroundAsset {
    // Priority: explicit backgroundAsset > background model > default
    if (widget.backgroundAsset != null) {
      return widget.backgroundAsset!;
    } else if (widget.background != null) {
      return widget.background!.assetPath;
    }
    return 'assets/images/Background/pemandangan1.png'; // Default background
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder for smooth animation
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentOffset = widget.animate ? _animation.value : 0.0;

        return Container(
          // Background Image
          decoration: BoxDecoration(
            // Add fallback color in case background image fails
            color: Colors.grey[200],
            image: DecorationImage(
              image: AssetImage(_effectiveBackgroundAsset),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high, // Changed to high for detailed backgrounds
              onError: (error, stackTrace) {
                print("Error loading background: $_effectiveBackgroundAsset\n$error");
              }
            ),
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(currentOffset, 0), // Apply animation offset
              child: _buildCharacterImage(widget.character.bodyAsset),
            ),
          ),
        );
      },
    );
  }
} 