import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LovePlusPaywallModal extends StatefulWidget {
  const LovePlusPaywallModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LovePlusPaywallModal(),
    );
  }

  @override
  State<LovePlusPaywallModal> createState() => _LovePlusPaywallModalState();
}

class _LovePlusPaywallModalState extends State<LovePlusPaywallModal> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Annual (Best Value)
  bool _isLoading = false;
  String _monthlyPrice = '£3.99 / mo';
  String _annualPrice = '£24.99 / yr';
  ProductDetails? _monthlyProduct;
  ProductDetails? _annualProduct;

  @override
  void initState() {
    super.initState();
    _initBillingStream();
    _fetchProducts();
  }

  void _initBillingStream() {
    try {
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _purchaseSubscription = purchaseUpdated.listen(
        _listenToPurchaseUpdated,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          debugPrint("Purchase stream error: $error");
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      debugPrint("IAP Stream setup failed: $e");
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) return;

      const Set<String> productIds = {
        'loveplus_premium_monthly',
        'loveplus_premium_annual',
      };

      final response = await _inAppPurchase.queryProductDetails(productIds);
      if (response.productDetails.isNotEmpty && mounted) {
        setState(() {
          for (final p in response.productDetails) {
            if (p.id == 'loveplus_premium_monthly') {
              _monthlyProduct = p;
              _monthlyPrice = '${p.price} / month';
            } else if (p.id == 'loveplus_premium_annual') {
              _annualProduct = p;
              _annualPrice = '${p.price} / year';
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching IAP products: $e");
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isLoading = true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase error: ${purchaseDetails.error}");
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment error: ${purchaseDetails.error?.message ?? "Cancelled"}')),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'isPremium': true,
            }, SetOptions(merge: true));

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_premium_user', true);

            if (mounted) {
              setState(() => _isLoading = false);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF1E1035),
                  content: Text('✨ Welcome to Love Plus Premium! All features unlocked.'),
                ),
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

  Future<void> _handleBuy() async {
    setState(() => _isLoading = true);
    try {
      final ProductDetails? targetProduct = _selectedPlanIndex == 0 ? _monthlyProduct : _annualProduct;
      if (targetProduct != null) {
        final purchaseParam = PurchaseParam(productDetails: targetProduct);
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Fallback or retry query
        const Set<String> productIds = {'loveplus_premium_monthly', 'loveplus_premium_annual'};
        final response = await _inAppPurchase.queryProductDetails(productIds);
        if (response.productDetails.isNotEmpty) {
          final p = response.productDetails.first;
          await _inAppPurchase.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connecting to Google Play Store... Please ensure billing is enabled.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error starting purchase: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Play billing service currently unavailable.')),
          );
        }
        return;
      }
      await _inAppPurchase.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found or restore error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0B18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xF0180F2A), Color(0xF00A0713)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFF2A6D).withOpacity(0.55),
                  width: 1.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Handle and Close Button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Official App Logo Hero in Glowing Frosted Container
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFF2A6D).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A6D).withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title & Subtitle
                    Text(
                      'Unlock Love Plus Premium',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Supercharge your connection with infinite AI creations & zero game cooldowns',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 2 Core Premium Benefits
                    _buildFeatureItem(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFFF2A6D),
                      title: 'Unlimited AI Generations',
                      subtitle: 'Generate infinite photo memos & memories from the Love Memo shop without limits.',
                    ),
                    _buildFeatureItem(
                      icon: Icons.sports_esports_rounded,
                      iconColor: const Color(0xFF9B51E0),
                      title: 'Zero Waiting Time on Games',
                      subtitle: 'Skip all cooldowns & play couple cards and quizzes with zero waiting time.',
                    ),

                    const SizedBox(height: 20),

                    // Pricing Selectors (Monthly vs Annual)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            index: 0,
                            title: 'Monthly',
                            price: _monthlyPrice,
                            subtext: 'Billed monthly',
                            badge: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            index: 1,
                            title: 'Annual',
                            price: _annualPrice,
                            subtext: 'Just ~£2.08 / month',
                            badge: 'BEST VALUE - SAVE 40%',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Primary Action Button ("Continue" / "Start Free Trial")
                    GestureDetector(
                      onTap: _isLoading ? null : _handleBuy,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2A6D), Color(0xFF9B51E0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withOpacity(0.42),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                )
                              : Text(
                                  'Continue with ${_selectedPlanIndex == 1 ? "Annual" : "Monthly"}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Restore Purchases & Legal Links (Wrap prevents any screen overflow)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : _handleRestore,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Restore Purchases',
                            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                          ),
                        ),
                        const Text('•', style: TextStyle(color: Colors.white30, fontSize: 11)),
                        TextButton(
                          onPressed: () => _launchUrl('https://coupleapp.com/terms'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Terms of Service',
                            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                          ),
                        ),
                        const Text('•', style: TextStyle(color: Colors.white30, fontSize: 11)),
                        TextButton(
                          onPressed: () => _launchUrl('https://coupleapp.com/privacy'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.32), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String subtext,
    String? badge,
  }) {
    final bool isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24153A) : const Color(0xFF161024),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2A6D) : Colors.white12,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF2A6D).withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2A6D), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              const SizedBox(height: 19),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFFFF2A6D) : Colors.white38,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFFFF2A6D) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
