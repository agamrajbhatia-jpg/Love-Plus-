import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PulsingAvatar extends StatefulWidget {
  final String label;
  final Color baseColor;
  final String imageUrl;

  const PulsingAvatar({
    super.key,
    required this.label,
    required this.baseColor,
    required this.imageUrl,
  });

  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing Ring
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.baseColor.withOpacity(0.5),
                        border: Border.all(
                          color: widget.baseColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // 3D Avatar Bubble
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.baseColor.withOpacity(0.8),
                    widget.baseColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.baseColor.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFFF6B6B)),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }
}
