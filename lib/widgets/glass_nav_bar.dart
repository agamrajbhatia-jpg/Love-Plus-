import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_container.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: GlassContainer(
        borderRadius: 30,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.checkroom, "OOTD"),
            _buildNavItem(1, Icons.location_on, "Map"),
            _buildNavItem(2, Icons.calendar_month, "Dates"),
            _buildNavItem(3, Icons.shopping_bag_outlined, "Shop"),
            _buildNavItem(4, Icons.pets, "Pet"),
            _buildNavItem(5, Icons.mail, "Letters"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12.0 : 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white.withOpacity(0.5)) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: isSelected ? 26 : 22,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
