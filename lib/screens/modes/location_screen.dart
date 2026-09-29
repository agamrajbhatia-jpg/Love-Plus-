import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:material_ui/material_ui.dart';
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

  bool _showDistanceCard = false;
  bool _hasInitialLocation = false;
  bool _isMapInitialized = false;
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
        _loadCustomMarkers(appState.currentUid, appState.currentCoupleId != null ? appState.partnerName : null);
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
    }
    
    if (foundPartner) {
      final double distanceInMeters = Geolocator.distanceBetween(
        newMyLoc.latitude, newMyLoc.longitude,
        newPartnerLoc.latitude, newPartnerLoc.longitude,
      );
      final double miles = distanceInMeters / 1609.34;
      if (distanceInMeters < 1000) {
        _distanceText = "In the same area!";
      } else {
        _distanceText = "\ miles apart";
      }
    } else {
      _distanceText = "Connect partner to view live distance";
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
    
    final Color haloColor = isMe ? const Color(0xFF00FFFF) : const Color(0xFFFFB300);
    final Color glowColor = isMe ? const Color(0xFF8A2BE2) : const Color(0xFFE11D48);
    final double radius = 85.0;
    final Offset center = Offset(size / 2, size / 2.2);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(center.dx, center.dy + 15), radius, shadowPaint);

    final Paint pulseGlowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius + 15, pulseGlowPaint);
    
    final Paint neonRingPaint = Paint()
      ..color = haloColor.withOpacity(0.6)
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
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
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
      final Paint paintImage = Paint();
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(center.dx - radius + 2, center.dy - radius + 2, radius * 2 - 4, radius * 2 - 4),
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
      await _loadCustomMarkers(uid, appState.currentCoupleId != null ? appState.partnerName : null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Stack(
        children: [
          if (_hasInitialLocation)
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController!.setMapStyle(darkMapStyle);
                _isMapInitialized = true;
                _recenterCamera();
              },
              mapType: _currentMapType,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              onTap: (_) {
                if (_showDistanceCard) setState(() => _showDistanceCard = false);
              },
              onCameraMove: (CameraPosition position) {
                if (position.zoom >= 16.0 && _currentMapType != MapType.hybrid) {
                  setState(() => _currentMapType = MapType.hybrid);
                } else if (position.zoom < 16.0 && _currentMapType != MapType.normal) {
                  setState(() => _currentMapType = MapType.normal);
                }
              },
              initialCameraPosition: CameraPosition(target: _myLoc, zoom: 15.5, tilt: 45),
              padding: const EdgeInsets.only(bottom: 120),
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
                    setState(() => _showDistanceCard = true);
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _myLoc, zoom: 16.5, tilt: 60.0)
                      )
                    );
                    // Open avatar selection after a slight delay
                    Future.delayed(const Duration(milliseconds: 500), _showAvatarPicker);
                  },
                ),
                if (_hasPartnerLocation)
                  Marker(
                    markerId: const MarkerId('partner'),
                    position: _partnerLoc,
                    icon: _partnerMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                    zIndex: 1,
                    onTap: () {
                      setState(() => _showDistanceCard = true);
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _partnerLoc, zoom: 16.5, tilt: 60.0)
                        )
                      );
                    },
                  ),
              },
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF00FFFF))),

          if (_hasInitialLocation)
            Positioned(
              bottom: 110,
              left: 16,
              right: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _showDistanceCard
                  ? _PartnerStatusHud(
                      key: const ValueKey('full_card'),
                      distanceText: _distanceText,
                      myCity: _myCity,
                      partnerCity: _hasPartnerLocation ? _partnerCity : 'Waiting...',
                      timeText: _timeText,
                      partnerName: appState.partnerName ?? 'Partner',
                      onClose: () => setState(() => _showDistanceCard = false),
                    )
                  : GestureDetector(
                      key: const ValueKey('capsule'),
                      onTap: () => setState(() => _showDistanceCard = true),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white24, width: 1),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.radar, color: Color(0xFFE11D48), size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _distanceText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}

class _PartnerStatusHud extends StatelessWidget {
  final String distanceText;
  final String myCity;
  final String partnerCity;
  final String timeText;
  final String partnerName;
  final VoidCallback onClose;
  
  const _PartnerStatusHud({
    super.key,
    required this.distanceText,
    required this.myCity,
    required this.partnerCity,
    required this.timeText,
    required this.partnerName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x22000000),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFE11D48).withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, color: Color(0xFFE11D48), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(partnerName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 28),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF00FFFF), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(partnerCity, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.social_distance, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(distanceText, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 16),
              Text(timeText, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

