import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<Color> gradientColors;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.gradientColors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFD700),
      Color(0xFFFF6B6B),
    ],
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating Gradient Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: SweepGradient(
                  center: Alignment.center,
                  colors: widget.gradientColors,
                  transform: GradientRotation(t * math.pi * 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),
        // Inner Content (makes the gradient look like a border)
        Padding(
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // Dark inner background
              borderRadius: BorderRadius.circular(
                widget.borderRadius.resolve(Directionality.of(context)).topLeft.x - widget.borderWidth,
              ),
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
