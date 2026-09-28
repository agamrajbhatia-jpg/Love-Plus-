import 'package:flutter/material.dart';

enum AccessoryType {
  topHat,
  baseballCap,
  crown,
  readingGlasses,
  sunglasses,
  bowtie,
  scarf,
  collar,
}

class AccessoryRenderer extends StatelessWidget {
  final AccessoryType type;
  final Color color;

  const AccessoryRenderer({super.key, required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    String assetPath = '';
    
    // Map the 8 categories to the 3 high-quality 3D assets we generated
    switch (type) {
      case AccessoryType.topHat:
      case AccessoryType.baseballCap:
      case AccessoryType.crown:
        assetPath = 'assets/3d_hat.png';
        break;
      case AccessoryType.readingGlasses:
      case AccessoryType.sunglasses:
        assetPath = 'assets/3d_glasses.png';
        break;
      case AccessoryType.bowtie:
      case AccessoryType.scarf:
      case AccessoryType.collar:
        assetPath = 'assets/3d_bow.png';
        break;
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.modulate, // Preserves shadows and highlights of the white 3D asset while perfectly tinting it
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}
