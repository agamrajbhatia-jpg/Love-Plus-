import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dynamic_background.dart';
import 'floating_hearts_background.dart';

class RomanticLoadingOverlay extends StatefulWidget {
  final String? customMessage;
  
  const RomanticLoadingOverlay({super.key, this.customMessage});

  @override
  State<RomanticLoadingOverlay> createState() => _RomanticLoadingOverlayState();
}

class _RomanticLoadingOverlayState extends State<RomanticLoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _quoteIndex = 0;
  Timer? _timer;

  final List<String> _quotes = [
    "distance means so little when someone means so much...",
    "loading your love story...",
    "finding the perfect connection...",
    "building bridges to your heart...",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FloatingHeartsBackground(
        opacityMultiplier: 0.1,
        child: DynamicBackground(
          colors: const [
            Color(0xFF2D0315),
            Color(0xFF1A020B),
            Color(0xFF3B071A),
            Color(0xFF0F0106),
          ],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D6D)),
                        strokeWidth: 2,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFF4D6D),
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: Text(
                      (widget.customMessage ?? _quotes[_quoteIndex]).toLowerCase(),
                      key: ValueKey<String>(widget.customMessage ?? _quotes[_quoteIndex]),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


