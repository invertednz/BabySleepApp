import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_before_after_screen.dart';
import 'package:babysteps_app/services/purchase_service.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingSpecialDiscountScreenNew extends StatefulWidget {
  const OnboardingSpecialDiscountScreenNew({super.key});

  @override
  State<OnboardingSpecialDiscountScreenNew> createState() =>
      _OnboardingSpecialDiscountScreenNewState();
}

class _OnboardingSpecialDiscountScreenNewState
    extends State<OnboardingSpecialDiscountScreenNew> {
  bool _isProcessing = false;
  final PurchaseService _purchaseService = PurchaseService();

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool hasUser = authProvider.user != null;
    const String productId = ProductIds.gift;
    final String tier = planTierFromProductId(productId);

    if (!_purchaseService.isRealPurchasesPlatform) {
      // Web: use mock flow
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _onPurchaseSuccess(tier, hasUser, authProvider);
      return;
    }

    // iOS/Android: use real in-app purchase
    _purchaseService.onPurchaseUpdate = (result, {error, productId}) {
      if (!mounted) return;
      switch (result) {
        case PurchaseResult.success:
          _onPurchaseSuccess(tier, hasUser, authProvider);
          break;
        case PurchaseResult.cancelled:
          setState(() { _isProcessing = false; });
          break;
        case PurchaseResult.error:
          setState(() { _isProcessing = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Purchase failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case PurchaseResult.pending:
          break;
      }
    };

    final result = await _purchaseService.buyProduct(productId);
    if (result == PurchaseResult.error) {
      if (!mounted) return;
      setState(() { _isProcessing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start purchase. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onPurchaseSuccess(
    String tier,
    bool hasUser,
    AuthProvider authProvider,
  ) async {
    if (hasUser) {
      await authProvider.markUserAsPaid(onTrial: true, planTier: tier);
    } else {
      await authProvider.savePendingPlanUpgrade(
        planTier: tier,
        isOnTrial: true,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Welcome to BabySteps Premium.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (hasUser) {
      Navigator.of(context).pushReplacementWithFade(
        const AppContainer(initialIndex: 2),
      );
    } else {
      Navigator.of(context).pushReplacementWithFade(
        const LoginScreen(),
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _purchaseService.onPurchaseUpdate = null;
    super.dispose();
  }

  Future<void> _skipAsFreeUser() async {
    if (!mounted) return;
    // Require the user to sign up / log in before continuing with limited access.
    Navigator.of(context).pushReplacementWithFade(
      const LoginScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localGift = _purchaseService.displayPrice(ProductIds.gift, '\$29');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32.0),
          children: [
            OnboardingAppBar(
              onBackPressed: () {
                Navigator.of(context).pushReplacementWithFade(
                  const OnboardingBeforeAfterScreen(),
                );
              },
            ),
            const SizedBox(height: 16),
              // Special offer badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.card_giftcard, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'EXCLUSIVE OFFER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Headline
              const Text(
                'Give Your Child',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The Best Start in Life',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryPurple,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'For less than a cup of coffee per month',
                style: TextStyle(
                  fontSize: 17,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // Price hero section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.15),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SAVE \$79',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$108',
                          style: TextStyle(
                            fontSize: 28,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          '\$29',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryPurple,
                            height: 0.9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Just \$2.42 per month',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Benefits section
              _buildBenefit(
                Icons.psychology_outlined,
                'Boost Development',
                'Guided activities aligned with AAP guidelines can support your child\'s cognitive growth*',
              ),
              const SizedBox(height: 16),
              _buildBenefit(
                Icons.trending_up,
                'Track & Celebrate Progress',
                'Milestone awareness helps parents identify developmental needs and celebrate wins*',
              ),
              const SizedBox(height: 16),
              _buildBenefit(
                Icons.favorite_outline,
                'Create Lasting Memories',
                'Capture every precious moment as your baby grows—memories you\'ll treasure forever',
              ),
              const SizedBox(height: 16),
              _buildBenefit(
                Icons.lightbulb_outline,
                'Reduce Parenting Stress',
                'Get expert guidance exactly when you need it—no more endless googling at 2 AM',
              ),
              const SizedBox(height: 32),
              // Social proof
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star,
                          color: Color(0xFFFBBF24),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '"This app helped me feel so much more confident about my baby\'s progress. Worth every penny!"',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '— Verified BabySteps Parent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Urgency messaging
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.access_time, color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This special price is only available right now',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment charged to your Apple ID or Google Play account at confirmation. Subscription auto-renews at $localGift/yr unless cancelled at least 24 hrs before period end. Manage in device settings. *Based on AAP (American Academy of Pediatrics) child development guidelines.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // CTA Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkPurple, AppTheme.primaryPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_isProcessing ? _handlePayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Invest in Your Child\'s Future',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
              if (_purchaseService.isRealPurchasesPlatform)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: _isProcessing ? null : () => _purchaseService.restorePurchases(),
                      child: const Text(
                        'Restore Purchases',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                '\$29/year • Cancel anytime • 100% secure',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _skipAsFreeUser,
              child: const Text(
                'No thanks, continue with limited access',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.2),
                  AppTheme.primaryPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryPurple,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
