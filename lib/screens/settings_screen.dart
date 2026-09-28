import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../main.dart';
import 'premium_benefits_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        title: Text('⚠️ Disconnect Partner', style: GoogleFonts.poppins(color: const Color(0xFFFF4D6D), fontWeight: FontWeight.bold)),
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
      )
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  )
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
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF007F), Color(0xFF000033)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Settings', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  children: [
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
                                      BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
                                    ]
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white24,
                                    backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                                    child: _photoUrl.isEmpty 
                                      ? const Icon(Icons.person, size: 50, color: Colors.white) 
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
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(_userEmail, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                          const SizedBox(height: 16),
                          _isPremium 
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('👑', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text('Premium Member', style: GoogleFonts.poppins(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              )
                            : Text('Free Tier', style: GoogleFonts.poppins(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (!_isPremium)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumBenefitsScreen()));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.03)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(color: Colors.pinkAccent.withOpacity(0.15), blurRadius: 25, spreadRadius: 2)
                                ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Unlock Premium ✨', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('Generate unlimited AI content, remove all limits & unlock all games!', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Upgrade Now >', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    if (!_isPremium) const SizedBox(height: 32),

                    Text('PREFERENCES', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.03)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(color: Colors.pinkAccent.withOpacity(0.15), blurRadius: 25, spreadRadius: 2)
                            ]
                          ),
                          child: Column(
                            children: [
                              _buildSettingTile(
                                icon: Icons.notifications, 
                                title: 'Enable Push Notifications', 
                                trailing: Switch(
                                  value: _pushEnabled,
                                  activeColor: const Color(0xFFFF4D6D),
                                  onChanged: (val) {
                                    setState(() => _pushEnabled = val);
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildSettingTile(
                                icon: Icons.privacy_tip, 
                                title: 'Privacy Policy', 
                                onTap: () {
                                  _showGlassModal('Privacy Policy', 'Data Collection:\nWe collect Couple profile details, paired IDs, daily OOTD media uploads, and in-app chat communications to provide you with the best experience.\n\nSecurity & Storage:\nAll data is secured using industry-standard cloud encryption in transit (TLS/HTTPS) and at rest.\n\nData Control:\nYou have the full right to erase your data via the in-app account deletion tool. Deleting your account instantly removes all personal footprint, chats, and media from our servers.');
                                }
                              ),
                              const SizedBox(height: 8),
                              _buildSettingTile(
                                icon: Icons.help_center, 
                                title: 'Help & Support', 
                                onTap: () {
                                  _showGlassModal('Help & Support', 'Welcome to the Help Center.\n\nIf you have any issues with pairing, syncing, or missing data, please ensure both partners are on the latest version of the app and have stable internet connections.\n\nFor further assistance, reach out to our support team at support@coupleapp.com.');
                                }
                              ),
                            ]
                          )
                        )
                      )
                    ),

                    const SizedBox(height: 24),
                    Text('ACCOUNT', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.03)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(color: Colors.pinkAccent.withOpacity(0.15), blurRadius: 25, spreadRadius: 2)
                            ]
                          ),
                          child: Column(
                            children: [
                              _buildSettingTile(
                                icon: Icons.link_off, 
                                title: 'Disconnect Partner', 
                                textColor: const Color(0xFFFF4D6D),
                                iconColor: const Color(0xFFFF4D6D),
                                onTap: _unpairPartner,
                              ),
                              const SizedBox(height: 8),
                              _buildSettingTile(
                                icon: Icons.logout, 
                                title: 'Sign Out', 
                                textColor: Colors.white70,
                                onTap: _signOut,
                              ),
                            ]
                          )
                        )
                      )
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon, 
    required String title, 
    String? subtitle,
    Widget? trailing, 
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D6D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFFFF4D6D), size: 20),
      ),
      title: Text(title, style: GoogleFonts.poppins(color: textColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
      onTap: onTap,
    );
  }
}

