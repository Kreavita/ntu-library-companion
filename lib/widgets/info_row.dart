import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final Widget child;
  final IconData icon;
  const InfoRow({super.key, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Flexible(child: child),
        ],
      ),
    );
  }
}
