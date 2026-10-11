import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/app_state.dart';
import '../main.dart';
import 'premium_benefits_screen.dart';
import '../widgets/feature_walkthrough_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _isPremium = false;
  String _userName = '';
  String _userEmail = '';
  String _photoUrl = '';
  bool _isUploadingProfilePic = false;

  // In-App Purchase integration
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String _localizedPrice = '\$3.99';
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initInAppPurchases();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _initInAppPurchases() {
    try {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
      _purchaseSubscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          _purchaseSubscription?.cancel();
        },
        onError: (error) {
          debugPrint("Purchase stream error: $error");
          if (mounted) setState(() => _isPurchasing = false);
        },
      );
      _fetchProductPrice();
    } catch (e) {
      debugPrint("In-app purchase stream init failed: $e");
    }
  }

  Future<void> _fetchProductPrice() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) return;

      const Set<String> kIds = <String>{'loveplus_premium_monthly'};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.firstWhere(
          (p) => p.id == 'loveplus_premium_monthly',
          orElse: () => response.productDetails.first,
        );
        if (mounted) {
          setState(() {
            _localizedPrice = product.price;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching dynamic price: $e");
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isPurchasing = true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase error: ${purchaseDetails.error}");
          if (mounted) {
            setState(() => _isPurchasing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Purchase error: ${purchaseDetails.error?.message ?? "Failed"}')),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'isPremium': true,
            });
            if (mounted) {
              setState(() {
                _isPremium = true;
                _isPurchasing = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Welcome to Love Plus Premium! ✨')),
              );
            }
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleBuyPremium() async {
    try {
      setState(() => _isPurchasing = true);

      final bool isAvailable = await _inAppPurchase.isAvailable().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!isAvailable) {
        if (mounted) _showDemoUnlockBottomSheet();
        return;
      }

      const Set<String> kIds = <String>{'loveplus_premium_monthly'};
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(kIds)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => ProductDetailsResponse(
              productDetails: [],
              notFoundIDs: ['loveplus_premium_monthly'],
            ),
          );

      if (response.productDetails.isNotEmpty) {
        final ProductDetails productDetails = response.productDetails.first;
        final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        if (mounted) _showDemoUnlockBottomSheet();
      }
    } catch (e) {
      debugPrint("Error triggering purchase: $e");
      if (mounted) _showDemoUnlockBottomSheet();
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showDemoUnlockBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xE6140F24),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: const Color(0xFFFF2A6D).withOpacity(0.5), width: 1.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2A6D).withOpacity(0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Love Plus Premium',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google Play Billing is synchronizing monetization or awaiting Play Console setup. You can activate instant Demo / Test Unlock to experience all premium features right now!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureRow('✨ Unlimited AI Love Memos & Photo Studio'),
                        const SizedBox(height: 8),
                        _buildFeatureRow('🗺️ Live Radar & Instant Maps Navigation'),
                        const SizedBox(height: 8),
                        _buildFeatureRow('🎮 Full Unlocked Couple Game & Question Library'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _activateDemoPremium,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A6D).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '⚡ Activate Demo Unlock Now',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumBenefitsScreen()),
                      );
                    },
                    child: Text(
                      'View All Benefits & Pricing',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _activateDemoPremium() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isPremium': true,
        }, SetOptions(merge: true));
      }
      if (mounted) {
        setState(() {
          _isPremium = true;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E1035),
            content: Text('✨ Love Plus Premium activated in test mode! Enjoy all perks.'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error activating demo premium: $e");
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] ?? '';
        _isPremium = data['isPremium'] ?? false;
        _photoUrl = data['photoUrl'] ?? '';
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingProfilePic = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}');
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        setState(() {
          _photoUrl = downloadUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePic = false;
        });
      }
    }
  }

  void _unpairPartner() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '⚠️ Disconnect Partner',
          style: GoogleFonts.poppins(color: const Color(0xFFFF4D6D), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to unpair from your partner? You will need to link again to resume.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final appState = context.read<AppState>();
              final coupleId = appState.currentCoupleId;
              final uid = appState.currentUid;
              if (coupleId != null && uid != null) {
                final partnerUid = coupleId.split('_').firstWhere((id) => id != uid, orElse: () => '');

                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'isPaired': false,
                  'coupleId': FieldValue.delete(),
                  'partnerUid': FieldValue.delete(),
                });

                if (partnerUid.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').doc(partnerUid).update({
                    'isPaired': false,
                    'coupleId': FieldValue.delete(),
                    'partnerUid': FieldValue.delete(),
                  });
                }

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('coupleId');
                await prefs.remove('isPaired');

                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RootScreen()),
                    (route) => false,
                  );
                }
              }
            },
            child: const Text('Disconnect', style: TextStyle(color: Color(0xFFFF4D6D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    }
  }

  void _showGlassModal(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              border: Border(top: BorderSide(color: const Color(0xFFFF4D6D).withOpacity(0.5), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(content, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, height: 1.6)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6D).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.5)),
                    ),
                    child: Text('Close', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpAndSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xE6140F24),
              border: Border(top: BorderSide(color: const Color(0xFFFF2A6D).withOpacity(0.5), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Help & Support', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to the Love Plus Help Center.\n\n'
                          '• Live Radar & Distance: Requires location permissions enabled on both devices to stream real-time distance and battery metrics.\n'
                          '• Syncing & Chat: Make sure both partners have an active internet connection for real-time Firestore updates.\n'
                          '• Notifications: Push notifications are powered by high-priority background channels. Keep app notifications enabled in system settings.\n\n'
                          'For further inquiries or account help, email our team at support@coupleapp.com.',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.55),
                        ),
                        const SizedBox(height: 20),
                        // Replay Walkthrough Button
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            FeatureWalkthroughModal.show(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2A6D).withOpacity(0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Replay Feature Walkthrough',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text('Close', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF130E20), Color(0xFF09070F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _updateProfilePicture,
                            borderRadius: BorderRadius.circular(50),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const SweepGradient(
                                      colors: [Color(0xFFFF4D6D), Colors.cyan, Colors.deepPurple, Color(0xFFFF4D6D)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF4D6D).withOpacity(0.35),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                                    child: _photoUrl.isEmpty
                                        ? const Icon(Icons.person, size: 46, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                if (_isUploadingProfilePic)
                                  const Positioned.fill(
                                    child: CircularProgressIndicator(color: Color(0xFFFF4D6D)),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF4D6D),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _userName.isEmpty ? 'Love Plus User' : _userName,
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmail,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
                          ),
                          const SizedBox(height: 10),
                          _isPremium
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('👑', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Premium Member',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFFFD700),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Text(
                                    'Free Tier',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Premium Card with Dynamic Localized Price
                    if (!_isPremium) ...[
                      GestureDetector(
                        onTap: _isPurchasing ? null : _handleBuyPremium,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2A6D).withOpacity(0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(1.2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161026).withOpacity(0.78),
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                child: Row(
                                  children: [
                                    // Left: Gradient squircle icon containing a glowing star/crown icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF2A6D).withOpacity(0.4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Center: Clean typography
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Love Plus Premium',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Unlimited AI memos, live widgets & couple games',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Right: A pill button or chip displaying localized price tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF2A6D).withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                      ),
                                      child: _isPurchasing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(
                                              _localizedPrice.contains('/mo') ? _localizedPrice : '$_localizedPrice/mo',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // PREFERENCES SECTION (Unified Glassmorphism Card)
                    Text(
                      'PREFERENCES',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 1.0, color: Colors.white.withOpacity(0.12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 18,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingTile(
                                icon: Icons.notifications_rounded,
                                iconColor: const Color(0xFFFF4D6D),
                                iconBgColor: const Color(0xFFFF4D6D).withOpacity(0.15),
                                title: 'Enable Push Notifications',
                                trailing: Switch.adaptive(
                                  value: _pushEnabled,
                                  activeColor: const Color(0xFFFF4D6D),
                                  onChanged: (val) {
                                    setState(() => _pushEnabled = val);
                                  },
                                ),
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                icon: Icons.privacy_tip_rounded,
                                iconColor: const Color(0xFF4E95FF),
                                iconBgColor: const Color(0xFF4E95FF).withOpacity(0.15),
                                title: 'Privacy Policy',
                                onTap: () {
                                  _showGlassModal(
                                    'Privacy Policy',
                                    'Data Collection:\nWe collect Couple profile details, paired IDs, daily OOTD media uploads, and in-app chat communications to provide you with the best experience.\n\nSecurity & Storage:\nAll data is secured using industry-standard cloud encryption in transit (TLS/HTTPS) and at rest.\n\nData Control:\nYou have the full right to erase your data via the in-app account deletion tool. Deleting your account instantly removes all personal footprint, chats, and media from our servers.',
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                icon: Icons.help_outline_rounded,
                                iconColor: const Color(0xFF00D2B4),
                                iconBgColor: const Color(0xFF00D2B4).withOpacity(0.15),
                                title: 'Help & Support',
                                onTap: _showHelpAndSupport,
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFFFB800),
                                iconBgColor: const Color(0xFFFFB800).withOpacity(0.15),
                                title: 'Rate Love Plus',
                                onTap: () async {
                                  final Uri url =
                                      Uri.parse('https://play.google.com/store/apps/details?id=com.agam.loveplus');
                                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    debugPrint('Could not launch URL');
                                  }
                                },
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                icon: Icons.share_rounded,
                                iconColor: const Color(0xFFA855F7),
                                iconBgColor: const Color(0xFFA855F7).withOpacity(0.15),
                                title: 'Share Love Plus',
                                onTap: () {
                                  Share.share(
                                    'Join me on Love Plus! Connect with me here: https://play.google.com/store/apps/details?id=com.agam.loveplus',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ACCOUNT SECTION (Unified Glassmorphism Card)
                    Text(
                      'ACCOUNT',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 1.0, color: Colors.white.withOpacity(0.12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 18,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingTile(
                                icon: Icons.link_off_rounded,
                                iconColor: const Color(0xFFFF4D6D),
                                iconBgColor: const Color(0xFFFF4D6D).withOpacity(0.15),
                                title: 'Disconnect Partner',
                                titleColor: const Color(0xFFFF4D6D),
                                onTap: _unpairPartner,
                              ),
                              _buildDivider(),
                              _buildSettingTile(
                                icon: Icons.logout_rounded,
                                iconColor: Colors.white70,
                                iconBgColor: Colors.white.withOpacity(0.1),
                                title: 'Sign Out',
                                titleColor: Colors.white70,
                                onTap: _signOut,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: titleColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Colors.white38,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
