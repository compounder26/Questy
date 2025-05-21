import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A custom checkbox widget that uses pixel art images
class PixelCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  
  const PixelCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    
    return GestureDetector(
      onTap: isEnabled 
          ? () => onChanged?.call(!value) 
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base checkbox image
          Image.asset(
            AppTheme.checkboxPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          
          // Green checkmark when selected
          if (value)
            Center(
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: AppTheme.greenHighlight,
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          
          // Disabled overlay
          if (!isEnabled)
            Container(
              width: size,
              height: size,
              color: Colors.black.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
} 