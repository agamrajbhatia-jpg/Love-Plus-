import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import 'modes/ootd_screen.dart';
import 'modes/location_screen.dart';
import 'modes/dates_screen.dart';
import 'modes/love_memo_shop_screen.dart';
import 'modes/love_board_screen.dart';
import 'modes/messenger_hub_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/floating_hearts_background.dart';
import '../widgets/bouncing_button.dart';
import 'modes/game_zone_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/premium_gate_service.dart';
import 'premium_benefits_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool isNavCollapsed = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumGateService.isPremium();
    setState(() {
      _isPremium = isPremium;
    });
  }

  final List<Widget> _modes = const [
    OOTDScreen(),
    LocationScreen(),
    DatesScreen(),
    LoveMemoShopScreen(),
    GameZoneScreen(),
    LoveBoardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final partnerName = context.watch<AppState>().partnerName ?? "Your Partner";
    final bool hideNav = isNavCollapsed && _currentIndex == 4;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'You & $partnerName',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: BouncingButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ]
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: BouncingButton(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const MessengerHubScreen())
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ]
                ),
                child: Consumer<AppState>(
                  builder: (context, state, child) {
                    return Badge(
                      isLabelVisible: state.unreadCount > 0,
                      label: Text(state.unreadCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFFF4D6D),
                      offset: const Offset(-2, -2),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    );
                  }
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Main Body Content
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentIndex == 4 && !isNavCollapsed) {
                  setState(() => isNavCollapsed = true);
                }
              },
              child: FloatingHeartsBackground(
                child: DynamicBackground(
                  colors: const [
                    Color(0xFFF43F5E), Color(0xFFF472B6), Color(0xFFFB7185), 
                    Color(0xFFFDA4AF), Color(0xFFF87171),
                  ],
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _modes[_currentIndex],
                  ),
                ),
              ),
            ),
          ),
          
          // Strict state management for Navigation UI
          if (isNavCollapsed)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() => isNavCollapsed = false);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.sports_esports, color: Colors.white, size: 28),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: RepaintBoundary(
                    child: GlassContainer(
                      blur: 25.0,
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: 30,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: (index) {
                          setState(() {
                            _currentIndex = index;
                            if (index != 4) isNavCollapsed = false;
                          });
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: const Color(0xFFF43F5E),
                        unselectedItemColor: Colors.white.withOpacity(0.6),
                        showSelectedLabels: false,
                        showUnselectedLabels: false,
                        selectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(color: Color(0xCCF43F5E), blurRadius: 10)
                          ]
                        ),
                        items: [
                          BottomNavigationBarItem(
                            icon: _buildOotdIcon(isActive: false),
                            activeIcon: _buildOotdIcon(isActive: true),
                            label: 'OOTD',
                          ),
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.location_on, size: 28, color: Colors.white70),
                            activeIcon: _buildGlowingIcon(Icons.location_on),
                            label: 'Map',
                          ),
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.calendar_month, size: 28, color: Colors.white70),
                            activeIcon: _buildGlowingIcon(Icons.calendar_month),
                            label: 'Dates',
                          ),
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                            activeIcon: _buildGlowingIcon(Icons.shopping_bag_outlined),
                            label: 'Love Shop',
                          ),
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.sports_esports, size: 28, color: Colors.white70),
                            activeIcon: _buildGlowingIcon(Icons.sports_esports),
                            label: 'Games',
                          ),
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.favorite, size: 28, color: Colors.white70),
                            activeIcon: _buildGlowingIcon(Icons.favorite),
                            label: 'Love-Board',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildGlowingIcon(IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0xCCF43F5E), blurRadius: 15, spreadRadius: 2)]
      ),
      child: Icon(icon, color: const Color(0xFFF43F5E), size: 28),
    );
  }


  Widget _buildOotdIcon({required bool isActive}) {
    final color = isActive ? const Color(0xFFF43F5E) : Colors.white.withOpacity(0.6);
    
    Widget iconWidget = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.checkroom, color: color, size: 24),
        Positioned(
          top: -4, right: -4,
          child: Icon(Icons.auto_awesome, color: color, size: 12),
        )
      ],
    );

    if (isActive) {
      return Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Color(0xCCF43F5E), blurRadius: 10)]
        ),
        child: iconWidget,
      );
    }
    return iconWidget;
  }
}



