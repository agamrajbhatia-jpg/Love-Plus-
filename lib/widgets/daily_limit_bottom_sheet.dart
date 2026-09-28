import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/premium_benefits_screen.dart';

class DailyLimitBottomSheet extends StatefulWidget {
  const DailyLimitBottomSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DailyLimitBottomSheet(),
    );
  }

  @override
  State<DailyLimitBottomSheet> createState() => _DailyLimitBottomSheetState();
}

class _DailyLimitBottomSheetState extends State<DailyLimitBottomSheet> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateTimeLeft();
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _timeLeft = nextMidnight.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours.remainder(24));
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFFE100FF).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE100FF).withOpacity(0.2), blurRadius: 40, offset: const Offset(0, -10))
        ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.hourglass_empty_rounded, color: Color(0xFF00FFD1), size: 48),
            const SizedBox(height: 16),
            Text(
              "Daily Limit Reached",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "You've exhausted your free sessions for today. Wait for the reset or unlock unlimited access!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00FFD1).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text("RESETS IN", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF00FFD1), letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_timeLeft),
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                      Shadow(color: const Color(0xFF00FFD1).withOpacity(0.5), blurRadius: 10)
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // dismiss bottom sheet
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumBenefitsScreen()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE100FF), Color(0xFF00FFD1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE100FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Center(
                  child: Text("UNLOCK UNLIMITED", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
