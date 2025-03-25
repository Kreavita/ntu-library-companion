import 'package:flutter/material.dart';

class AccountTile extends StatelessWidget {
  final IconData icon;
  final void Function() onTap;
  final String name;
  final String value;

  const AccountTile({
    super.key,
    required this.icon,
    required this.onTap,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 5,
          children: [
            Icon(icon),
            Text(name),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                value,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
