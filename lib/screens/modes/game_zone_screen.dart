import '../premium_benefits_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/app_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';
import '../games/would_you_rather_screen.dart';
import '../games/how_well_do_you_know_me_screen.dart';
import '../games/scenario_scale_screen.dart';
import '../games/tic_tac_toe_screen.dart';
import '../games/how_mad_screen.dart';
import '../games/expose_us_screen.dart';
import '../games/live_card_game_screen.dart';
import '../games/ranking_date_ideas_screen.dart';
import '../games/visual_custom_deck_creator_screen.dart';
import '../games/play_custom_game_screen.dart';
import '../../services/firebase_gate_service.dart';

class GameZoneScreen extends StatefulWidget {
  const GameZoneScreen({super.key});

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {

    void _showPremiumLock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const _PremiumLockBottomSheet();
      }
    );
  }
  Future<void> _handleGameTap(String gameName, VoidCallback action) async {
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
                title: Text("Create a game quiz", style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text("Design your own deck and visual styles", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showGameTemplatePicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blueAccent),
                title: Text("Create a couple card", style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text("Simple question and answer format", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showCoupleCardTemplatePicker();
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

  void _showCoupleCardTemplatePicker() {
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
              Text("Choose Category", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _templateTile("Icebreakers & Fun"),
                    _templateTile("Deep Dive Talk"),
                    _templateTile("Playful Challenges"),
                    _templateTile("Spontaneous Date"),
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
          .collection('custom_games')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return _renderCustomGamesList(snapshot.data!.docs, appState);
        }

        // Fallback for pre-existing custom_decks docs
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(appState.currentCoupleId)
              .collection('custom_decks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, fallbackSnapshot) {
            if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.docs.isEmpty) {
              return const SizedBox();
            }
            return _renderCustomGamesList(fallbackSnapshot.data!.docs, appState);
          },
        );
      },
    );
  }

  Widget _renderCustomGamesList(List<QueryDocumentSnapshot> docs, AppState appState) {
    final currentUid = appState.currentUid;

    // Recipient filtering: playable incoming cards for current user
    final incomingDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final target = data['targetUserId']?.toString();
      final creator = data['creatorId']?.toString() ?? data['createdBy']?.toString();
      if (target != null && target.isNotEmpty) {
        return target == currentUid;
      }
      return creator != currentUid;
    }).toList();

    // Creator filtering: outgoing cards created by current user
    final outgoingDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final creator = data['creatorId']?.toString() ?? data['createdBy']?.toString();
      return creator == currentUid;
    }).toList();

    if (incomingDocs.isEmpty && outgoingDocs.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (incomingDocs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Text("💌", style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  "Games From Your Partner",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2A6D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${incomingDocs.length}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: incomingDocs.length,
              itemBuilder: (context, index) {
                final doc = incomingDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title']?.toString() ?? data['templateType']?.toString() ?? 'Custom Game';
                final isPending = (data['status'] ?? 'pending') == 'pending' && !(data['isPlayed'] == true);
                final questions = (data['questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                return Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C1654), Color(0xFF4A154B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF2A6D).withOpacity(0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2A6D).withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayCustomGameScreen(
                              gameId: doc.id,
                              data: {
                                ...data,
                                'id': doc.id,
                                'questions': questions,
                                'title': title,
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("✨", style: TextStyle(fontSize: 22)),
                                if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF2A6D),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF2A6D).withOpacity(0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "NEW",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${questions.length} cards • Tap to play",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFFF7597),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Outgoing inactive section for creator
        if (outgoingDocs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Text("📤", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  "Sent to Partner • Waiting for response",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: outgoingDocs.length,
              itemBuilder: (context, index) {
                final doc = outgoingDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title']?.toString() ?? data['templateType']?.toString() ?? 'Custom Game';
                final isCompleted = data['status'] == 'completed' || data['isPlayed'] == true;

                return Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF00F0FF).withOpacity(0.15)
                              : Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF00F0FF).withOpacity(0.4)
                                : Colors.amber.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          isCompleted ? "✅ Completed" : "⏳ Waiting...",
                          style: GoogleFonts.poppins(
                            color: isCompleted ? const Color(0xFF00F0FF) : Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.visible,
                softWrap: true,
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();


    final games = [
      {
        "title": "Would You Rather",
        "subtitle": "Spicy & Sweet",
        "icon": "🌶️",
        "color": const Color(0xFFFF6B6B),
        "onTap": () {
          _handleGameTap("Would You Rather", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WouldYouRatherScreen()));
          });
        },
      },
      {
        "title": "How Well Do You Know Me",
        "subtitle": "Trivia Time",
        "icon": "🤔",
        "color": const Color(0xFF4ECDC4),
        "onTap": () {
          _handleGameTap("how_well_do_you_know_me", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HowWellDoYouKnowMeScreen()));
          });
        },
      },
      {
        "title": "Scenario Scale",
        "subtitle": "Rate it 1-10",
        "icon": "⚖️",
        "color": const Color(0xFFFFD93D),
        "onTap": () {
          _handleGameTap("Scenario Scale", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ScenarioScaleScreen()));
          });
        },
      },
      {
        "title": "Tic Tac Toe",
        "subtitle": "Quick Match",
        "icon": "❌",
        "color": const Color(0xFF6C5CE7),
        "onTap": () {
          _handleGameTap("Tic Tac Toe", () {
            final appState = context.read<AppState>();
            Navigator.push(context, MaterialPageRoute(builder: (context) => TicTacToeScreen(
              coupleId: appState.currentCoupleId,
              currentUserId: appState.currentUid,
            )));
          });
        },
      },
      {
        "title": "How Mad?",
        "subtitle": "Test the limits",
        "icon": "😤",
        "color": const Color(0xFFFF9A9E),
        "onTap": () {
          _handleGameTap("How Mad?", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HowMadScreen()));
          });
        },
      },
      {
        "title": "Expose Us",
        "subtitle": "Who is more likely?",
        "icon": "🫣",
        "color": const Color(0xFFa18cd1),
        "onTap": () {
          _handleGameTap("Expose Us", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExposeUsScreen()));
          });
        },
      },
      {
        "title": "Blind Ranking Date Ideas",
        "subtitle": "Daily sync game",
        "icon": "🏆",
        "color": const Color(0xFFAB47BC),
        "onTap": () {
          _handleGameTap("Blind Ranking Date Ideas", () {
            final appState = context.read<AppState>();
            Navigator.push(context, MaterialPageRoute(builder: (context) => RankingDateIdeasScreen(
              coupleId: appState.currentCoupleId,
              currentUserId: appState.currentUid,
            )));
          });
        },
      },
      {
        "title": "Create Your Own",
        "subtitle": "Custom Games & Cards",
        "icon": "🎨",
        "color": const Color(0xFFE91E63),
        "onTap": () async {
          final appState = context.read<AppState>();
          final coupleId = appState.currentCoupleId;
          final uid = appState.currentUid;
          if (coupleId != null && uid != null) {
            bool canCreate = await FirebaseGateService.checkCustomCreationAccess(coupleId, uid);
            if (canCreate) {
              _showCreateChoiceBottomSheet();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daily limit reached! Wait until tomorrow.")));
            }
          }
        },
      }
    ];
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Game Zone",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: const Color(0xFFFF1493).withOpacity(0.5), blurRadius: 10)
                    ]
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Challenge your partner to cute PvP games!",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                StreamBuilder<QuerySnapshot>(
                  stream: (appState.currentCoupleId != null && appState.currentUid != null)
                      ? FirebaseFirestore.instance
                          .collection('couples')
                          .doc(appState.currentCoupleId)
                          .collection('challenges')
                          .where('targetId', isEqualTo: appState.currentUid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    final docs = snapshot.data!.docs;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "New Challenges!",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              // Merge doc id into data map
                              final challenge = {...data, 'id': docs[index].id};
                              
                              return GestureDetector(
                                onTap: () {
                                  final gameName = challenge['type'] ?? challenge['gameType'] ?? 'Unknown Challenge';
                                  _handleGameTap(gameName, () {
                                    if (gameName == 'how_mad') {
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => HowMadScreen(challengeToPlay: challenge)
                                        )
                                      );
                                    } else if (gameName == 'scenario') {
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => ScenarioScaleScreen(challengeToPlay: challenge)
                                        )
                                      );
                                    } else {
                                      Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => HowWellDoYouKnowMeScreen(challengeToPlay: challenge)
                                        )
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFA1C4FD).withOpacity(0.4), 
                                        blurRadius: 10, 
                                        offset: const Offset(0, 4)
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Flexible(
                                        child: Text("💌", style: TextStyle(fontSize: 32)),
                                      ),
                                      const SizedBox(height: 4),
                                      Flexible(
                                        child: Text(
                                          "New Challenge!",
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 10),
                Text(
                  "Couple Cards",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildDeckButton(context, 'Icebreakers \n& Fun', '🎈', const [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
                    _buildDeckButton(context, 'Deep Dive Talk', '💬', const [Color(0xFFE55D87), Color(0xFF5FC3E4)]),
                    _buildDeckButton(context, 'Playful Challenges', '🎯', const [Color(0xFF00F0FF), Color(0xFF00B4DB)]),
                    _buildDeckButton(context, 'Spontaneous Date Ideas', '💡', const [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]),
                  ],
                ),
                const SizedBox(height: 30),

                Text(
                  "Game Library",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best recommended to play on call together',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: (appState.currentCoupleId != null) 
                      ? FirebaseFirestore.instance
                          .collection('couples')
                          .doc(appState.currentCoupleId)
                          .collection('daily_limits')
                          .where(FieldPath.documentId, isGreaterThanOrEqualTo: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}_")
                          .where(FieldPath.documentId, isLessThan: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}_\uf8ff")
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final lockedGames = <String>{};
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final playCount = data['playCount'] as int? ?? 0;
                        final lastPlayed = data['lastPlayedAt'] as Timestamp?;
                        bool isLocked = false;
                        if (playCount >= FirebaseGateService.maxFreeDailySessions) {
                          isLocked = true;
                        } else if (lastPlayed != null && playCount < 2) {
                          if (DateTime.now().difference(lastPlayed.toDate()).inMinutes < 5) {
                            isLocked = true;
                          }
                        }
                        if (isLocked) {
                          final uid = appState.currentUid;
                          if (uid != null && doc.id.endsWith("_$uid")) {
                             lockedGames.add(doc.id);
                          }
                        }
                      }
                    }

                    return AnimationLimiter(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          final gameTitle = game['title'] as String;
                          final safeName = FirebaseGateService.getSafeGameName(gameTitle);
                          final dateStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                          final uid = appState.currentUid ?? '';
                          final isLocked = lockedGames.contains("${dateStr}_${safeName}_$uid") && gameTitle != 'Tic Tac Toe' && gameTitle != 'Create Your Own';

                          return AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            columnCount: 2,
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: SizedBox.expand(
                                  child: _GameCard(
                                    title: gameTitle,
                                    subtitle: game['subtitle'] as String,
                                    icon: game['icon'] as String,
                                    color: game['color'] as Color,
                                    onTapAction: () {
                                      if (gameTitle.toLowerCase().contains('would you rather')) {
                                        _handleGameTap(gameTitle, () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const WouldYouRatherScreen()));
                                        });
                                        return;
                                      }
                                      final VoidCallback? tapAction = game['onTap'] as VoidCallback?;
                                      if (tapAction != null) {
                                        tapAction();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                ),
                const SizedBox(height: 30),
                _buildCustomGamesInbox(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // Persistent Scoreboard Widget
          Positioned(
            top: 10,
            right: 20,
            child: _ScoreboardWidget(
              userScore: appState.userGameScore,
              partnerScore: appState.partnerGameScore,
              partnerName: appState.partnerName ?? "Partner",
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreboardWidget extends StatelessWidget {
  final int userScore;
  final int partnerScore;
  final String partnerName;

  const _ScoreboardWidget({
    required this.userScore,
    required this.partnerScore,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 20,
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScorePill(name: "You", score: userScore, color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Text(
            ' ⚔️ ',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          _ScorePill(name: partnerName, score: partnerScore, color: const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String name;
  final int score;
  final Color color;

  const _ScorePill({required this.name, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Row(
          children: [
            Text(
              "$score",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: color, blurRadius: 12)]
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 14),
          ],
        )
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback? onTapAction;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: () {
        if (onTapAction != null) {
          onTapAction!();
        } else {
          showDialog(
            context: context,
            barrierColor: Colors.black12,
            builder: (dialogContext) {
              Future.delayed(const Duration(seconds: 2), () {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              });
              return SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Text(
                          "Loading $title...",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ]
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(icon, style: const TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 75,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.visible,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.poppins(fontSize: 11, height: 1.1, color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



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


class _PremiumLockBottomSheet extends StatefulWidget {
  const _PremiumLockBottomSheet();
  @override
  _PremiumLockBottomSheetState createState() => _PremiumLockBottomSheetState();
}

class _PremiumLockBottomSheetState extends State<_PremiumLockBottomSheet> {
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
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

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
              "Wait ${hours}h ${minutes}m ${seconds}s or upgrade to Premium for endless fun!",
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
                child: Center(
                  child: Text(
                    "Upgrade to Premium ✨",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
}




