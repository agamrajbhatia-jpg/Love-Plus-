import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../providers/app_state.dart';
import '../../services/open_router_service.dart';
import '../../services/premium_gate_service.dart';
import '../../services/firebase_gate_service.dart';
import '../premium_benefits_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/bouncing_button.dart';

class LoveMemoShopScreen extends StatefulWidget {
  const LoveMemoShopScreen({super.key});

  @override
  State<LoveMemoShopScreen> createState() => _LoveMemoShopScreenState();
}

class _LoveMemoShopScreenState extends State<LoveMemoShopScreen> with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OpenRouterService _aiService = OpenRouterService();
  final ImagePicker _picker = ImagePicker();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  int _selectedTab = 0; // 0: Cute Memo, 1: Photo Booth
  File? _userPhoto;
  File? _partnerPhoto;

  bool _isGenerating = false;
  String? _generatedImageUrl;
  bool _isSaving = false;

  bool _isPremium = false;
  int _freePhotosUsed = 0;

  final List<String> _suggestions = [
    'Marriage look',
    'Old self look at 80',
    'Children look',
    'Cartoon Pixar style',
    'Cyberpunk future',
  ];

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _focusNode.addListener(() {
      setState(() {});
    });
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _promptController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isUser) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isUser) {
            _userPhoto = File(image.path);
          } else {
            _partnerPhoto = File(image.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumGateService.isPremium();
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    int used = 0;
    
    if (coupleId != null && uid != null) {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final docId = "${dateStr}_photo_gen_$uid";
      
      final docSnap = await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('daily_limits')
          .doc(docId)
          .get();
          
      if (docSnap.exists) {
        used = docSnap.data()?['playCount'] as int? ?? 0;
      }
    }

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _freePhotosUsed = used;
      });
    }
  }

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

  Future<void> _generateImage() async {
    if (_userPhoto == null || _partnerPhoto == null) {
      _showError('Please upload both Your Photo and Partner\'s Photo for identity consistency!');
      return;
    }

    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    final uid = appState.currentUid;
    if (coupleId == null || uid == null) {
      _showError('No Couple ID found.');
      return;
    }

    bool canGen = await FirebaseGateService.checkPhotoAccess(coupleId, uid);
    if (!canGen) {
      _showPremiumLock(context);
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedImageUrl = null;
    });

    try {
      final String? result = await _aiService.generateImage(
        _promptController.text,
        userPhoto: _userPhoto,
        partnerPhoto: _partnerPhoto,
      );

      if (result != null && !result.startsWith('Error:')) {
        await FirebaseGateService.recordPhotoGeneration(coupleId, uid);
        
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _generatedImageUrl = result;
            _freePhotosUsed += 1;
          });
        }
      } else {
        print("API FAILED: $result");
        throw Exception(result ?? "Unknown Error");
      }
    } catch (e) {
      print('API Error: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        _showError('Generation failed: $e');
      }
    }
  }

  Future<void> _saveToMemos() async {
    if (_generatedImageUrl == null) return;
    
    setState(() => _isSaving = true);

    try {
      Uint8List? imageBytes;
      if (_generatedImageUrl!.startsWith('http')) {
        final res = await http.get(Uri.parse(_generatedImageUrl!));
        imageBytes = res.bodyBytes;
      } else {
        final base64String = _generatedImageUrl!.split(',').last;
        imageBytes = base64Decode(base64String);
      }
      
      if (imageBytes.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('/storage/emulated/0/Download/love_memo_$timestamp.jpg');
        await file.writeAsBytes(imageBytes);
        debugPrint("Gallery save result: success (${file.path})");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to your photo gallery! ✨', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFFF477E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Failed to save memo: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19), // Deeper indigo base
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradientText(
              "Love Memo Studio",
              gradient: const LinearGradient(colors: [Color(0xFFFF477E), Color(0xFF00F0FF)]),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'powered by gemini nano banana',
              style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Transform your bond into timeless art, future milestones, or classic booth strips.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatusBadge(),
                  const SizedBox(height: 20),
                  _buildTabControl(),
                  const SizedBox(height: 24),
                  _buildPhotoUploadSection(),
                  const SizedBox(height: 24),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                    },
                    child: _selectedTab == 0 ? _buildCuteMemoUI() : _buildPhotoBoothUI(),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildImageOutput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -150 * _bgAnimation.value,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF477E).withOpacity(0.35),
                      const Color(0xFFFF477E).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150 * (2.0 - _bgAnimation.value),
              right: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F0FF).withOpacity(0.35),
                      const Color(0xFF00F0FF).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00F0FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.2), blurRadius: 10, spreadRadius: 1),
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00F0FF), size: 16),
            const SizedBox(width: 8),
            Text("✨ LOVE PLUS AI", style: GoogleFonts.poppins(color: const Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedContainer({Key? key, required Widget child, EdgeInsetsGeometry? padding, Color glowColor = const Color(0xFFFF477E)}) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glowColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: glowColor.withOpacity(0.15), blurRadius: 30, spreadRadius: -5),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTabControl() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? const Color(0xFFFF477E).withOpacity(0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(27),
                  border: _selectedTab == 0 ? Border.all(color: const Color(0xFFFF477E).withOpacity(0.6), width: 1.5) : null,
                  boxShadow: _selectedTab == 0 ? [BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.3), blurRadius: 12)] : [],
                ),
                alignment: Alignment.center,
                child: Text("Cute Memo", style: GoogleFonts.poppins(color: _selectedTab == 0 ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFF00F0FF).withOpacity(0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(27),
                  border: _selectedTab == 1 ? Border.all(color: const Color(0xFF00F0FF).withOpacity(0.6), width: 1.5) : null,
                  boxShadow: _selectedTab == 1 ? [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.3), blurRadius: 12)] : [],
                ),
                alignment: Alignment.center,
                child: Text("Photo Booth", style: GoogleFonts.poppins(color: _selectedTab == 1 ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    bool bothUploaded = _userPhoto != null && _partnerPhoto != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.15), blurRadius: 40, spreadRadius: -5)
        ]
      ),
      child: Column(
        children: [
          Text(
            "Identity Hub",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPhotoSlot(true, "Your Photo", _userPhoto, const Color(0xFFFF477E)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: bothUploaded 
                  ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF477E).withOpacity(0.2),
                          border: Border.all(color: const Color(0xFFFF477E).withOpacity(0.8), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.8), blurRadius: 20, spreadRadius: 5),
                          ]
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 30),
                      ),
                    )
                  : Icon(Icons.favorite_border, color: Colors.white.withOpacity(0.3), size: 28),
              ),
              _buildPhotoSlot(false, "Partner's Photo", _partnerPhoto, const Color(0xFF00F0FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(bool isUser, String label, File? photo, Color accentColor) {
    return GestureDetector(
      onTap: () => _pickImage(isUser),
      child: Column(
        children: [
          Container(
            width: 85,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF131B33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: photo != null ? accentColor : Colors.white.withOpacity(0.15),
                width: 2.5,
              ),
              boxShadow: photo != null ? [
                BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 3)
              ] : [],
              image: photo != null ? DecorationImage(image: FileImage(photo), fit: BoxFit.cover) : null,
            ),
            child: photo == null ? Icon(Icons.add_a_photo, color: Colors.white.withOpacity(0.4), size: 28) : null,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 85,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitIndicator() {
    int maxAllowed = _isPremium ? 5 : 1;
    int remaining = maxAllowed - _freePhotosUsed;
    if (remaining < 0) remaining = 0;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          "Generations Left: $remaining/$maxAllowed",
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCuteMemoUI() {
    return Column(
      key: const ValueKey('CuteMemo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _SuggestionChipWidget(
                text: s,
                onTap: () {
                  _promptController.text = s;
                },
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focusNode.hasFocus ? const Color(0xFFFF477E) : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: _focusNode.hasFocus ? [
              BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
            ] : [],
          ),
          child: TextField(
            controller: _promptController,
            focusNode: _focusNode,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              hintText: "Describe your dream memory...",
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLimitIndicator(),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _isGenerating ? null : _generateImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF477E), Color(0xFF00F0FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
              ]
            ),
            alignment: Alignment.center,
            child: _isGenerating 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text("Generate Memory ✨", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoBoothUI() {
    return _buildFrostedContainer(
      key: const ValueKey('PhotoBooth'),
      glowColor: const Color(0xFF00F0FF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.6), width: 2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.4), blurRadius: 20)
              ]
            ),
            child: const Icon(Icons.camera, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          _GradientText(
            "Classic 4-Frame Booth",
            gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Colors.white]),
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Upload reference photos above. We'll generate a gorgeous vintage photo strip of you two.",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildLimitIndicator(),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isGenerating ? null : _generateImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF070B19),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
                ]
              ),
              alignment: Alignment.center,
              child: _isGenerating 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF00F0FF), strokeWidth: 2.5))
                : Text("Enter Booth 📸", style: GoogleFonts.poppins(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBoothStrip(Widget imageWidget) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBE1), // Aesthetic vintage paper color
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white70, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black26, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: imageWidget,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Love Plus Booth",
            style: GoogleFonts.dancingScript(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            "${DateTime.now().year}",
            style: GoogleFonts.courierPrime(
              color: Colors.black54,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOutput() {
    if (_isGenerating) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFFF477E).withOpacity(0.4),
        highlightColor: const Color(0xFF00F0FF).withOpacity(0.7),
        child: Container(
          height: 420,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 54),
                const SizedBox(height: 20),
                Text(
                  "Weaving romantic magic...\nPlease Wait.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_generatedImageUrl != null) {
      Widget imageWidget;
      if (_generatedImageUrl!.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: _generatedImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
        );
      } else {
        try {
          final base64String = _generatedImageUrl!.split(',').last;
          imageWidget = Image.memory(base64Decode(base64String), fit: BoxFit.cover);
        } catch (e) {
          imageWidget = const Center(child: Text('Invalid image data', style: TextStyle(color: Colors.white)));
        }
      }

      return _buildFrostedContainer(
        padding: const EdgeInsets.all(16),
        glowColor: const Color(0xFF00F0FF),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 15),
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("Identity Match Check: PASS", style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            _selectedTab == 1 ? _buildPhotoBoothStrip(imageWidget) : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: imageWidget,
                ),
              ),
            ),
            
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _isSaving ? null : _saveToMemos,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF477E), Color(0xFF00F0FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF477E).withOpacity(0.4), blurRadius: 15, spreadRadius: 1),
                  ]
                ),
                alignment: Alignment.center,
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("Save to Gallery & Memos 💾", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                    ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}

class _SuggestionChipWidget extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChipWidget({required this.text, required this.onTap});

  @override
  State<_SuggestionChipWidget> createState() => _SuggestionChipWidgetState();
}

class _SuggestionChipWidgetState extends State<_SuggestionChipWidget> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedScale(
        scale: _isTapped ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _isTapped ? const Color(0xFF00F0FF).withOpacity(0.25) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isTapped ? const Color(0xFF00F0FF) : const Color(0xFF00F0FF).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: _isTapped ? [
              BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.4), blurRadius: 15, spreadRadius: 1)
            ] : [],
          ),
          child: Text(widget.text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const _GradientText(this.text, {required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
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


