import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoStudioModal extends StatefulWidget {
  final String imagePath;
  const PhotoStudioModal({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<PhotoStudioModal> createState() => _PhotoStudioModalState();
}

class _PhotoStudioModalState extends State<PhotoStudioModal> {
  final GlobalKey _previewKey = GlobalKey();
  
  double _brightness = 0.0; // -0.5 to 0.5
  double _contrast = 1.0; // 0.5 to 1.5
  double _vignette = 0.0; // 0.0 to 1.0
  String _aspectRatio = 'Original'; // 1:1, 4:5, Original
  List<double>? _selectedFilter;

  final Map<String, List<double>> _filters = {
    'Original': [
      1,0,0,0,0,
      0,1,0,0,0,
      0,0,1,0,0,
      0,0,0,1,0,
    ],
    'Warm Rosé': [
      1.1, 0, 0, 0, 10,
      0, 0.9, 0, 0, 5,
      0, 0, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Golden Hour': [
      1.1, 0, 0, 0, 20,
      0, 1.0, 0, 0, 10,
      0, 0, 0.7, 0, -10,
      0, 0, 0, 1, 0,
    ],
    'Vintage Film': [
      0.9, 0.2, 0.1, 0, 0,
      0.2, 0.8, 0.1, 0, 0,
      0.1, 0.2, 0.7, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Moody Noir': [
      0.33, 0.33, 0.33, 0, -20,
      0.33, 0.33, 0.33, 0, -20,
      0.33, 0.33, 0.33, 0, -20,
      0, 0, 0, 1, 0,
    ],
    'Ethereal Glow': [
      1.2, 0.1, 0.1, 0, 10,
      0.1, 1.1, 0.2, 0, 15,
      0.1, 0.1, 1.2, 0, 20,
      0, 0, 0, 1, 0,
    ],
    'Cyber Bloom': [
      1.3, 0, 0, 0, 10,
      0, 0.8, 0.3, 0, 0,
      0, 0.2, 1.4, 0, 20,
      0, 0, 0, 1, 0,
    ],
  };

  List<double> _getColorMatrix() {
    double b = _brightness * 255.0;
    double c = _contrast;
    double t = (1.0 - c) * 255.0 / 2.0;

    return [
      c, 0, 0, 0, b + t,
      0, c, 0, 0, b + t,
      0, 0, c, 0, b + t,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> _exportAndReturn() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Calculate a pixel ratio that ensures a high-resolution export (e.g. ~2160 pixels wide)
      final screenWidth = MediaQuery.of(context).size.width;
      final targetWidth = 2160.0;
      final dynamicRatio = targetWidth / screenWidth;
      final clampedRatio = dynamicRatio.clamp(2.0, 6.0); // Keep within reasonable bounds to prevent OOM
      ui.Image image = await boundary.toImage(pixelRatio: clampedRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        if (mounted) Navigator.pop(context, pngBytes);
      } else {
        if (mounted) Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    double ar = 1.0;
    if (_aspectRatio == '1:1') ar = 1.0;
    else if (_aspectRatio == '4:5') ar = 0.8;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Studio', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _exportAndReturn,
            child: Text('Done', style: GoogleFonts.poppins(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(
            child: RepaintBoundary(
              key: _previewKey,
              child: AspectRatio(
                aspectRatio: _aspectRatio == 'Original' ? 3/4 : ar,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.matrix(_getColorMatrix()),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(_selectedFilter ?? _filters['Original']!),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (_vignette > 0)
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(_vignette)],
                            stops: const [0.4, 1.0],
                            radius: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: _filters.keys.map((name) {
                              bool isSel = (_selectedFilter == _filters[name]) || (_selectedFilter == null && name == 'Original');
                              return GestureDetector(
                                onTap: () => setState(() => _selectedFilter = _filters[name]),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFFFF6B6B) : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(name, style: GoogleFonts.poppins(color: isSel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSlider('Brightness', _brightness, -0.5, 0.5, (v) => setState(() => _brightness = v)),
                        _buildSlider('Contrast', _contrast, 0.5, 1.5, (v) => setState(() => _contrast = v)),
                        _buildSlider('Vignette', _vignette, 0.0, 1.0, (v) => setState(() => _vignette = v)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['Original', '1:1', '4:5'].map((ar) {
                            return GestureDetector(
                              onTap: () => setState(() => _aspectRatio = ar),
                              child: Text(ar, style: GoogleFonts.poppins(color: _aspectRatio == ar ? const Color(0xFFFF6B6B) : Colors.white54, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))
          ),
          Expanded(
            child: Slider(
              value: value, min: min, max: max,
              activeColor: const Color(0xFFFF6B6B),
              inactiveColor: Colors.white10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}


