import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A custom card widget that has a wooden pixel art frame
class PixelCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  
  const PixelCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor,
    this.padding = AppTheme.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(AppTheme.woodBackgroundPath),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: child,
    );
  }
} 