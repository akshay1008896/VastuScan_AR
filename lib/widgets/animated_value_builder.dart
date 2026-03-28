import 'package:flutter/material.dart';

/// A convenience wrapper around AnimatedWidget that takes a builder function.
/// 
/// This avoids the need for separate StatefulWidgets for simple animations.
/// Uses [AnimatedWidget] internally for efficient rebuilds.
class AnimatedValueBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedValueBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
