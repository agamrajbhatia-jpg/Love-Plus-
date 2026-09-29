import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'photo_studio_modal.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/app_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';
import '../../widgets/pulsing_neon_border.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../services/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

Uint8List _compressImage(Uint8List list) {
  img.Image? decoded = img.decodeImage(list);
  if (decoded == null) return list;
  // Maintain high resolution, cap width at a large size like 2160 if needed for memory
  if (decoded.width > 2160) {
    decoded = img.copyResize(decoded, width: 2160);
  }
  return Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
}
class OOTDScreen extends StatefulWidget {
  const OOTDScreen({super.key});

  @override
  State<OOTDScreen> createState() => _OOTDScreenState();
}

class _OOTDScreenState extends State<OOTDScreen> {
  bool _isUploading = false;
  bool _showSuccessBadge = false;
  late AudioPlayer _audioPlayer;
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(BuildContext context, String coupleId, String currentUserId) async {
    final ImageSource? source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add OOTD'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 100);
    
    if (pickedFile == null || !mounted) return;

    final Uint8List? editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhotoStudioModal(imagePath: pickedFile.path))
    );

    if (editedImageBytes == null || !mounted) return;

    setState(() {
      _isUploading = true;
    });

    _processAndUpload(editedImageBytes, coupleId, currentUserId);
  }

  Future<void> _processAndUpload(Uint8List rawBytes, String coupleId, String currentUserId) async {
    try {
      final Uint8List compressedBytes = await compute(_compressImage, rawBytes);
      
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('ootd/$coupleId/$currentUserId/$fileName');
      
      final uploadTask = await ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('ootd').doc(currentUserId).set({
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'hypeCount': 0,
        'fitRating': 0.0
      }, SetOptions(merge: true));

      debugPrint("FCM PUSH TRIGGER: To Partner -> ✨ New Outfit Dropped! [Partner Name] just shared their Outfit of the Day. Tap to view!");

      if (mounted) {
        setState(() {
          _showSuccessBadge = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSuccessBadge = false);
        });
        _audioPlayer.play(AssetSource('sounds/cute_noise.wav'), volume: 1.0).catchError((_) {});
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.heavyImpact();        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OOTD Uploaded Successfully! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.currentCoupleId == null || appState.currentUid == null) {
      return const Center(child: Text("Please link with a partner first", style: TextStyle(color: Colors.white)));
    }

    final coupleId = appState.currentCoupleId!;
    final myUid = appState.currentUid!;
    final partnerUid = coupleId.split('_').firstWhere((id) => id != myUid, orElse: () => '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('couples')
                .doc(coupleId)
                .collection('ootd')
                .doc(partnerUid)
                .snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic>? partnerData;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                if (timestamp != null && _isToday(timestamp.toDate())) {
                  partnerData = data;
                }
              }

              return ListView(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 120.0, bottom: 40.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outfit of the Day',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Check out your partner's fit for today.",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5), width: 1.5),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.2), blurRadius: 12)],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFFF6B6B), strokeWidth: 2.5)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text('Uploading your OOTD to partner...', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('ootd').doc(myUid).snapshots(),
                      builder: (context, mySnapshot) {
                        if (mySnapshot.hasData && mySnapshot.data!.exists) {
                          final myData = mySnapshot.data!.data() as Map<String, dynamic>;
                          final myTimestamp = myData['timestamp'] as Timestamp?;
                          if (myTimestamp != null && _isToday(myTimestamp.toDate())) {
                            final myImageUrl = myData['imageUrl'] as String?;
                            if (myImageUrl != null) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 32.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0x20FFFFFF),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.15), blurRadius: 20, spreadRadius: 2)
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _showSuccessBadge 
                                                    ? Row(
                                                        children: [
                                                          const Icon(Icons.check_circle, color: Color(0xFFFF6B6B)),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text('Your outfit was successfully uploaded!', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                          ),
                                                        ],
                                                      )
                                                    : Row(
                                                        children: [
                                                          const Icon(Icons.person, color: Colors.white70, size: 20),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text("YOU • TODAY'S FIT", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                                                          ),
                                                        ],
                                                      ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _pickAndUploadImage(context, coupleId, myUid),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0x22FFFFFF),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: Colors.white24, width: 1),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                                        const SizedBox(width: 6),
                                                        Text('Update', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 800),
                                            child: CachedNetworkImage(
                                              imageUrl: myImageUrl,
                                              key: ValueKey<String>(myImageUrl),
                                              height: 350,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              fadeInDuration: const Duration(milliseconds: 300),
                                              placeholder: (context, url) => Container(
                                                height: 350,
                                                color: Colors.black12,
                                                child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B6B))),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                height: 350,
                                                color: Colors.black12,
                                                child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.black26)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildPartnerOotdCard(
                    context: context,
                    appState: appState,
                    coupleId: coupleId,
                    partnerUid: partnerUid,
                    partnerData: partnerData,
                  ),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),

        ],
      ),
      floatingActionButton: _isUploading ? null : Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: BouncingButton(
          onTap: () => _pickAndUploadImage(context, coupleId, myUid),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFEE0979)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEE0979).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Icon(Icons.add_a_photo, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerOotdCard({
    required BuildContext context,
    required AppState appState,
    required String coupleId,
    required String partnerUid,
    required Map<String, dynamic>? partnerData,
  }) {
    final theme = appState.chatTheme ?? appState.availableThemes.first;

    if (partnerData == null || partnerData['imageUrl'] == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515).withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.accentColor.withOpacity(0.28),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.white24, Colors.pinkAccent.withOpacity(0.15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: theme.accentColor.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                height: 400,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale + (0.05 * (scale == 1.0 ? 1 : -1)),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checkroom, size: 72, color: theme.accentColor.withOpacity(0.8)),
                        const SizedBox(height: 16),
                        Text(
                          "Waiting for ${appState.partnerName ?? 'Partner'}\nto post their outfit...",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.partnerName ?? 'Partner',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'No post yet today',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }
    final imageUrl = partnerData['imageUrl'] as String;
    final hypeCount = partnerData['hypeCount'] as int? ?? 0;
    final fitRating = (partnerData['fitRating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withOpacity(0.28),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.accentColor.withOpacity(0.6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HypePhotoWrapper(
              imageUrl: imageUrl,
              hypeCount: hypeCount,
              onHype: () {
                FirebaseFirestore.instance
                    .collection('couples')
                    .doc(coupleId)
                    .collection('ootd')
                    .doc(partnerUid)
                    .update({'hypeCount': FieldValue.increment(1)});
                // Send push notification to partner
                NotificationService.sendLocalNotification(
                  '${appState.userName ?? 'Your partner'} reacted 🔥',
                  '${appState.userName ?? 'Your partner'} reacted 🔥 to your Outfit of the Day!',
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (appState.partnerName ?? 'Partner').toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EDITORIAL • TODAY',
                              style: GoogleFonts.poppins(fontSize: 12, color: theme.accentColor, fontWeight: FontWeight.w600, letterSpacing: 2.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FitRatingSlider(
                    initialRating: fitRating,
                    coupleId: coupleId,
                    partnerUid: partnerUid,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FitRatingSlider extends StatefulWidget {
  final double initialRating;
  final String coupleId;
  final String partnerUid;

  const FitRatingSlider({
    super.key,
    required this.initialRating,
    required this.coupleId,
    required this.partnerUid,
  });

  @override
  State<FitRatingSlider> createState() => _FitRatingSliderState();
}

class _FitRatingSliderState extends State<FitRatingSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialRating;
  }

  @override
  void didUpdateWidget(FitRatingSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRating != oldWidget.initialRating) {
       _currentValue = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rating: ${_currentValue.toStringAsFixed(1)}/10',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _currentValue,
            min: 0.0,
            max: 10.0,
            activeColor: const Color(0xFFFF6B6B),
            inactiveColor: Colors.white12,
            onChanged: (val) {
              setState(() {
                _currentValue = val;
              });
            },
            onChangeEnd: (val) {
              FirebaseFirestore.instance
                  .collection('couples')
                  .doc(widget.coupleId)
                  .collection('ootd')
                  .doc(widget.partnerUid)
                  .update({'fitRating': val});
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hmm...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
              Text('Fire! 🔥', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}

class HypePhotoWrapper extends StatefulWidget {
  final String imageUrl;
  final int hypeCount;
  final VoidCallback onHype;

  const HypePhotoWrapper({
    super.key,
    required this.imageUrl,
    required this.hypeCount,
    required this.onHype,
  });

  @override
  State<HypePhotoWrapper> createState() => _HypePhotoWrapperState();
}

class _HypePhotoWrapperState extends State<HypePhotoWrapper> with TickerProviderStateMixin {
  final List<_FloatingEmoji> _emojis = [];
  int _localHypeCount = 0;

  @override
  void initState() {
    super.initState();
    _localHypeCount = widget.hypeCount;
  }

  @override
  void didUpdateWidget(HypePhotoWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hypeCount > _localHypeCount) {
      _localHypeCount = widget.hypeCount;
      _spawnEmojis();
    }
  }

  void _handleHypeTap() {
    widget.onHype();
    _localHypeCount++;
    _spawnEmojis();
  }

  void _spawnEmojis() {
    final random = Random();
    final emojisToSpawn = ['🔥', '😍', '🥵', '❤️'];
    
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + random.nextInt(400)),
      );
      
      final emoji = _FloatingEmoji(
        emoji: emojisToSpawn[random.nextInt(emojisToSpawn.length)],
        controller: controller,
        startX: 0.6 + random.nextDouble() * 0.3,
      );
      
      setState(() => _emojis.add(emoji));
      
      controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _emojis.remove(emoji);
          });
          controller.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var e in _emojis) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(
                height: 400,
                width: double.infinity,
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B6B)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 400,
                width: double.infinity,
                color: Colors.black12,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64, color: Colors.black26),
                ),
              ),
            ),
          ),
        ..._emojis.map((e) {
          return AnimatedBuilder(
            animation: e.controller,
            builder: (context, child) {
               final progress = e.controller.value;
               return Positioned(
                 bottom: 20 + (progress * 200),
                 left: MediaQuery.of(context).size.width * e.startX,
                 child: Opacity(
                   opacity: 1.0 - progress,
                   child: Text(
                     e.emoji,
                     style: TextStyle(fontSize: 32 + (progress * 20)),
                   ),
                 ),
               );
            },
          );
        }),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in ['🔥', '😍', '🥵', '❤️', '👏'])
                      BouncingButton(
                        onTap: () {
                          _handleHypeTap();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF1493), Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${widget.hypeCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}

class _FloatingEmoji {
  final String emoji;
  final AnimationController controller;
  final double startX;
  
  _FloatingEmoji({required this.emoji, required this.controller, required this.startX});
}




















