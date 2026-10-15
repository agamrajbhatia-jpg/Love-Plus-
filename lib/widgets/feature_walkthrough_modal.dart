import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureWalkthroughModal extends StatefulWidget {
  const FeatureWalkthroughModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Walkthrough',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const FeatureWalkthroughModal();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FeatureWalkthroughModal> createState() => _FeatureWalkthroughModalState();
}

class _FeatureWalkthroughModalState extends State<FeatureWalkthroughModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Live Radar & Presence',
      'description':
          'Stay close no matter the miles. View real-time distance, partner battery, live weather, and one-tap Google Maps directions.',
      'icon': Icons.near_me_rounded,
      'gradient': [const Color(0xFF00F0FF), const Color(0xFF8A2BE2)],
      'badge': 'RADAR',
    },
    {
      'title': 'OOTD & Daily Fits',
      'description':
          'Share your daily style and fit checks privately with instant notifications, glowing borders, and cute hype reactions.',
      'icon': Icons.checkroom_rounded,
      'gradient': [const Color(0xFFFF2A6D), const Color(0xFF9B51E0)],
      'badge': 'DAILY FITS',
    },
    {
      'title': 'Love Letters & Board',
      'description':
          'Pin heartfelt love letters, secret memos, and memories on your shared board to cherish anytime.',
      'icon': Icons.favorite_rounded,
      'gradient': [const Color(0xFFFF2A6D), const Color(0xFFFF8E53)],
      'badge': 'LOVE BOARD',
    },
    {
      'title': 'Deep Conversation Decks',
      'description':
          'Explore intimate questions, fun challenges, and spicy couple card decks crafted to spark deep conversations.',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [const Color(0xFF9B51E0), const Color(0xFF00F0FF)],
      'badge': 'GAMES & DECKS',
    },
  ];

  Future<void> _completeWalkthrough() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_walkthrough', true);
      await prefs.setBool('has_seen_walkthrough', true);
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWalkthrough();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
            decoration: BoxDecoration(
              color: const Color(0xF20F0C1B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFF2A6D).withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFFFF2A6D).withOpacity(0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar: Brand Pill + Skip Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('❤️', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                'LOVE PLUS',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _completeWalkthrough,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carousel PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        final List<Color> gradient = step['gradient'] as List<Color>;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 14),
                              // Glowing Hero Icon
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient.first.withOpacity(0.4),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    step['icon'] as IconData,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Step Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: gradient.first.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: gradient.first.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  step['badge'] as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Step Title
                              Text(
                                step['title'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Step Description
                              Text(
                                step['description'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Controls: Animated Dots Indicator + Continue CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (index) {
                            final bool isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isActive ? 24 : 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFF2A6D)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF2A6D).withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Action Button
                        GestureDetector(
                          onTap: _onNext,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2A6D).withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _steps.length - 1
                                      ? 'Get Started ✨'
                                      : 'Continue',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (_currentPage < _steps.length - 1) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
