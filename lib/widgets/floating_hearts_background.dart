import 'dart:math';
import 'package:flutter/material.dart';

class FloatingHeartsBackground extends StatefulWidget {
  final Widget child;
  final double opacityMultiplier;

  const FloatingHeartsBackground({
    super.key, 
    required this.child, 
    this.opacityMultiplier = 1.0,
  });

  @override
  State<FloatingHeartsBackground> createState() => _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_Heart> _hearts = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize random hearts
    for (int i = 0; i < 15; i++) {
      _hearts.add(_Heart(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.1 + _random.nextDouble() * 0.2,
        size: 10 + _random.nextDouble() * 20,
        opacityOffset: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HeartsPainter(hearts: _hearts, progress: _controller.value, opacityMultiplier: widget.opacityMultiplier),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Heart {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double opacityOffset;

  _Heart({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacityOffset,
  });
}

class _HeartsPainter extends CustomPainter {
  final List<_Heart> hearts;
  final double progress;
  final double opacityMultiplier;

  _HeartsPainter({required this.hearts, required this.progress, required this.opacityMultiplier});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var heart in hearts) {
      // Calculate continuous upward movement
      double currentY = (heart.y - (progress * heart.speed)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Gentle horizontal swaying
      double currentX = heart.x + sin((progress * pi * 4) + heart.opacityOffset) * 0.02;
      
      // Pulsing opacity
      double opacity = (0.2 + sin((progress * pi * 4) + heart.opacityOffset) * 0.2) * opacityMultiplier;
      paint.color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));

      _drawHeart(
        canvas, 
        paint, 
        currentX * size.width, 
        currentY * size.height, 
        heart.size,
      );
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    path.moveTo(x, y + size / 4);
    path.cubicTo(
      x - size, y - size / 2, 
      x - size / 2, y - size, 
      x, y - size / 3
    );
    path.cubicTo(
      x + size / 2, y - size, 
      x + size, y - size / 2, 
      x, y + size / 4
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) => true;
}
