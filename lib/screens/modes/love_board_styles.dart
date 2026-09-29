import 'package:material_ui/material_ui.dart';

class LoveBoardStyle {
  final String name;
  final BoxDecoration decoration;
  final Color textColor;
  final Widget? watermark;

  const LoveBoardStyle({
    required this.name,
    required this.decoration,
    required this.textColor,
    this.watermark,
  });
}

final List<LoveBoardStyle> loveBoardStyles = [
  // 1. Soft Rosewater
  LoveBoardStyle(
    name: 'Soft Rosewater',
    decoration: const BoxDecoration(color: Color(0xFFF6DFEB)),
    textColor: const Color(0xFF4A4A4A),
  ),
  // 2. Neon Sunset
  LoveBoardStyle(
    name: 'Neon Sunset',
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    textColor: Colors.white,
  ),
  // 3. Deep Crimson
  LoveBoardStyle(
    name: 'Deep Crimson',
    decoration: const BoxDecoration(color: Color(0xFF6F002A)),
    textColor: Colors.white,
  ),
  // 4. Frosted Glass
  LoveBoardStyle(
    name: 'Frosted Glass',
    decoration: BoxDecoration(
      color: Colors.pinkAccent.withOpacity(0.15),
      border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 1.5),
    ),
    textColor: const Color(0xFF333333),
  ),
  // 5. Cherry Blossom Silhouette
  LoveBoardStyle(
    name: 'Cherry Blossom',
    decoration: const BoxDecoration(color: Color(0xFFFFF0F5)),
    textColor: const Color(0xFF4A4A4A),
    watermark: const Positioned(
      right: -20,
      bottom: -20,
      child: Icon(Icons.local_florist, size: 120, color: Color(0xFFFFD1DC)),
    ),
  ),
  // 6. Rose Gold Foil
  LoveBoardStyle(
    name: 'Rose Gold Foil',
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFB76E79), Color(0xFFE0BFB8), Color(0xFFC07C88), Color(0xFFE0BFB8)],
        stops: [0.0, 0.3, 0.6, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    textColor: Colors.white,
  ),
  // 7. Midnight Pink
  LoveBoardStyle(
    name: 'Midnight Pink',
    decoration: BoxDecoration(
      color: const Color(0xFF1A000D),
      boxShadow: [
        BoxShadow(color: const Color(0xFFFF1493).withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
      ],
      border: Border.all(color: const Color(0xFFFF1493), width: 1),
    ),
    textColor: const Color(0xFFFFB6C1),
  ),
  // 8. Vintage Parchment
  LoveBoardStyle(
    name: 'Vintage Parchment',
    decoration: BoxDecoration(
      color: const Color(0xFFFDF6E3),
      border: Border.all(color: const Color(0xFFEBC7C7), width: 2),
    ),
    textColor: const Color(0xFF5C4033),
  ),
];

