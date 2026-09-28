const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

if (!gzs.includes('import \'dart:async\';')) {
  gzs = gzs.replace(`import 'package:flutter/material.dart';`, `import 'package:flutter/material.dart';\nimport 'dart:async';`);
}

const oldCooldownBlock = `            return StatefulBuilder(
              builder: (context, setState) {
                final now = DateTime.now();
                final lastPlayed = response.lastPlayedAt ?? now;
                final diff = now.difference(lastPlayed).inSeconds;
                final remainingSeconds = (5 * 60) - diff;
                
                if (remainingSeconds <= 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  });
                  return const SizedBox();
                }

                final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
                final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

                Future.delayed(const Duration(seconds: 1), () {
                  if (context.mounted) setState(() {});
                });

                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)),
                      ),
                      const SizedBox(height: 24),
                      const Text('⏳', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'Cooling Down!',
                        style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wait ' + mins + ':' + secs + ' to play this game again.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6A1B9A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Got it', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }
            );`;

const newCooldownBlock = `            final now = DateTime.now();
            return _CooldownBottomSheet(lastPlayedAt: response.lastPlayedAt ?? now);`;

gzs = gzs.replace(oldCooldownBlock, newCooldownBlock);

const cooldownClass = `
class _CooldownBottomSheet extends StatefulWidget {
  final DateTime lastPlayedAt;
  const _CooldownBottomSheet({required this.lastPlayedAt});
  @override
  _CooldownBottomSheetState createState() => _CooldownBottomSheetState();
}

class _CooldownBottomSheetState extends State<_CooldownBottomSheet> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(widget.lastPlayedAt).inSeconds;
    final remainingSeconds = (5 * 60) - diff;

    if (remainingSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const SizedBox();
    }

    final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 24),
          const Text('⏳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Cooling Down!',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Wait $mins:$secs to play this game again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A1B9A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Got it', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
`;

gzs = gzs + cooldownClass;

fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed cooldown bottom sheet');
