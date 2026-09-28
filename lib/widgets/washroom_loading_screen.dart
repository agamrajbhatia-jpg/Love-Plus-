import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class WashroomLoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const WashroomLoadingScreen({super.key, required this.onComplete});

  @override
  State<WashroomLoadingScreen> createState() => _WashroomLoadingScreenState();
}

class _WashroomLoadingScreenState extends State<WashroomLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentLoadingText = "Freshening up...";
  final List<_FloatingHeart> _hearts = [];
  late double _screenWidth;
  late double _screenHeight;
  
  late AudioPlayer _audioPlayer;
  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer = AudioPlayer();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _controller.addListener(() {
      final val = _controller.value;
      String newText = _currentLoadingText;
      if (val >= 0.0 && val < 0.2) {
        newText = "Freshening up...";
      } else if (val >= 0.2 && val < 0.4) {
        newText = "Brushing teeth...";
      } else if (val >= 0.4 && val < 0.8) {
        newText = "Taking shower...";
      } else if (val >= 0.8 && val <= 1.0) {
        newText = "Using a towel...";
      }

      if (newText != _currentLoadingText) {
        setState(() {
          _currentLoadingText = newText;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_hasPlayedSound) {
          _hasPlayedSound = true;
          _audioPlayer.play(AssetSource('sounds/cute_noise.mp3'));
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Initialize hearts if not done
          if (_hearts.isEmpty) {
            _screenWidth = constraints.maxWidth;
            _screenHeight = constraints.maxHeight;
            for (int i = 0; i < 20; i++) {
              _hearts.add(_FloatingHeart(_screenWidth, _screenHeight));
            }
            _controller.forward();
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFDAB9), Color(0xFFC2185B)], // Soft Peach to Deep Rose
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
            // Floating Hearts Background
            ..._hearts.map((h) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  h.update();
                  return Positioned(
                    left: h.x,
                    top: h.y - (_controller.value * 300 * h.speed),
                    child: Opacity(
                      opacity: h.opacity,
                      child: const Icon(Icons.favorite, color: Colors.white54, size: 24),
                    ),
                  );
                }
            )),
            
            // Center UI
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currentLoadingText,
                          key: ValueKey<String>(_currentLoadingText), // THIS IS MANDATORY
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _controller.value,
                              strokeWidth: 10,
                              backgroundColor: Colors.pinkAccent.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                "${(_controller.value * 100).toInt()}%",
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}

class _FloatingHeart {
  final random = Random();
  late double x;
  late double y;
  late double speed;
  late double opacity;

  _FloatingHeart(double width, double height) {
    x = random.nextDouble() * width;
    y = height + random.nextDouble() * 200; // start slightly below screen
    speed = 0.5 + random.nextDouble() * 1.5;
    opacity = 0.2 + random.nextDouble() * 0.4;
  }

  void update() {
    x += sin(DateTime.now().millisecondsSinceEpoch / 1000.0 + speed) * 0.5;
  }
}