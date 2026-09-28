import 'package:flutter/material.dart';

class BouncingHeart extends StatefulWidget {
  const BouncingHeart({super.key});

  @override
  State<BouncingHeart> createState() => _BouncingHeartState();
}

class _BouncingHeartState extends State<BouncingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text(
            '🫂💖',
            style: TextStyle(
              fontSize: 80,
              fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji', 'Segoe UI Emoji'],
              shadows: [
                Shadow(
                  color: Color(0xFFFF4D6D),
                  blurRadius: 30,
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}
