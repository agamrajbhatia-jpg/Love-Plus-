import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/firebase_gate_service.dart';

class CustomDeckCreatorScreen extends StatefulWidget {
  final String templateType;

  const CustomDeckCreatorScreen({super.key, required this.templateType});

  @override
  State<CustomDeckCreatorScreen> createState() => _CustomDeckCreatorScreenState();
}

class _CustomDeckCreatorScreenState extends State<CustomDeckCreatorScreen> {
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  bool _isSubmitting = false;

  Future<void> _submitDeck() async {
    for (var controller in _controllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all 5 questions!')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = context.read<AppState>();
      final coupleId = appState.currentCoupleId;
      final uid = appState.currentUid;

      if (coupleId != null && uid != null) {
        final questions = _controllers.map((c) => c.text.trim()).toList();

        await FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .collection('custom_decks')
            .add({
          'templateType': widget.templateType,
          'questions': questions,
          'createdBy': uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isPlayed': false,
        });

        await FirebaseGateService.recordCustomCreation(coupleId, uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent to Partner! ??', style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: const Color(0xFF6A1B9A),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Create Custom Game",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE55D87).withOpacity(0.15),
                    const Color(0xFF0B0F19),
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Type 5 custom questions or prompts for your partner to play!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 5,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextFormField(
                            controller: _controllers[index],
                            style: GoogleFonts.poppins(color: Colors.white),
                            maxLines: 2,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: "Question ${index + 1}...",
                              hintStyle: GoogleFonts.poppins(color: Colors.white38),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _isSubmitting ? null : _submitDeck,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFFFF2E93)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66FF2E93), blurRadius: 15, spreadRadius: 2),
                        ],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                "Send to Partner ??",
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
