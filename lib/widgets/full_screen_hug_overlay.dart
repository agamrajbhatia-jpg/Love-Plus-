import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FullScreenHugOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const FullScreenHugOverlay({super.key, required this.onDismiss});

  @override
  State<FullScreenHugOverlay> createState() => _FullScreenHugOverlayState();
}

class _FullScreenHugOverlayState extends State<FullScreenHugOverlay> with TickerProviderStateMixin {
  late AnimationController _phase1Controller;
  late AnimationController _phase2Controller;
  
  // Phase 1: Text
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;
  
  // Phase 2: Graphic and Particles
  late Animation<double> _graphicScale;
  late Animation<double> _graphicOpacity;
  
  final int numParticles = 20;
  final List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    
    // Play Audio (Handle autoplay restrictions gracefully)
    try {
      final audio = html.AudioElement('https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3'); // Magical Chime
      audio.play().catchError((e) {
        debugPrint('Audio autoplay blocked by browser: $e');
      });
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
    
    // Initialize Particles
    final random = Random();
    for (int i = 0; i < numParticles; i++) {
      particles.add(Particle(
        angle: random.nextDouble() * 2 * pi,
        speed: random.nextDouble() * 100 + 50,
        size: random.nextDouble() * 20 + 10,
        color: random.nextBool() ? const Color(0xFFFF4D6D) : const Color(0xFFFF8FA3),
      ));
    }

    // Phase 1 Controller (0 - 1.5s)
    _phase1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.5).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_phase1Controller);

    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_phase1Controller);

    // Phase 2 Controller (1.0s - 3.5s)
    _phase2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _graphicScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.8).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.8, end: 1.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.8, end: 2.2).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_phase2Controller);

    _graphicOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_phase2Controller);

    _runAnimations();
  }
  
  Future<void> _runAnimations() async {
    _phase1Controller.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    _phase2Controller.forward();
    
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _phase1Controller.dispose();
    _phase2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Darken Background slightly
            AnimatedBuilder(
              animation: _phase2Controller,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.4 * _graphicOpacity.value),
                );
              }
            ),
            
            // Phase 1: "awwww>>>" text
            AnimatedBuilder(
              animation: _phase1Controller,
              builder: (context, child) {
                if (_textOpacity.value == 0) return const SizedBox();
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Text(
                      'awwww>>>',
                      style: GoogleFonts.caveat(
                        fontSize: 64,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            color: Color(0xFFFF4D6D),
                            blurRadius: 20,
                          )
                        ]
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Phase 2: Graphic and Particles
            AnimatedBuilder(
              animation: _phase2Controller,
              builder: (context, child) {
                if (_phase2Controller.value == 0) return const SizedBox();
                
                return Opacity(
                  opacity: _graphicOpacity.value,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Particles
                      ...particles.map((p) {
                        final progress = _phase2Controller.value;
                        final distance = p.speed * progress;
                        final dx = cos(p.angle) * distance;
                        final dy = sin(p.angle) * distance;
                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: Opacity(
                            opacity: 1.0 - progress,
                            child: Icon(Icons.favorite, color: p.color, size: p.size),
                          ),
                        );
                      }),
                      
                      // Glowing aura
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D6D).withOpacity(0.6),
                              blurRadius: 120,
                              spreadRadius: 60,
                            )
                          ]
                        ),
                      ),
                      
                      // Main Graphic
                      Transform.scale(
                        scale: _graphicScale.value,
                        child: const Text(
                          '👩‍❤️‍👨', // Couple hugging/loving emoji composition
                          style: TextStyle(
                            fontSize: 80,
                            fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji', 'Segoe UI Emoji'],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  Particle({required this.angle, required this.speed, required this.size, required this.color});
}
