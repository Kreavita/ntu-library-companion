import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String name;
  final String description;
  final Widget? child;
  final void Function() onTap;

  const SettingTile({
    super.key,
    required this.name,
    required this.description,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.apply(fontSizeDelta: -3),
                    overflow: TextOverflow.fade,
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.apply(
                      color: Theme.of(context).hintColor,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
