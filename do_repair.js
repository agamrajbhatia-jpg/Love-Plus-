const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const replacement = `  void _showPremiumLock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final now = DateTime.now();
            final tomorrow = DateTime(now.year, now.month, now.day + 1);
            final diff = tomorrow.difference(now);
            final hoursStr = diff.inHours.toString().padLeft(2, '0');
            final minsStr = (diff.inMinutes % 60).toString().padLeft(2, '0');
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5EC),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🔒", style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      "Free Play Used Today!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD81B60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Wait $hoursStr:$minsStr or upgrade to Premium for endless fun!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    BouncingButton(
                      onTap: () {
                         Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumBenefitsScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                          "Upgrade to Premium ✨",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Maybe later",
                        style: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _handleGameTap(String gameName, VoidCallback action) async {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    if (coupleId == null || uid == null) return;
    
    final response = await FirebaseGateService.checkGameAccess(gameName, coupleId, uid);
    if (response.status == GameAccessStatus.cooldownActive) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            final now = DateTime.now();
            return _CooldownBottomSheet(lastPlayedAt: response.lastPlayedAt ?? now);
          }
        );
      }
      return;
    } else if (response.status == GameAccessStatus.dailyLimitReached) {
      if (mounted) {
        _showPremiumLock(context);
      }
    } else {
      action();
    }
  }

  void _showCreateChoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create Custom Game",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.style, color: Colors.pinkAccent),
                title: Text("Visual Card Game", style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text("Design your own deck and visual styles", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showGameTemplatePicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blueAccent),
                title: Text("Text Based Quiz", style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text("Simple question and answer format", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showGameTemplatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose Template", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _templateTile("Would You Rather"),
                    _templateTile("How Well Do You Know Me"),
                    _templateTile("Scenario Scale"),
                    _templateTile("How Mad?"),
                    _templateTile("Expose Us"),
                    _templateTile("Blind Ranking Date Ideas"),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _templateTile(String templateType) {
    return ListTile(
      title: Text(templateType, style: GoogleFonts.poppins(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => VisualCustomDeckCreatorScreen(templateType: templateType))
        );
      },
    );
  }

  Widget _buildCustomGamesInbox() {
    final appState = context.watch<AppState>();
    if (appState.currentCoupleId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(appState.currentCoupleId)
          .collection('custom_decks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Custom Games Inbox",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Custom Game';
                  final author = data['createdBy'] == appState.currentUid ? 'You' : 'Partner';
                  final template = data['templateType'] ?? 'CoupleCards';
                  final List<dynamic> questions = data['questions'] ?? [];

                  return GestureDetector(
                    onTap: () {
                      final cardTitle = template;
                      if (cardTitle.toLowerCase().contains('would you rather')) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WouldYouRatherScreen(customQuestions: questions, customDeckId: doc.id)));
                        return;
                      }
                      final safeRoute = template.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
                      if (safeRoute == 'couplecards') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: 'Custom Deck', customQuestions: questions, customDeckId: doc.id)));
                      }
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF3498DB)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mail, color: Colors.white, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            "By $author",
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildDeckButton(BuildContext context, String title, String icon, List<Color> gradientColors) {
    return BouncingButton(
      onTap: () {
        _handleGameTap(title, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: title)));
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradientColors.first.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title.replaceAll(' ', '\n'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
`;

const startIndex = gzs.indexOf('  void _showPremiumLock(BuildContext context) {');
const endIndex = gzs.indexOf('  @override\n  Widget build(BuildContext context) {');

if (startIndex !== -1 && endIndex !== -1) {
  gzs = gzs.substring(0, startIndex) + replacement + '\n' + gzs.substring(endIndex);
  fs.writeFileSync(path, gzs, 'utf8');
  console.log('REPAIRED!');
} else {
  console.log('Could not find indices!');
}
