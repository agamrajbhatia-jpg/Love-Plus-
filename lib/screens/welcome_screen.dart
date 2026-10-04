import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Live Location',
      'description': 'Stay connected by seeing where your partner is on the shared map in real-time.',
      'icon': 'location_on'
    },
    {
      'title': 'Love Memos',
      'description': 'Leave sweet notes, photos, and voice memos on your partner\'s board.',
      'icon': 'favorite'
    },
    {
      'title': 'Couple Games',
      'description': 'Play fun quizzes and card games together to deepen your connection.',
      'icon': 'videogame_asset'
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootScreen()),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'location_on': return Icons.location_on;
      case 'favorite': return Icons.favorite;
      case 'videogame_asset': return Icons.videogame_asset;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E13),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconData(_pages[index]['icon']!),
                      size: 100,
                      color: const Color(0xFFFF4D6D),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _pages[index]['title']!,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _pages[index]['description']!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFFF4D6D)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                _currentPage == _pages.length - 1
                    ? ElevatedButton(
                        onPressed: _finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D6D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


