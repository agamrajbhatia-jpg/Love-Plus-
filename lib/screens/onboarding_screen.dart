import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/floating_hearts_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _partnerController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  String? _selectedRole;
  bool _showCodeGeneration = false;
  bool _showCodeEntry = false;
  bool _isLinking = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not authenticated")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          if (data['coupleId'] != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            });
          }
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: Text("Sign Out", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
        ],
      ),
      body: FloatingHeartsBackground(
        opacityMultiplier: 0.15,
        child: DynamicBackground(
          // Dark Romantic Burgundy/Rose Palette
          colors: const [
            Color(0xFF4A0404), // Dark burgundy
            Color(0xFF7A103C), // Deep rose
            Color(0xFF2D0315), // Midnight pink
            Color(0xFF5A0B2E), // Rich maroon
            Color(0xFF3B071A), // Very dark red
          ],
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: GlassContainer(
                  blur: 25.0,
                  color: Colors.black.withOpacity(0.4),
                  padding: const EdgeInsets.all(32.0),
                  // Apply rose gold glow border to the main glass container (we do this by wrapping or customizing)
                  // Our GlassContainer supports color but not border color directly, we'll use a wrapper or its existing styling.
                  // Since we can't easily change GlassContainer's inner border without editing it, we will just pass a slightly red-tinted color
                  // wait, GlassContainer has a hardcoded white border in its implementation. Let me edit GlassContainer next.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: RepaintBoundary(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF), Color(0xFFFF4D6D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'LOVE PLUS',
                              style: GoogleFonts.cinzel(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFF4D6D).withOpacity(0.8),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (appState.userName == null || appState.userRole == null) ...[
                        // Step 1: Ask for name & role
                        Text(
                          'Connect with your partner.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildTextField(_nameController, 'What is your name?', Icons.person),
                        const SizedBox(height: 24),
                        Text(
                          "Who is playing right now? 👀",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRoleToggle("I am the BF", "👦", "BF"),
                            _buildRoleToggle("I am the GF", "👧", "GF"),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSolidButton('Next', () {
                          if (_nameController.text.isNotEmpty && _selectedRole != null) {
                            context.read<AppState>().setUserRole(_selectedRole!);
                            context.read<AppState>().setUserName(_nameController.text.trim());
                          }
                        }),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.read<AppState>().enterDemoMode(),
                          child: Text(
                            'Skip & Enter Demo Mode',
                            style: GoogleFonts.poppins(color: Colors.white70, decoration: TextDecoration.underline),
                          ),
                        ),
                      ] else if (!_showCodeGeneration && !_showCodeEntry) ...[
                        // Step 2: Choose action
                        Text(
                          'Hi, ${appState.userName}',
                          style: GoogleFonts.poppins(
                            fontSize: 28, 
                            color: Colors.white, 
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ready to link up?',
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        
                        _buildOptionCard(
                          title: 'Create a Connection Code',
                          icon: '✨',
                          onTap: () async {
                            setState(() {
                              _showCodeGeneration = true;
                              // We could add _isGeneratingCode here, but user asked to reset _showCodeGeneration on error
                            });
                            try {
                              await context.read<AppState>().generateCode();
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _showCodeGeneration = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildOptionCard(
                          title: 'I already have a code',
                          icon: '🔗',
                          onTap: () => setState(() => _showCodeEntry = true),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => context.read<AppState>().enterDemoMode(),
                          child: Text(
                            'Skip & Enter Demo Mode',
                            style: GoogleFonts.poppins(color: Colors.white70, decoration: TextDecoration.underline),
                          ),
                        ),
                      ] else if (_showCodeGeneration) ...[
                        // Step 3a: Show Code
                        Text(
                          'Your Connection Code:',
                          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFB76E79).withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D6D).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Text(
                            appState.connectionCode ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: const Color(0xFFFF4D6D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(color: Color(0xFFFF4D6D)),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for your partner to enter this code...',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ] else if (_showCodeEntry) ...[
                        // Step 3b: Enter Code
                        _buildTextField(_codeController, 'Enter Connection Code', Icons.password),
                        const SizedBox(height: 16),
                        _buildTextField(_partnerController, "Partner's Name", Icons.favorite_border),
                        const SizedBox(height: 24),
                        _isLinking 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D6D)))
                          : _buildSolidButton('Link Devices', () async {
                              if (_codeController.text.isNotEmpty && _partnerController.text.isNotEmpty) {
                                setState(() => _isLinking = true);
                                try {
                                  await context.read<AppState>().linkWithPartner(
                                    _codeController.text.trim(), 
                                    _partnerController.text.trim()
                                  );
                                  // success, guaranteed navigation
                                  if (mounted) {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _isLinking = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                  }
                                }
                              }
                            }),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }


  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB76E79).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D6D).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white54),
          prefixIcon: Icon(icon, color: const Color(0xFFFF4D6D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildSolidButton(String text, VoidCallback onPressed) {
    return BouncingButton(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D6D),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOptionCard({required String title, required String icon, required VoidCallback onTap}) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB76E79).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28, fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'])),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle(String title, String emoji, String role) {
    bool isSelected = _selectedRole == role;
    return BouncingButton(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4D6D) : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4D6D) : const Color(0xFFB76E79).withOpacity(0.4),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(isSelected ? 0.4 : 0.15),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

