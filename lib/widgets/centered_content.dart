import 'package:flutter/material.dart';

class CenterContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const CenterContent({super.key, required this.child, this.maxWidth = 600.0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        height: double.infinity,
        child: child,
      ),
    );
  }
}
