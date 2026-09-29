import 'dart:async';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumLockScreen extends StatefulWidget {
  final bool isDailyLimit;
  final DateTime unlockTime;

  const PremiumLockScreen({
    super.key,
    required this.isDailyLimit,
    required this.unlockTime,
  });

  @override
  State<PremiumLockScreen> createState() => _PremiumLockScreenState();
}

class _PremiumLockScreenState extends State<PremiumLockScreen> with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    if (widget.unlockTime.isAfter(now)) {
      _remaining = widget.unlockTime.difference(now);
    } else {
      _remaining = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    if (_remaining.isNegative || _remaining == Duration.zero) {
      return widget.isDailyLimit ? "00:00:00" : "00:00";
    }
    int h = _remaining.inHours;
    int m = _remaining.inMinutes.remainder(60);
    int s = _remaining.inSeconds.remainder(60);
    
    if (widget.isDailyLimit) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    } else {
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient (Layer 1)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0033), Color(0xFF4D004D)],
              ),
            ),
          ),
          
          // Ambient blurred glowing particles
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.2),
              ),
            ),
          ),
          
          // Animated Teaser Card (Layer 2)
          Center(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: Transform.rotate(
                angle: -0.15,
                child: Container(
                  width: 250,
                  height: 350,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "?",
                      style: GoogleFonts.poppins(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Cinematic matte-glass depth filter (Layer 3)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          
          // Main Content (Layer 4)
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isDailyLimit ? "DAILY LIMIT REACHED" : "BREATHING SPACE",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4.0,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  
                  // Glowing Pulsing Ring
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.65,
                        height: MediaQuery.of(context).size.width * 0.65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A0033).withOpacity(0.8), // Dark center to mask shadow
                          border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.5 + (_glowAnimation.value * 0.3)),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(_glowAnimation.value * 0.6),
                              blurRadius: 40 + (_glowAnimation.value * 20),
                              spreadRadius: 5 + (_glowAnimation.value * 10),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formattedTime,
                          style: GoogleFonts.poppins(
                            fontSize: widget.isDailyLimit ? 52 : 72,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        widget.isDailyLimit 
                          ? "Absence makes the heart grow fonder..." 
                          : "Next deck unlocks soon.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

