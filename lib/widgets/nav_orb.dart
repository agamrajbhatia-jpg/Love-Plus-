import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class AssistiveNavOrb extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AssistiveNavOrb({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<AssistiveNavOrb> createState() => _AssistiveNavOrbState();
}

class _AssistiveNavOrbState extends State<AssistiveNavOrb> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _handleTabSelected(int index) {
    setState(() => _isOpen = false);
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        return SizedBox(
          height: 350, // Enough area to expand the semi-circle
          width: availableWidth,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
          // Background Dimmer (optional, to focus on nav)
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.transparent),
              ),
            ),

          // --- Nav Items Fan Array ---
          _buildNavItem(index: 0, icon: Icons.checkroom, label: "OOTD", angle: pi, availableWidth: availableWidth),
          _buildNavItem(index: 1, icon: Icons.location_on, label: "Map", angle: pi * 1.2, availableWidth: availableWidth),
          _buildNavItem(index: 2, icon: Icons.calendar_month, label: "Dates", angle: pi * 1.4, availableWidth: availableWidth),
          _buildNavItem(index: 3, icon: Icons.shopping_bag_outlined, label: "Shop", angle: pi * 1.6, availableWidth: availableWidth),
          _buildNavItem(index: 4, icon: Icons.pets, label: "Pet", angle: pi * 1.8, availableWidth: availableWidth),
          _buildNavItem(index: 5, icon: Icons.mail, label: "Letters", angle: pi * 2, availableWidth: availableWidth),

          // --- Central Orb ---
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isOpen ? 50 : 65,
                height: _isOpen ? 50 : 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOpen ? Colors.white24 : const Color(0xFFF43F5E), // rose-500
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF43F5E).withOpacity(0.5),
                      blurRadius: _isOpen ? 10 : 25,
                      spreadRadius: _isOpen ? 2 : 5,
                    )
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isOpen ? Icons.close : Icons.explore,
                      key: ValueKey<bool>(_isOpen),
                      color: Colors.white,
                      size: _isOpen ? 24 : 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      }
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required double angle,
    required double availableWidth,
  }) {
    // Math to position items in an arc above the orb
    const double radius = 120.0;
    
    // Bottom center is (0,0) in our logical offset mapping.
    // However, AnimatedPositioned uses left/right/bottom. 
    // We can use Alignment to make the math easier.
    
    // Convert angle (pi to 2*pi is the top half circle). 
    // Wait, typical trigonometric circle: 0 is Right, pi/2 is Bottom, pi is Left, 3pi/2 is Top.
    // We want from pi (left) to 0 (right), spanning the top semi-circle.
    
    // Remap index 0..5 to angles pi .. 0.
    // 0: pi (left)
    // 1: 0.8 * pi
    // 2: 0.6 * pi
    // 3: 0.4 * pi
    // 4: 0.2 * pi
    // 5: 0 (right)
    
    double mappedAngle = pi - (index * (pi / 5));
    
    final dx = radius * cos(mappedAngle);
    final dy = radius * sin(mappedAngle); // sin is positive, so it goes "down" in UI coords?
    // Actually, in UI coords, -Y is up.
    
    final bool isSelected = widget.currentIndex == index;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      // The orb is at bottom: 20. Orb height is 65. Center is approx bottom 50.
      bottom: _isOpen ? 50 + dy : 20,
      left: _isOpen ? (availableWidth / 2) + dx - 25 : (availableWidth / 2) - 25,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isOpen ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: () {
            if (_isOpen) _handleTabSelected(index);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFF43F5E) : Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFFF43F5E).withOpacity(0.5) : Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFFF43F5E),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(color: Colors.black54, blurRadius: 4)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
