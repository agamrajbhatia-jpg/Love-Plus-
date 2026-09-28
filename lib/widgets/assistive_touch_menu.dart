import 'package:flutter/material.dart';

/// An Assistive Touch style menu that expands/collapses vertically.
/// Managed via AnimatedPositioned within the parent Stack.
class AssistiveTouchMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onFeed;
  final VoidCallback onClean;
  final VoidCallback onWardrobe;

  const AssistiveTouchMenu({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onFeed,
    required this.onClean,
    required this.onWardrobe,
  });

  @override
  Widget build(BuildContext context) {
    const double bubbleSize = 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: Alignment.bottomCenter,
          child: Container(
            height: isOpen ? null : 0.0,
            padding: const EdgeInsets.only(bottom: 15.0, right: 5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildActionBubble(
                  icon: Icons.checkroom,
                  color: Colors.pinkAccent,
                  onTap: onWardrobe,
                ),
                const SizedBox(height: 15),
                _buildActionBubble(
                  icon: Icons.shower,
                  color: Colors.lightBlue,
                  onTap: onClean,
                ),
                const SizedBox(height: 15),
                _buildActionBubble(
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  onTap: onFeed,
                ),
              ],
            ),
          ),
        ),
        // Main Toggle Bubble
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isOpen ? Icons.close : Icons.pets,
                key: ValueKey<bool>(isOpen),
                color: Colors.pinkAccent,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBubble({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
