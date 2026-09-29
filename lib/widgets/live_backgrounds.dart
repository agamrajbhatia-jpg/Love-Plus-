import 'package:material_ui/material_ui.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

// --- Theme Enum ---
enum PetTheme { rosePetal, cottonCandy, cherryBlossom, neonHeart }

// --- Wrapper for chosen live background ---
class LiveBackground extends StatelessWidget {
  final PetTheme theme;
  const LiveBackground({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    switch (theme) {
      case PetTheme.rosePetal:
        return const RosePetalCloudBackground();
      case PetTheme.cottonCandy:
        return const CottonCandySunsetBackground();
      case PetTheme.cherryBlossom:
        return const CherryBlossomHavenBackground();
      case PetTheme.neonHeart:
        return const NeonHeartbeatBackground();
    }
  }
}

// ==========================================
// 1. Rose Petal Cloud
// ==========================================
class RosePetalCloudBackground extends StatefulWidget {
  const RosePetalCloudBackground({super.key});
  @override
  State<RosePetalCloudBackground> createState() => _RosePetalCloudBackgroundState();
}

class _RosePetalCloudBackgroundState extends State<RosePetalCloudBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Petal> _petals = [];
  final Random _random = Random();
  Offset _touchPos = const Offset(-1000, -1000);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      _petals.add(_Petal(
        x: _random.nextDouble() * 500,
        y: _random.nextDouble() * 1000,
        rotation: _random.nextDouble() * pi * 2,
        size: _random.nextDouble() * 8 + 6,
        isWhite: _random.nextBool(),
      ));
    }
    _ticker = createTicker((elapsed) {
      setState(() {
        for (var p in _petals) {
          p.update(_touchPos);
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _touchPos = details.localPosition,
      onPanEnd: (_) => _touchPos = const Offset(-1000, -1000),
      onTapDown: (details) => _touchPos = details.localPosition,
      onTapUp: (_) => _touchPos = const Offset(-1000, -1000),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomPaint(
          painter: _RosePetalPainter(_petals),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Petal {
  double x, y;
  double vx = 0, vy = 1.0; 
  double rotation;
  double rotSpeed;
  double size;
  bool isWhite;
  
  _Petal({required this.x, required this.y, required this.rotation, required this.size, required this.isWhite}) 
    : rotSpeed = (Random().nextDouble() - 0.5) * 0.1;

  void update(Offset touchPos) {
    rotation += rotSpeed;
    vx = sin(y / 50.0) * 1.0;

    double dx = x - touchPos.dx;
    double dy = y - touchPos.dy;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 150 && touchPos.dx > 0) {
      double force = (150 - dist) / 150;
      vx += (dx / dist) * force * 5;
      vy += (dy / dist) * force * 5;
    } else {
      vy = vy + (1.2 - vy) * 0.1;
    }

    x += vx;
    y += vy;
    
    if (x < -20) x = 500;
    if (x > 520) x = 0;
    if (y > 1000) y = -20;
    if (y < -20) y = 1000;
  }
}

class _RosePetalPainter extends CustomPainter {
  final List<_Petal> petals;
  _RosePetalPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in petals) {
      double renderX = p.x % size.width;
      double renderY = p.y % size.height;
      
      final paint = Paint()..color = p.isWhite ? Colors.white.withOpacity(0.8) : const Color(0xFFD32F2F).withOpacity(0.8);
      
      canvas.save();
      canvas.translate(renderX, renderY);
      canvas.rotate(p.rotation);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 2. Cotton Candy Sunset
// ==========================================
class CottonCandySunsetBackground extends StatefulWidget {
  const CottonCandySunsetBackground({super.key});
  @override
  State<CottonCandySunsetBackground> createState() => _CottonCandySunsetBackgroundState();
}

class _CottonCandySunsetBackgroundState extends State<CottonCandySunsetBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Orb> _orbs = [];
  final Random _random = Random();
  Offset _touchPos = const Offset(-1000, -1000);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 30; i++) {
      _orbs.add(_Orb(
        x: _random.nextDouble() * 500,
        y: _random.nextDouble() * 1000,
        size: _random.nextDouble() * 20 + 10,
      ));
    }
    _ticker = createTicker((elapsed) {
      setState(() {
        for (var o in _orbs) {
          o.update(_touchPos);
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _touchPos = details.localPosition,
      onPanEnd: (_) => _touchPos = const Offset(-1000, -1000),
      onTapDown: (details) => _touchPos = details.localPosition,
      onTapUp: (_) => _touchPos = const Offset(-1000, -1000),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFCCBC), Color(0xFFE91E63)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomPaint(
          painter: _OrbPainter(_orbs),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Orb {
  double x, y;
  double vx = 0, vy = -1.0; 
  double size;
  
  _Orb({required this.x, required this.y, required this.size});

  void update(Offset touchPos) {
    vx = sin(y / 100.0) * 1.5;

    double dx = x - touchPos.dx;
    double dy = y - touchPos.dy;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 150 && touchPos.dx > 0) {
      double force = (150 - dist) / 150;
      vx += (dx / dist) * force * 3;
      vy += (dy / dist) * force * 3;
    } else {
      vy = vy + (-1.5 - vy) * 0.1;
    }

    x += vx;
    y += vy;
    
    if (x < -50) x = 500;
    if (x > 550) x = 0;
    if (y < -50) y = 1000;
    if (y > 1050) y = 1000;
  }
}

class _OrbPainter extends CustomPainter {
  final List<_Orb> orbs;
  _OrbPainter(this.orbs);

  @override
  void paint(Canvas canvas, Size size) {
    for (var o in orbs) {
      double renderX = o.x % size.width;
      double renderY = o.y % size.height;
      
      final glowPaint = Paint()
        ..color = const Color(0xFFF8BBD0).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        
      canvas.drawCircle(Offset(renderX, renderY), o.size, glowPaint);
      
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(renderX, renderY), o.size / 3, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// ==========================================
// 3. Cherry Blossom Haven
// ==========================================
class CherryBlossomHavenBackground extends StatefulWidget {
  const CherryBlossomHavenBackground({super.key});
  @override
  State<CherryBlossomHavenBackground> createState() => _CherryBlossomHavenBackgroundState();
}

class _CherryBlossomHavenBackgroundState extends State<CherryBlossomHavenBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Blossom> _blossoms = [];
  final Random _random = Random();
  Offset _touchPos = const Offset(-1000, -1000);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 50; i++) {
      _blossoms.add(_Blossom(
        x: _random.nextDouble() * 500,
        y: _random.nextDouble() * 1000,
        rotation: _random.nextDouble() * pi * 2,
        size: _random.nextDouble() * 4 + 4,
      ));
    }
    _ticker = createTicker((elapsed) {
      setState(() {
        for (var b in _blossoms) {
          b.update(_touchPos);
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _touchPos = details.localPosition,
      onPanEnd: (_) => _touchPos = const Offset(-1000, -1000),
      onTapDown: (details) => _touchPos = details.localPosition,
      onTapUp: (_) => _touchPos = const Offset(-1000, -1000),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFCDD2), // Warm blush pink
        ),
        child: CustomPaint(
          painter: _BlossomPainter(_blossoms),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Blossom {
  double x, y;
  double vx = 1.0, vy = 1.5; 
  double rotation;
  double rotSpeed;
  double size;
  
  _Blossom({required this.x, required this.y, required this.rotation, required this.size}) 
    : rotSpeed = (Random().nextDouble() - 0.5) * 0.15;

  void update(Offset touchPos) {
    rotation += rotSpeed;
    
    // Wind drift
    vx = 1.5 + sin(y / 40.0) * 1.0;

    double dx = x - touchPos.dx;
    double dy = y - touchPos.dy;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 150 && touchPos.dx > 0) {
      double force = (150 - dist) / 150;
      vx += (dx / dist) * force * 5;
      vy += (dy / dist) * force * 5;
    } else {
      vy = vy + (1.5 - vy) * 0.1;
    }

    x += vx;
    y += vy;
    
    if (x > 550) x = -20;
    if (x < -50) x = 500;
    if (y > 1050) y = -20;
    if (y < -50) y = 1000;
  }
}

class _BlossomPainter extends CustomPainter {
  final List<_Blossom> blossoms;
  _BlossomPainter(this.blossoms);

  @override
  void paint(Canvas canvas, Size size) {
    // Soft bokeh background layer
    final bokehPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 100, bokehPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 150, bokehPaint);

    final paint = Paint()..color = const Color(0xFFF48FB1).withOpacity(0.9);
    for (var b in blossoms) {
      double renderX = b.x % size.width;
      double renderY = b.y % size.height;
      
      canvas.save();
      canvas.translate(renderX, renderY);
      canvas.rotate(b.rotation);
      
      // Draw blossom petal
      Path path = Path();
      path.moveTo(0, -b.size);
      path.quadraticBezierTo(b.size, -b.size, b.size, 0);
      path.quadraticBezierTo(b.size, b.size, 0, b.size);
      path.quadraticBezierTo(-b.size, b.size, -b.size, 0);
      path.quadraticBezierTo(-b.size, -b.size, 0, -b.size);
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 4. Neon Heartbeat Background
// ==========================================
class NeonHeartbeatBackground extends StatefulWidget {
  const NeonHeartbeatBackground({super.key});
  @override
  State<NeonHeartbeatBackground> createState() => _NeonHeartbeatBackgroundState();
}

class _NeonHeartbeatBackgroundState extends State<NeonHeartbeatBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_NeonHeart> _hearts = [];
  final Random _random = Random();
  double _globalBeatPhase = 0.0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _hearts.add(_NeonHeart(
        x: _random.nextDouble() * 400 + 50,
        y: _random.nextDouble() * 800 + 100,
        size: _random.nextDouble() * 20 + 20,
        phaseOffset: _random.nextDouble() * pi * 2,
      ));
    }
    _ticker = createTicker((elapsed) {
      setState(() {
        _globalBeatPhase += 0.1;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF4A0024), // Deep fuchsia/burgundy
      ),
      child: CustomPaint(
        painter: _NeonHeartPainter(_hearts, _globalBeatPhase),
        size: Size.infinite,
      ),
    );
  }
}

class _NeonHeart {
  double x, y, size, phaseOffset;
  _NeonHeart({required this.x, required this.y, required this.size, required this.phaseOffset});
}

class _NeonHeartPainter extends CustomPainter {
  final List<_NeonHeart> hearts;
  final double globalBeatPhase;
  _NeonHeartPainter(this.hearts, this.globalBeatPhase);

  @override
  void paint(Canvas canvas, Size size) {
    for (var h in hearts) {
      // Pulsating beat math (heartbeat style: lub-dub)
      double beat = sin(globalBeatPhase + h.phaseOffset);
      double scale = 1.0 + (beat > 0.8 ? (beat - 0.8) * 1.5 : 0.0);
      
      double scaledSize = h.size * scale;
      
      // Neon glow
      final glowPaint = Paint()
        ..color = const Color(0xFFFF007F).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
        
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      _drawHeart(canvas, h.x, h.y, scaledSize, glowPaint);
      _drawHeart(canvas, h.x, h.y, scaledSize, corePaint);
    }
  }
  
  void _drawHeart(Canvas canvas, double x, double y, double size, Paint paint) {
    Path path = Path();
    path.moveTo(x, y + size / 3);
    path.cubicTo(
      x - size, y - size,
      x - size * 1.5, y + size / 2,
      x, y + size
    );
    path.moveTo(x, y + size / 3);
    path.cubicTo(
      x + size, y - size,
      x + size * 1.5, y + size / 2,
      x, y + size
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

