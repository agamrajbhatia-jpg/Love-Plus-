import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/floating_hearts_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (cred.user != null) {
          await _createUserDoc(cred.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Authentication failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final UserCredential cred = await FirebaseAuth.instance.signInWithPopup(provider);
        
        if (cred.user != null) {
          await _createUserDoc(cred.user!);
        }
      } else {
        // Native Google Sign In
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          if (googleAuth.idToken == null && googleAuth.accessToken == null) {
            throw Exception('Missing Google Auth Token! (Did you add your SHA-1 to Firebase Console?)');
          }
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          final UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (cred.user != null) {
            await _createUserDoc(cred.user!);
          }
        } else {
          // User canceled
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In Exception: $e');
      if (e is FirebaseAuthException) {
        setState(() => _errorMessage = e.message ?? "Google sign in failed");
        _showSnackbar(e.message ?? "Google sign in failed", Colors.redAccent);
      } else {
        setState(() => _errorMessage = "Google sign in failed (Check SHA-1 in Firebase Console)");
        _showSnackbar("Google Auth Error: ${e.toString()}", Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDoc(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'phone': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FloatingHeartsBackground(
        opacityMultiplier: 0.15,
        child: DynamicBackground(
          colors: const [
            Color(0xFF4A0404),
            Color(0xFF7A103C),
            Color(0xFF2D0315),
            Color(0xFF5A0B2E),
            Color(0xFF3B071A),
          ],
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: GlassContainer(
                  blur: 25.0,
                  color: Colors.black.withOpacity(0.4),
                  padding: const EdgeInsets.all(32.0),
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
                      const SizedBox(height: 16),
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Log in to continue' : 'Sign up to connect',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      _buildTextField(_emailController, 'Email', Icons.email, false),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', Icons.lock, true),
                      
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D6D)))
                        : _buildSolidButton(
                            _isLogin ? 'Log In' : 'Sign Up',
                            _submitEmail
                          ),
                      
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                        }),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF4D6D),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFFF4D6D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                        
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildGoogleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return BouncingButton(
      onTap: _submitGoogle,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, color: Colors.white, size: 40),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB76E79).withOpacity(0.4), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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
}
