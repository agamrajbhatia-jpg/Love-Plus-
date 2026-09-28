import 'dart:math' as math;
import 'package:flutter/material.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  
  const DynamicBackground({super.key, required this.child, this.colors});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(t * math.pi * 2), math.sin(t * math.pi * 2)),
              end: Alignment(-math.cos(t * math.pi * 2), -math.sin(t * math.pi * 2)),
              colors: widget.colors ?? const [
                Color(0xFFFFF0F5), // Soft pinkish white
                Color(0xFFE0F7FA), // Soft cyan
                Color(0xFFF3E5F5), // Soft purple
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
