import 'dart:math';
import 'package:flutter/material.dart';

// --- Midnight Love Letter (Deep & Passionate) ---
class MidnightLoveLetterBackground extends StatefulWidget {
  final Widget child;
  const MidnightLoveLetterBackground({super.key, required this.child});
  @override
  State<MidnightLoveLetterBackground> createState() => _MidnightLoveLetterBackgroundState();
}

class _MidnightLoveLetterBackgroundState extends State<MidnightLoveLetterBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Petal> _petals = [];
  final Random _rnd = Random();

  final Paint _emberPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
  final Paint _petalPaint = Paint()..color = const Color(0x998B0000); // 0.6 opacity
  final Path _basePetalPath = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(1, 0, 0, 1)
    ..quadraticBezierTo(-1, 0, 0, -1);
  final List<Color> _emberColors = List.generate(256, (i) => Color.fromARGB(i, 255, 69, 0));

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _petals.add(_Petal(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        speed: 0.1 + _rnd.nextDouble() * 0.2,
        size: 8 + _rnd.nextDouble() * 12,
        amplitude: 10 + _rnd.nextDouble() * 30,
        phase: _rnd.nextDouble() * pi * 2,
        rotationSpeed: (_rnd.nextDouble() - 0.5) * pi,
      ));
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0410), Color(0xFF000000)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(painter: _PetalAndEmberPainter(_petals, _controller.value, _emberPaint, _petalPaint, _basePetalPath, _emberColors));
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Petal {
  double x, y, speed, size, amplitude, phase, rotationSpeed;
  _Petal({required this.x, required this.y, required this.speed, required this.size, required this.amplitude, required this.phase, required this.rotationSpeed});
}

class _PetalAndEmberPainter extends CustomPainter {
  final List<_Petal> petals;
  final double progress;
  final Paint emberPaint;
  final Paint petalPaint;
  final Path basePetalPath;
  final List<Color> emberColors;
  _PetalAndEmberPainter(this.petals, this.progress, this.emberPaint, this.petalPaint, this.basePetalPath, this.emberColors);

