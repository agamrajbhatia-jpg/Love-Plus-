import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_gate_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_state.dart';
import '../../widgets/dynamic_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';

class VisualCustomDeckCreatorScreen extends StatefulWidget {
  final String templateType;

  const VisualCustomDeckCreatorScreen({super.key, required this.templateType});

  @override
  State<VisualCustomDeckCreatorScreen> createState() => _VisualCustomDeckCreatorScreenState();
}

class _VisualCustomDeckCreatorScreenState extends State<VisualCustomDeckCreatorScreen> {
  int _currentIndex = 0;
  final int _totalCards = 5;

  final List<TextEditingController> _controllersA = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _controllersB = List.generate(5, (_) => TextEditingController());
  bool _isSaving = false;

  @override
  void dispose() {
    for (var c in _controllersA) {
      c.dispose();
    }
    for (var c in _controllersB) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextOrSave() async {
    // Basic validation
    if (_controllersA[_currentIndex].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in the fields.')));
      return;
    }
    if (widget.templateType == 'Would You Rather' && _controllersB[_currentIndex].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both options.')));
      return;
    }

    if (_currentIndex < _totalCards - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      await _saveDeck();
    }
  }

  Future<void> _saveDeck() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final appState = context.read<AppState>();
      final coupleId = appState.currentCoupleId;
      final uid = appState.currentUid;
      if (coupleId == null || uid == null) throw Exception("Not logged in");

      List<String> finalQuestions = [];
      for (int i = 0; i < _totalCards; i++) {
        if (widget.templateType == 'Would You Rather') {
          final q = "Would you rather ${_controllersA[i].text.trim()} or ${_controllersB[i].text.trim()}?";
          finalQuestions.add(q);
        } else {
          finalQuestions.add(_controllersA[i].text.trim());
        }
      }

      final doc = FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('custom_decks').doc();
      await doc.set({
        'templateType': widget.templateType,
        'questions': finalQuestions,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isPlayed': false,
      });

      await FirebaseGateService.recordCustomCreation(coupleId, uid);

      if (mounted) {
        Navigator.pop(context); // close creator
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Custom deck sent to partner!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Make: ${widget.templateType}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                  child: Text(
                    "Card ${_currentIndex + 1}/$_totalCards",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: _buildCardUI(key: ValueKey(_currentIndex)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: BouncingButton(
                    onTap: () {
                      if (_isSaving) return;
                      _nextOrSave();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black))
                            : Text(
                                _currentIndex == _totalCards - 1 ? "Send to Partner" : "Next",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    List<Color> colors;
    switch (widget.templateType) {
      case 'Icebreakers & Fun':
      case 'Deep Dive Talk':
      case 'Playful Challenges':
      case 'Spontaneous Date':
      case 'Couple Cards':
        colors = const [Color(0xFF0B0F19), Color(0xFF1E1E2A)];
        break;
      case 'Would You Rather':
        colors = const [Color(0xFFff9a9e), Color(0xFFfecfef)];
        break;
      case 'How Well Do You Know Me':
        colors = const [Color(0xFFA1C4FD), Color(0xFFC2E9FB)];
        break;
      case 'Scenario Scale':
        colors = const [Color(0xFFD4FC79), Color(0xFF96E6A1)];
        break;
      case 'How Mad?':
        colors = const [Color(0xFFFF9A9E), Color(0xFFFECFEF)];
        break;
      case 'Expose Us':
        colors = const [Color(0xFFa18cd1), Color(0xFFfbc2eb)];
        break;
      case 'Blind Ranking Date Ideas':
        colors = const [Color(0xFF8E2DE2), Color(0xFF4A00E0)];
        break;
      default:
        colors = const [Color(0xFF1E1E2A), Color(0xFF2A2A40)];
    }
    return DynamicBackground(
      colors: colors,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildCardUI({required Key key}) {
    switch (widget.templateType) {
      case 'Icebreakers & Fun':
      case 'Deep Dive Talk':
      case 'Playful Challenges':
      case 'Spontaneous Date':
        return _buildNeonCoupleCardUI(key: key);
      case 'Couple Cards':
        return _buildCoupleCardsUI(key: key);
      case 'Would You Rather':
        return _buildWouldYouRatherUI(key: key);
      case 'How Well Do You Know Me':
        return _buildHowWellUI(key: key);
      case 'Scenario Scale':
        return _buildScenarioScaleUI(key: key);
      case 'How Mad?':
        return _buildHowMadUI(key: key);
      case 'Expose Us':
        return _buildExposeUsUI(key: key);
      case 'Blind Ranking Date Ideas':
        return _buildRankingUI(key: key);
      default:
        return const SizedBox();
    }
  }

  Widget _buildNeonCoupleCardUI({required Key key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2E93), Color(0xFF00F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x66FF2E93), blurRadius: 28, spreadRadius: 2),
          BoxShadow(color: Color(0x6600F0FF), blurRadius: 28, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC0D0B12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: TextField(
                  controller: _controllersA[_currentIndex],
                  maxLines: null,
                  textAlign: TextAlign.center,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type your question...',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleCardsUI({required Key key}) {
    return GlassContainer(
      key: key,
      blur: 20,
      borderRadius: 30,
      padding: const EdgeInsets.all(32),
      color: Colors.white.withOpacity(0.15),
      child: Center(
        child: TextField(
          controller: _controllersA[_currentIndex],
          maxLines: null,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Type your question here...',
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildWouldYouRatherUI({required Key key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Would you rather...",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6a11cb).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Center(
              child: TextField(
                controller: _controllersA[_currentIndex],
                maxLines: null,
                textAlign: TextAlign.center,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Type here...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "OR",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFFff0844), Color(0xFFffb199)]),
              boxShadow: [
                BoxShadow(color: const Color(0xFFff0844).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Center(
              child: TextField(
                controller: _controllersB[_currentIndex],
                maxLines: null,
                textAlign: TextAlign.center,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Type here...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowWellUI({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Center(
        child: TextField(
          controller: _controllersA[_currentIndex],
          maxLines: null,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Type a trivia question about yourself...',
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioScaleUI({required Key key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Center(
            child: TextField(
              controller: _controllersA[_currentIndex],
              maxLines: null,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, height: 1.3),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Type a scenario to be rated...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38),
              ),
            ),
          ),
        ),
        const SizedBox(height: 50),
        Text(
          "5",
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
          ),
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            trackHeight: 8,
          ),
          child: Slider(
            value: 5,
            min: 1,
            max: 10,
            onChanged: null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nah", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Absolutely", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHowMadUI({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Center(
        child: TextField(
          controller: _controllersA[_currentIndex],
          maxLines: null,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Type a scenario to see how mad they get...',
            hintStyle: GoogleFonts.poppins(color: Colors.black38),
          ),
        ),
      ),
    );
  }

  Widget _buildExposeUsUI({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology, size: 48, color: Color(0xFFa18cd1)),
          const SizedBox(height: 16),
          TextField(
            controller: _controllersA[_currentIndex],
            maxLines: null,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF4A4A4A), height: 1.2),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Who is more likely to...',
              hintStyle: GoogleFonts.poppins(color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingUI({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: TextField(
          controller: _controllersA[_currentIndex],
          maxLines: null,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF6A1B9A)),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Type a date idea to be ranked...',
            hintStyle: GoogleFonts.poppins(color: Colors.black38),
          ),
        ),
      ),
    );
  }
}





