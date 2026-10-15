import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../theme/map_style.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _myMarkerIcon;
  BitmapDescriptor? _partnerMarkerIcon;
  String? _myPhotoUrlCache;
  String? _partnerPhotoUrlCache;
  MapType _currentMapType = MapType.normal;
  
  StreamSubscription<DocumentSnapshot>? _locationSub;
  LatLng _myLoc = const LatLng(0, 0);
  LatLng _partnerLoc = const LatLng(0, 0);
  String _partnerCity = "Unknown Location";
  String _distanceText = "Calculating...";
  DateTime? _lastUpdated;
  String _myCity = "Locating you...";
  String _timeText = "Last updated: Just now";
  static final Map<String, Uint8List> _networkImageCache = {};

  int _partnerBattery = 84;
  String _partnerTemp = "22°C";
  String _partnerWeather = "Sunny";
  int _partnerAqi = 32;

  bool _hasInitialLocation = false;
  bool _hasPartnerLocation = false;

  @override
  void initState() {
    super.initState();
    // Pre-cache load before map
    _fetchLocation();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationStream();
      final appState = context.read<AppState>();
      if (appState.currentUid != null) {
        _loadCustomMarkers(appState.currentUid, appState.partnerUid);
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initLocationStream() {
    final appState = context.read<AppState>();
    if (appState.currentCoupleId != null) {
      _locationSub = FirebaseFirestore.instance
          .collection('couples')
          .doc(appState.currentCoupleId)
          .snapshots()
          .listen(_onLocationUpdate);
    }
  }

  void _onLocationUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('locations')) return;
    
    final appState = context.read<AppState>();
    final locations = data['locations'] as Map<String, dynamic>;
    
    LatLng newMyLoc = _myLoc;
    LatLng newPartnerLoc = _partnerLoc;
    
    if (appState.currentUid != null && locations.containsKey(appState.currentUid)) {
      newMyLoc = LatLng(locations[appState.currentUid]['lat'], locations[appState.currentUid]['lng']);
      _myCity = locations[appState.currentUid]['city'] ?? "Unknown City";
    }
    
    final partnerUid = data['user1'] == appState.currentUid ? data['user2'] : data['user1'];
    bool foundPartner = false;
    if (partnerUid != null && locations.containsKey(partnerUid)) {
      foundPartner = true;
      final pData = locations[partnerUid];
      newPartnerLoc = LatLng(pData['lat'], pData['lng']);
      _partnerCity = pData['city'] ?? "Unknown Area";
      _lastUpdated = (pData['timestamp'] as Timestamp?)?.toDate();
      _partnerBattery = (pData['battery'] as num?)?.toInt() ?? 84;
      _partnerWeather = pData['weather'] as String? ?? "Sunny";
      _partnerTemp = pData['temp'] as String? ?? "22°C";
      _partnerAqi = (pData['aqi'] as num?)?.toInt() ?? 32;
    }
    
    if (foundPartner) {
      final double distanceInMeters = Geolocator.distanceBetween(
        newMyLoc.latitude, newMyLoc.longitude,
        newPartnerLoc.latitude, newPartnerLoc.longitude,
      );
      if (distanceInMeters < 1000) {
        _distanceText = "${distanceInMeters.round()} m apart";
      } else {
        final double miles = distanceInMeters / 1609.34;
        _distanceText = "${miles.toStringAsFixed(1)} mi apart";
      }
    } else {
      _distanceText = "Waiting for partner...";
    }
    
    if (_lastUpdated != null) {
      final diff = DateTime.now().difference(_lastUpdated!);
      if (diff.inMinutes > 60) {
        _timeText = "Active \h ago";
      } else if (diff.inMinutes > 0) {
        _timeText = "Active \m ago";
      } else {
        _timeText = "Active just now";
      }
    } else {
      _timeText = "No active connection";
    }
    
    if (mounted) {
      setState(() {
        _myLoc = newMyLoc;
        _partnerLoc = newPartnerLoc;
        _hasPartnerLocation = foundPartner;
      });
      if (appState.currentUid != null && partnerUid != null) {
        _loadCustomMarkers(appState.currentUid, partnerUid);
      }
    }
  }

  Future<void> _loadCustomMarkers(String? myUid, String? partnerUid) async {
    if (myUid == null) return;
    String? myPhotoUrl;
    String? partnerPhotoUrl;
    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      myPhotoUrl = myDoc.data()?['mapPinUrl'] ?? myDoc.data()?['profileImageUrl'] ?? myDoc.data()?['photoUrl'];
      
      if (partnerUid != null) {
        final pDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
        partnerPhotoUrl = pDoc.data()?['mapPinUrl'] ?? pDoc.data()?['profileImageUrl'] ?? pDoc.data()?['photoUrl'];
      }
    } catch (_) {}

    if (myPhotoUrl != _myPhotoUrlCache || partnerPhotoUrl != _partnerPhotoUrlCache || _myMarkerIcon == null) {
      _myPhotoUrlCache = myPhotoUrl;
      _partnerPhotoUrlCache = partnerPhotoUrl;
      
      final myIcon = await _createCustomMarkerBitmap(myPhotoUrl, isMe: true);
      final partnerIcon = await _createCustomMarkerBitmap(partnerPhotoUrl, isMe: false);
      
      if (mounted) {
        setState(() {
          _myMarkerIcon = myIcon;
          _partnerMarkerIcon = partnerIcon;
        });
      }
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String? imageUrl, {required bool isMe}) async {
    final int size = 260;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Color haloColor = isMe ? const Color(0xFF00FFFF) : const Color(0xFFFF2E93);
    final Color glowColor = isMe ? const Color(0xFF8A2BE2) : const Color(0xFFFF2E93);
    final double radius = 85.0;
    final Offset center = Offset(size / 2, size / 2.2);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(center.dx, center.dy + 15), radius, shadowPaint);

    final Paint pulseGlowPaint = Paint()
      ..color = glowColor.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius + 15, pulseGlowPaint);
    
    final Paint neonRingPaint = Paint()
      ..color = haloColor.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 2, neonRingPaint);

    final Paint pointerPaint = Paint()..color = haloColor;
    final Path pointerPath = Path()
      ..moveTo(center.dx - 18, center.dy + radius - 5)
      ..lineTo(center.dx + 18, center.dy + radius - 5)
      ..lineTo(center.dx, center.dy + radius + 40)
      ..close();
    canvas.drawPath(pointerPath, pointerPaint);
    canvas.drawPath(pointerPath, shadowPaint); 

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    if (isMe) {
      borderPaint.color = Colors.white;
    } else {
      borderPaint.shader = ui.Gradient.sweep(
        center,
        [const Color(0xFFFF2E93), const Color(0xFF00F0FF), const Color(0xFF9B51E0), const Color(0xFFFF2E93)],
      );
    }
    canvas.drawCircle(center, radius, borderPaint);

    ui.Image? image;
    bool isEmoji = false;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        try {
          Uint8List? bytes = _networkImageCache[imageUrl];
          if (bytes == null) {
            final request = await HttpClient().getUrl(Uri.parse(imageUrl));
            final response = await request.close();
            bytes = await consolidateHttpClientResponseBytes(response);
            _networkImageCache[imageUrl] = bytes;
          }
          final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: (radius * 2).toInt(), targetHeight: (radius * 2).toInt());
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          image = frameInfo.image;
        } catch (e) {}
      } else {
        isEmoji = true;
      }
    }

    final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2));
    canvas.save();
    canvas.clipPath(clipPath);

    if (image != null) {
      final Paint paintImage = Paint()..filterQuality = FilterQuality.high;
      final double srcW = image.width.toDouble();
      final double srcH = image.height.toDouble();
      final double minDim = min(srcW, srcH);
      final double srcX = (srcW - minDim) / 2;
      final double srcY = (srcH - minDim) / 2;
      final Rect srcRect = Rect.fromLTWH(srcX, srcY, minDim, minDim);
      final Rect dstRect = Rect.fromLTWH(center.dx - radius + 2, center.dy - radius + 2, radius * 2 - 4, radius * 2 - 4);
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        paintImage,
      );
    } else if (isEmoji && imageUrl != null) {
      final Paint bgPaint = Paint()..color = const Color(0xFF151515);
      canvas.drawCircle(center, radius - 2, bgPaint);
      
      final TextPainter textPainter = TextPainter(
        textDirection: ui.TextDirection.ltr,
        text: TextSpan(text: imageUrl, style: const TextStyle(fontSize: 90)),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2) + 5),
      );
    } else {
      final Paint fallbackPaint = Paint()..color = const Color(0xFF1A1A1A);
      canvas.drawCircle(center, radius - 2, fallbackPaint);
    }
    
    canvas.restore();
    canvas.drawCircle(center, radius, borderPaint);

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _hasInitialLocation = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _hasInitialLocation = true);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _hasInitialLocation = true);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    
    String city = "Unknown";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? "Unknown";
      }
    } catch (_) {}

    if (mounted) {
      final appState = context.read<AppState>();
      appState.updateLocation(position.latitude, position.longitude, city);
      setState(() {
        _myLoc = LatLng(position.latitude, position.longitude);
        _myCity = city;
        _hasInitialLocation = true;
      });
      _recenterCamera();
    }
  }

  void _recenterCamera() {
    if (_mapController == null) return;
    HapticFeedback.mediumImpact();
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _myLoc, zoom: 15.5, tilt: 45.0)
      )
    );
  }

  void _showAvatarPicker() {
    final List<Map<String, String>> presets = [
      {'emoji': '🧑‍🎤', 'label': 'Rockstar'},
      {'emoji': '👩‍🎤', 'label': 'Diva'},
      {'emoji': '🦸‍♂️', 'label': 'Hero'},
      {'emoji': '🦸‍♀️', 'label': 'Heroine'},
      {'emoji': '🧑‍🚀', 'label': 'Explorer'},
      {'emoji': '👸', 'label': 'Princess'},
      {'emoji': '🤴', 'label': 'Prince'},
      {'emoji': '🧚‍♀️', 'label': 'Fairy'},
      {'emoji': '🧑‍🎨', 'label': 'Artist'},
      {'emoji': '💃', 'label': 'Dancer'},
      {'emoji': '🕺', 'label': 'Groove'},
      {'emoji': '🦊', 'label': 'Foxy'},
      {'emoji': '🐱', 'label': 'Kitty'},
      {'emoji': '🐻', 'label': 'Bear'},
      {'emoji': '🦋', 'label': 'Butterfly'},
      {'emoji': '🌸', 'label': 'Blossom'},
      {'emoji': '🔮', 'label': 'Mystic'},
      {'emoji': '💎', 'label': 'Diamond'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Color(0xE6120E17),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Choose Your Map Avatar', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Select a character or upload your photo', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 260,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: presets.length,
                      itemBuilder: (context, index) {
                        final preset = presets[index];
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _applyPresetAvatar(preset['emoji']!);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Center(
                              child: Text(preset['emoji']!, style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadCustomPhoto();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00FFFF), Color(0xFF8A2BE2)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Upload Custom Photo', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyPresetAvatar(String emoji) async {
    try {
      final appState = context.read<AppState>();
      final uid = appState.currentUid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'mapPinUrl': emoji,
      });

      _myPhotoUrlCache = null;
      await _loadCustomMarkers(uid, appState.currentCoupleId != null ? appState.partnerName : null);
    } catch (_) {}
  }

  Future<void> _pickAndUploadCustomPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading avatar...'), duration: Duration(seconds: 1)),
    );

    try {
      final appState = context.read<AppState>();
      final uid = appState.currentUid;
      if (uid == null) return;

      final file = File(image.path);
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'mapPinUrl': url,
        'photoUrl': url,
      });

      _myPhotoUrlCache = null; 
      await _loadCustomMarkers(uid, appState.partnerUid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')),
        );
      }
    }
  }

  Future<void> _launchDirections() async {
    if (!_hasPartnerLocation || (_partnerLoc.latitude == 0 && _partnerLoc.longitude == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Partner location is not available yet.")),
      );
      return;
    }
    final lat = _partnerLoc.latitude;
    final lng = _partnerLoc.longitude;
    final Uri nativeUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri);
      }
    } catch (e) {
      debugPrint("Could not launch maps: $e");
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  IconData _getWeatherIcon(String weather) {
    final lower = weather.toLowerCase();
    if (lower.contains('rain')) return Icons.water_drop_rounded;
    if (lower.contains('cloud')) return Icons.cloud_rounded;
    if (lower.contains('snow')) return Icons.ac_unit_rounded;
    if (lower.contains('thunder')) return Icons.flash_on_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF32D74B);
    if (aqi <= 100) return const Color(0xFFFFD60A);
    if (aqi <= 150) return const Color(0xFFFF9F0A);
    return const Color(0xFFFF453A);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Stack(
        children: [
          // Full Screen Google Map
          if (_hasInitialLocation)
            Positioned.fill(
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapController!.setMapStyle(darkMapStyle);
                  _recenterCamera();
                },
                mapType: _currentMapType,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                onTap: (_) {},
                onCameraMove: (CameraPosition position) {
                  if (position.zoom >= 16.0 && _currentMapType != MapType.hybrid) {
                    setState(() => _currentMapType = MapType.hybrid);
                  } else if (position.zoom < 16.0 && _currentMapType != MapType.normal) {
                    setState(() => _currentMapType = MapType.normal);
                  }
                },
                initialCameraPosition: CameraPosition(target: _myLoc, zoom: 15.5, tilt: 45),
                padding: const EdgeInsets.only(top: 90, bottom: 20),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('me'),
                    position: _myLoc,
                    icon: _myMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                    zIndex: 2,
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _myLoc, zoom: 16.5, tilt: 60.0),
                        ),
                      );
                      Future.delayed(const Duration(milliseconds: 400), _showAvatarPicker);
                    },
                  ),
                  if (_hasPartnerLocation)
                    Marker(
                      markerId: const MarkerId('partner'),
                      position: _partnerLoc,
                      icon: _partnerMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                      zIndex: 1,
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: _partnerLoc, zoom: 16.5, tilt: 60.0),
                          ),
                        );
                      },
                    ),
                },
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF00FFFF))),

          // Floating Frosted Glass Status HUD at the Top
          if (_hasInitialLocation)
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: SafeArea(
                child: _buildTopStatusHud(appState),
              ),
            ),

          // Floating Action Buttons for quick Map Navigation and Avatar
          if (_hasInitialLocation)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'recenter_map',
                    backgroundColor: const Color(0xDD0D0F17),
                    foregroundColor: const Color(0xFF00F0FF),
                    elevation: 4,
                    onPressed: _recenterCamera,
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'change_avatar',
                    backgroundColor: const Color(0xFFFF2E93),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    onPressed: _showAvatarPicker,
                    child: const Icon(Icons.face_retouching_natural_rounded, size: 20),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getAqiStatus(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    return 'High';
  }

  Widget _buildTopStatusHud(AppState appState) {
    final batteryColor = _partnerBattery <= 20
        ? const Color(0xFFFF453A)
        : (_partnerBattery <= 40 ? const Color(0xFFFF9F0A) : const Color(0xFF32D74B));

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xE6120D22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF2E93).withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFFF2E93).withOpacity(0.12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              // [ ❤️ ]
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF2E93).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFFFF2E93).withOpacity(0.4), width: 1),
                ),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF2E93), size: 14),
              ),
              _buildHudDivider(),

              // Metrics Row: [ 📍 Distance ] | [ ☀️ Weather ] | [ 🍃 AQI ] | [ ⚡ Battery ]
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // [ 📍 Real-time Distance ]
                      _buildHudMetric(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF00F0FF),
                        label: _hasPartnerLocation ? _distanceText : "Locating...",
                      ),
                      _buildHudDivider(),

                      // [ ☀️ Weather & Temp ]
                      _buildHudMetric(
                        icon: _getWeatherIcon(_partnerWeather),
                        iconColor: const Color(0xFFFFB800),
                        label: _partnerTemp,
                      ),
                      _buildHudDivider(),

                      // [ 🍃 AQI with color status ]
                      _buildHudMetric(
                        icon: Icons.eco_rounded,
                        iconColor: _getAqiColor(_partnerAqi),
                        label: "AQI $_partnerAqi",
                      ),
                      _buildHudDivider(),

                      // [ ⚡ Battery ]
                      _buildHudMetric(
                        icon: Icons.bolt_rounded,
                        iconColor: batteryColor,
                        label: "$_partnerBattery%",
                      ),
                    ],
                  ),
                ),
              ),

              _buildHudDivider(),

              // [ ↗ Directions ] CTA
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _launchDirections,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2E93), Color(0xFF00F0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2E93).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Directions',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudMetric({required IconData icon, required Color iconColor, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudDivider() {
    return Container(
      height: 14,
      width: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}


