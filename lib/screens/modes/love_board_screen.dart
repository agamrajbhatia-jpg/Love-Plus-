import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import 'create_letter_screen.dart';
import 'love_board_styles.dart';

class LoveBoardScreen extends StatelessWidget {
  const LoveBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final coupleId = appState.currentCoupleId;
    final partnerName = appState.partnerName ?? "Partner";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Love-Board',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Padding to avoid bottom nav bar
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateLetterScreen()));
          },
          backgroundColor: const Color(0xFFFF4D6D),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
      body: coupleId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .collection('love_board')
                  .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No letters yet. Be the first to post!',
                      style: GoogleFonts.poppins(color: Colors.black54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120, top: 20, left: 16, right: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _LoveBoardCard(data: data, docId: docs[index].id, partnerName: partnerName);
                  },
                );
              },
            ),
    );
  }
}

class _LoveBoardCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String partnerName;

  const _LoveBoardCard({required this.data, required this.docId, required this.partnerName});

  @override
  State<_LoveBoardCard> createState() => _LoveBoardCardState();
}

class _LoveBoardCardState extends State<_LoveBoardCard> {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _isUnlocked = !(widget.data['isGift'] == true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isMine = widget.data['senderId'] == appState.currentUid;
    final senderName = isMine ? "You" : widget.partnerName;
    
    final timestamp = widget.data['timestamp'] as Timestamp?;
    final timeString = timestamp != null ? DateFormat('MMM d, h:mm a').format(timestamp.toDate()) : 'Just now';
    
    final int colorIndex = widget.data['colorIndex'] ?? 0;
    final style = loveBoardStyles[colorIndex % loveBoardStyles.length];

    final contentCard = Container(
      clipBehavior: Clip.hardEdge,
      decoration: style.decoration.copyWith(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          if (style.watermark != null) style.watermark!,
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.data['purpose'] ?? 'Message',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    Text(
                      timeString,
                      style: GoogleFonts.poppins(fontSize: 12, color: style.textColor.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.data['text'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 16, color: style.textColor, height: 1.5),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '- $senderName',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: style.textColor),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );

    if (!_isUnlocked) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.4,
              child: contentCard,
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            ),
            Dismissible(
              key: ValueKey('gift_${widget.docId}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) {
                setState(() => _isUnlocked = true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF758C)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mail_lock, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      'Gift from $senderName',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swipe to open ✨',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: contentCard,
    );
  }
}
