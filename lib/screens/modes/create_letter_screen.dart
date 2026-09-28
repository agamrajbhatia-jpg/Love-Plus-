import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state.dart';
import 'love_board_styles.dart';

class CreateLetterScreen extends StatefulWidget {
  const CreateLetterScreen({super.key});

  @override
  State<CreateLetterScreen> createState() => _CreateLetterScreenState();
}

class _CreateLetterScreenState extends State<CreateLetterScreen> {
  final _textController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isGift = false;
  String _selectedPurpose = 'Love letter';
  bool _isSubmitting = false;

  final _purposes = [
    'Love letter',
    'Apology',
    'Comfort message',
    'Birthday',
    'Anniversary',
    'Happy journey',
    'Anxiety relief'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    final appState = context.read<AppState>();
    
    // Request push permissions (if not already granted)
    await appState.requestPushPermissions();
    
    await appState.postToLoveBoard(
      text: _textController.text.trim(),
      purpose: _selectedPurpose,
      colorIndex: _selectedColorIndex,
      isGift: _isGift,
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('New Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purpose of this letter:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedPurpose,
                  items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.poppins()))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPurpose = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Styling:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: loveBoardStyles.length,
                itemBuilder: (context, index) {
                  final style = loveBoardStyles[index];
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: style.decoration.copyWith(
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black87, width: 3) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              decoration: loveBoardStyles[_selectedColorIndex].decoration.copyWith(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(20),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  if (loveBoardStyles[_selectedColorIndex].watermark != null)
                    loveBoardStyles[_selectedColorIndex].watermark!,
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    minLines: 5,
                    style: GoogleFonts.poppins(color: loveBoardStyles[_selectedColorIndex].textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Write your heart out...',
                      hintStyle: GoogleFonts.poppins(color: loveBoardStyles[_selectedColorIndex].textColor.withOpacity(0.6)),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('Post as a Gift', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text('Partner must tap to reveal the letter', style: GoogleFonts.poppins(fontSize: 12)),
              value: _isGift,
              activeColor: const Color(0xFFFF4D6D),
              onChanged: (val) => setState(() => _isGift = val),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D6D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Post to Love-Board', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
