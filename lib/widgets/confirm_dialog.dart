import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.confirmString,
  });

  final String title;
  final String content;
  final IconData icon;
  final String confirmString;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(textAlign: TextAlign.center, content),
      actions: [
        MaterialButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(confirmString),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}
