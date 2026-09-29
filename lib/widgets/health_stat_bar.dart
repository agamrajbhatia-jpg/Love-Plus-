import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet_state.dart';

class HealthStatBar extends StatelessWidget {
  final PetStats stats;

  const HealthStatBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow("Fullness", stats.fullness * 100, Colors.orange),
        const SizedBox(height: 8),
        _buildStatRow("Tidiness", stats.tidiness * 100, Colors.blue),
        const SizedBox(height: 8),
        _buildStatRow("Happiness", stats.health.toDouble(), Colors.pink),
      ],
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

