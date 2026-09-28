import 'package:flutter/material.dart';

class PulsingNeonBorder extends StatefulWidget {
  final Widget child;
  
  const PulsingNeonBorder({super.key, required this.child});

  @override
  State<PulsingNeonBorder> createState() => _PulsingNeonBorderState();
}

class _PulsingNeonBorderState extends State<PulsingNeonBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26), // Match inner GlassContainer roughly
            border: Border.all(
              color: const Color(0xFFEC4899).withOpacity(_opacityAnimation.value), // pink-500
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.9 * _opacityAnimation.value),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
