const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

// Replace the handleGameTap
const oldTap = `    if (response.status == GameAccessStatus.cooldownActive) {
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
    } else if (response.status == GameAccessStatus.dailyLimitReached) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumBenefitsScreen()));
      }
    } else {
      action();
    }`;

const newTap = `    if (response.status == GameAccessStatus.cooldownActive) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return StatefulBuilder(
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
            );
          }
        );
      }
      return;
    } else if (response.status == GameAccessStatus.dailyLimitReached) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                final now = DateTime.now();
                final tomorrow = DateTime(now.year, now.month, now.day + 1);
                final remainingSeconds = tomorrow.difference(now).inSeconds;

                final hours = (remainingSeconds ~/ 3600).toString().padLeft(2, '0');
                final mins = ((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
                final secs = (remainingSeconds % 60).toString().padLeft(2, '0');

                Future.delayed(const Duration(seconds: 1), () {
                  if (context.mounted) setState(() {});
                });

                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.5), width: 2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
                      const Icon(Icons.lock, color: Color(0xFFFF4D6D), size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Daily Limit Reached',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Next free play in ' + hours + ':' + mins + ':' + secs,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumBenefitsScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4D6D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Upgrade to Premium', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }
            );
          }
        );
      }
    } else {
      action();
    }`;

gzs = gzs.replace(oldTap, newTap);

fs.writeFileSync(path, gzs, 'utf8');
console.log('Modified GameZoneScreen handles');
