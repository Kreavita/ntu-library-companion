import 'package:flutter/material.dart';

// Source: https://homebakedcode.com/en/blog/flutter-outline-text
class OutlineText extends StatelessWidget {
  final Text child;
  final double strokeWidth;
  final Color? strokeColor;

  const OutlineText({
    super.key,
    // default storke width
    this.strokeWidth = 2,
    this.strokeColor,
    required this.child,
  });

  // Option: can add flags
  // e.g.) read a related state and globally apply if needed
  // final backgroundProvider = ref.watch(backgroundSelectProvider);
  // if (backgroundProvider.imagePath.isEmpty) {
  //   return child;
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // stroke text
        Text(
          // need to set text scale if needed
          textScaler: child.textScaler,
          child.data!,
          style: TextStyle(
            fontSize: child.style?.fontSize,
            fontWeight: child.style?.fontWeight,
            foreground:
                Paint()
                  ..color = strokeColor ?? Theme.of(context).colorScheme.surface
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth,
          ),
          overflow: child.overflow,
        ),
        // original text
        child,
      ],
    );
  }
}
