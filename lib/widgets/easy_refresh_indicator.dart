import 'package:flutter/material.dart';

class EasyRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Key? refreshKey;
  final Widget child;

  const EasyRefreshIndicator({
    super.key,
    required this.onRefresh,
    this.refreshKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          key: refreshKey,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(height: constraints.maxHeight, child: child),
          ),
        );
      },
    );
  }
}
