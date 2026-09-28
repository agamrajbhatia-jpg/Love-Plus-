const fs = require('fs');
const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');

// Purple Cooldown
const badToast = `    if (response.status == GameAccessStatus.cooldownActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Wait ' + response.remainingMinutes.toString() + ' minutes to play again', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }`;

const purpleOverlay = `    if (response.status == GameAccessStatus.cooldownActive) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
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
                  'Wait ' + response.remainingMinutes.toString() + ' minutes to play this game again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
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
          ),
        );
      }
      return;
    }`;
gzs = gzs.replace(badToast, purpleOverlay);

fs.writeFileSync(gzsPath, gzs, 'utf8');
console.log('Fixed overlay');