  @override
  void paint(Canvas canvas, Size size) {
    // Embers
    double emberOpacity = (sin(progress * pi * 8) + 1) / 2 * 0.4 + 0.2;
    int opacityIndex = (emberOpacity * 255).clamp(0, 255).toInt();
    emberPaint.color = emberColors[opacityIndex];
    
    canvas.drawCircle(Offset(size.width * 0.2, size.height + 20), 100, emberPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height + 20), 80, emberPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height + 50), 120, emberPaint);

    // Petals
    for (var p in petals) {
      double py = p.y + (progress * p.speed);
      if (py > 1.1) p.y -= 1.2;
      double px = p.x * size.width + sin(progress * pi * 4 + p.phase) * p.amplitude;
      double yPos = (py % 1.0) * size.height;
      
      canvas.save();
      canvas.translate(px, yPos);
      canvas.rotate(progress * p.rotationSpeed * 10);
      canvas.scale(p.size);
      
      canvas.drawPath(basePetalPath, petalPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- Written in the Stars (Dreamy & Cosmic) ---
class WrittenInTheStarsBackground extends StatefulWidget {
  final Widget child;
  const WrittenInTheStarsBackground({super.key, required this.child});
  @override
  State<WrittenInTheStarsBackground> createState() => _WrittenInTheStarsBackgroundState();
}

class _WrittenInTheStarsBackgroundState extends State<WrittenInTheStarsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final Random _rnd = Random();

  final Paint _starPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  final Paint _linePaint = Paint()..strokeWidth = 1.0..style = PaintingStyle.stroke;
  final Paint _shootPaint = Paint()..strokeWidth = 2.0..strokeCap = StrokeCap.round;
  final Paint _dotPaint = Paint();
  final List<Color> _starColors = List.generate(256, (i) => Color.fromARGB(i, 255, 255, 255));
  final Path _heartPath = Path();
  late List<Offset> _heartPoints;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) { // Capped to 20
      _stars.add(_Star(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        size: 1 + _rnd.nextDouble() * 2.5,
        twinkleSpeed: 2 + _rnd.nextDouble() * 5,
        phase: _rnd.nextDouble() * pi * 2,
      ));
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    double cx = MediaQuery.of(context).size.width / 2;
    double cy = MediaQuery.of(context).size.height / 3;
    _heartPoints = [
      Offset(cx, cy - 20),
      Offset(cx + 30, cy - 40),
      Offset(cx + 60, cy - 10),
      Offset(cx, cy + 50),
      Offset(cx - 60, cy - 10),
      Offset(cx - 30, cy - 40),
    ];
    _heartPath.moveTo(_heartPoints[0].dx, _heartPoints[0].dy);
    for (int i = 1; i < _heartPoints.length; i++) {
      _heartPath.lineTo(_heartPoints[i].dx, _heartPoints[i].dy);
    }
    _heartPath.close();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF150524), Color(0xFF000000)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(painter: _StarPainter(_stars, _controller.value, _starPaint, _linePaint, _shootPaint, _dotPaint, _starColors, _heartPath, _heartPoints));
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  double x, y, size, twinkleSpeed, phase;
  _Star({required this.x, required this.y, required this.size, required this.twinkleSpeed, required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final Paint starPaint;
  final Paint linePaint;
  final Paint shootPaint;
  final Paint dotPaint;
  final List<Color> starColors;
  final Path heartPath;
  final List<Offset> heartPoints;
  _StarPainter(this.stars, this.progress, this.starPaint, this.linePaint, this.shootPaint, this.dotPaint, this.starColors, this.heartPath, this.heartPoints);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stars
    for (var s in stars) {
      double opacity = (sin(progress * pi * s.twinkleSpeed + s.phase) + 1) / 2 * 0.8 + 0.2;
      int idx = (opacity * 255).clamp(0, 255).toInt();
      starPaint.color = starColors[idx];
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, starPaint);
    }

    // Heart Constellation
    double constelOpacity = (sin(progress * pi * 2) + 1) / 2 * 0.4;
    int lineIdx = (constelOpacity * 255).clamp(0, 255).toInt();
    linePaint.color = starColors[lineIdx];
    canvas.drawPath(heartPath, linePaint);
    
    int dotIdx = ((constelOpacity + 0.4).clamp(0.0, 1.0) * 255).toInt();
    dotPaint.color = starColors[dotIdx];
    for (var p in heartPoints) {
      canvas.drawCircle(p, 3.0, dotPaint);
    }

    // Shooting Star
    if (progress > 0.5 && progress < 0.6) {
      double t = (progress - 0.5) * 10;
      double sx = size.width - (t * size.width * 1.5);
      double sy = t * size.height * 0.8;
      
      int shootIdx = ((1 - t).clamp(0.0, 1.0) * 255).toInt();
      shootPaint.color = starColors[shootIdx];
      canvas.drawLine(Offset(sx, sy), Offset(sx + 80, sy - 40), shootPaint);
      
      dotPaint.color = starColors[255];
      canvas.drawCircle(Offset(sx, sy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- Neon Heartbeat (Modern & Moody) ---
class NeonHeartbeatBackground extends StatefulWidget {
  final Widget child;
  const NeonHeartbeatBackground({super.key, required this.child});
  @override
  State<NeonHeartbeatBackground> createState() => _NeonHeartbeatBackgroundState();
}

class _NeonHeartbeatBackgroundState extends State<NeonHeartbeatBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WireHeart> _hearts = [];
  final Random _rnd = Random();

  final Paint _cyanPaint = Paint()..color = const Color(0x6600FFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
  final Paint _pinkPaint = Paint()..color = const Color(0x66FF1493)..style = PaintingStyle.stroke..strokeWidth = 1.5..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
  final Path _baseHeartPath = Path()
    ..moveTo(0, 0.25)
    ..cubicTo(-1, -0.5, -0.5, -1, 0, -0.33)
    ..cubicTo(0.5, -1, 1, -0.5, 0, 0.25);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) { // Capped to 15
      _hearts.add(_WireHeart(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        speed: 0.1 + _rnd.nextDouble() * 0.2,
        size: 20 + _rnd.nextDouble() * 40,
        isCyan: _rnd.nextBool(),
      ));
    }
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020A1A), Color(0xFF000000)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(painter: _WireHeartPainter(_hearts, _controller.value, _cyanPaint, _pinkPaint, _baseHeartPath));
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _WireHeart {
  double x, y, speed, size;
  bool isCyan;
  _WireHeart({required this.x, required this.y, required this.speed, required this.size, required this.isCyan});
}

class _WireHeartPainter extends CustomPainter {
  final List<_WireHeart> hearts;
  final double progress;
  final Paint cyanPaint;
  final Paint pinkPaint;
  final Path baseHeartPath;
  _WireHeartPainter(this.hearts, this.progress, this.cyanPaint, this.pinkPaint, this.baseHeartPath);

  @override
  void paint(Canvas canvas, Size size) {
    double pulse = 1.0 + (sin(progress * pi * 16) > 0.8 ? 0.05 : 0.0);

    for (var h in hearts) {
      double py = h.y - (progress * h.speed);
      if (py < -0.2) h.y += 1.4;
      double px = h.x * size.width;
      double yPos = (py % 1.0) * size.height;
      
      canvas.save();
      canvas.translate(px, yPos);
      canvas.scale(pulse * h.size);
      
      canvas.drawPath(baseHeartPath, h.isCyan ? cyanPaint : pinkPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- Animated Bubble Pop ---
class AnimatedBubblePop extends StatefulWidget {
  final Widget child;
  const AnimatedBubblePop({super.key, required this.child});
  @override
  State<AnimatedBubblePop> createState() => _AnimatedBubblePopState();
}

class _AnimatedBubblePopState extends State<AnimatedBubblePop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
