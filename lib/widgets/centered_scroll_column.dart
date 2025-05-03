import 'package:flutter/material.dart';

/// Combination of Centered and SingleChildScrollView
class CenterScrollColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const CenterScrollColumn({
    super.key,
    this.spacing = 0.0,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: spacing,
          children: children,
        ),
      ),
    );
  }
}
