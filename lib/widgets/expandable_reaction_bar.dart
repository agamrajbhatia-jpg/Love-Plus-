import 'package:flutter/material.dart';
import 'bouncing_button.dart';

class ExpandableReactionBar extends StatefulWidget {
  const ExpandableReactionBar({super.key});

  @override
  State<ExpandableReactionBar> createState() => _ExpandableReactionBarState();
}

class _ExpandableReactionBarState extends State<ExpandableReactionBar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  
  final List<String> _emojis = ['🔥', '✨', '😍', '💋', '🥺'];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BouncingButton(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.add_reaction_outlined, color: Color(0xFFFF6B6B), size: 20),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _emojis.map((emoji) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: BouncingButton(
                      onTap: () {
                        setState(() => _isExpanded = false);
                      },
                      child: Text(
                        emoji, 
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji', 'Segoe UI Emoji'],
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
