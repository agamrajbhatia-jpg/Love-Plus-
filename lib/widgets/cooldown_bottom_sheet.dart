import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class CooldownBottomSheet extends StatefulWidget {
  final String gameName;
  final int remainingMinutes;

  const CooldownBottomSheet({
    Key? key,
    required this.gameName,
    required this.remainingMinutes,
  }) : super(key: key);

  static Future<void> show(BuildContext context, String gameName, {required int remainingMinutes}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CooldownBottomSheet(gameName: gameName, remainingMinutes: remainingMinutes),
    );
  }

  @override
  State<CooldownBottomSheet> createState() => _CooldownBottomSheetState();
}

class _CooldownBottomSheetState extends State<CooldownBottomSheet> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = Duration(minutes: widget.remainingMinutes);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft -= const Duration(seconds: 1);
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60);
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFF00FFD1).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00FFD1).withOpacity(0.2), blurRadius: 40, offset: const Offset(0, -10))
        ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.timer_outlined, color: Color(0xFFE100FF), size: 48),
            const SizedBox(height: 16),
            Text(
              "Cooldown Active",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              "Let the tension build... wait ${_formatDuration(_timeLeft)} before your next session.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE100FF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text("REMAINING", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE100FF), letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_timeLeft),
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                      Shadow(color: const Color(0xFFE100FF).withOpacity(0.5), blurRadius: 10)
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Center(
                  child: Text("DISMISS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

