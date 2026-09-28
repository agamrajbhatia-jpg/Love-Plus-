import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/premium_gate_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumBenefitsScreen extends StatefulWidget {
  const PremiumBenefitsScreen({Key? key}) : super(key: key);

  @override
  State<PremiumBenefitsScreen> createState() => _PremiumBenefitsScreenState();
}

class _PremiumBenefitsScreenState extends State<PremiumBenefitsScreen> {
  int _selectedPlanIndex = 1; // Defaults to Annual Plan
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      Package? packageToBuy;
      
      if (_selectedPlanIndex == 0) packageToBuy = offerings.current?.monthly;
      if (_selectedPlanIndex == 1) packageToBuy = offerings.current?.annual;

      if (packageToBuy != null) {
        final result = await Purchases.purchasePackage(packageToBuy);
        if (result.customerInfo.entitlements.all["premium"]?.isActive == true) {
          await PremiumGateService.upgradeToPremium();
          if (mounted) Navigator.pop(context); 
        }
      }
    } catch (e) {
      debugPrint("Purchase failed: $e");
      // Optional: Show a snackbar error here
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: _buildAmbientGlow(const Color(0xFFE100FF))),
          Positioned(bottom: -50, right: -50, child: _buildAmbientGlow(const Color(0xFF00FFD1))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Unlock Infinite\nConnection.",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bridge the miles with zero limits, exclusive features, and cloud history.",
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildFeatureRow(Icons.all_inclusive, "Unlimited Daily Games", "Play as much as you want. No daily limits."),
                  _buildFeatureRow(Icons.camera_alt_rounded, "Unlimited Love Memos", "Generate endless photos in the Love Memo Shop."),
                  _buildFeatureRow(Icons.cloud_sync_rounded, "OOTD Cloud History", "Unlock your 30-day outfit history, split for you and your partner."),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(child: _buildPricingCard(index: 0, title: "Monthly", price: "\$3.99", subtitle: "/mo")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPricingCard(index: 1, title: "Annual", price: "\$25.99", subtitle: "/yr", badge: "BEST VALUE")),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  GestureDetector(
                    onTap: _isLoading ? null : _handlePurchase,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE100FF), Color(0xFF00FFD1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE100FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("UPGRADE NOW", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A2E),
                            title: const Text("Terms & Conditions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const SingleChildScrollView(
                              child: Text(
                                "By subscribing to Love Plus Premium, you agree to our terms of service.\n\n"
                                "Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. "
                                "You can manage or cancel your subscription anytime through your app store account settings.\n\n"
                                "Refunds are subject to the policies of the respective app store.",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close", style: TextStyle(color: Color(0xFF00FFD1))),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Cancel anytime. Terms & Conditions apply.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow(Color color) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: const Color(0xFF00FFD1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({required int index, required String title, required String price, required String subtitle, String? badge}) {
    final isSelected = _selectedPlanIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE100FF).withOpacity(0.1) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFFE100FF) : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1),
            ),
            child: Column(
              children: [
                Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Text(price, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSelected ? 22 : 20)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF00FFD1), borderRadius: BorderRadius.circular(20)),
                child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
