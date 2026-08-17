import 'package:flutter/material.dart';

class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveFormContainer({super.key, required this.child, this.maxWidth = 420.0, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(width: double.infinity, padding: padding, child: child),
      ),
    );
  }
}
