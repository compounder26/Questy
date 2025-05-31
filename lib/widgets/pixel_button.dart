import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A custom button widget that uses pixel art style
class PixelButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double? height;
  final EdgeInsetsGeometry padding;
  
  const PixelButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppTheme.primaryBrown,
    this.textColor = Colors.white,
    this.width = 140.0,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    
    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: widget.backgroundColor.withOpacity(isEnabled ? 1.0 : 0.5),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: Colors.black.withOpacity(0.5),
            width: 2.0,
          ),
          boxShadow: _isPressed || !isEnabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
          image: const DecorationImage(
            image: AssetImage(AppTheme.woodBackgroundPath),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        transform: _isPressed ? Matrix4.translationValues(2, 2, 0) : Matrix4.identity(),
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: TextStyle(
            color: widget.textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          child: widget.child,
        ),
      ),
    );
  }
} 