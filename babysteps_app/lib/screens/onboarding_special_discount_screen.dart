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

class OnboardingSpecialDiscountScreen extends StatefulWidget {
  const OnboardingSpecialDiscountScreen({super.key});

  @override
  State<OnboardingSpecialDiscountScreen> createState() =>
      _OnboardingSpecialDiscountScreenState();
}

class _OnboardingSpecialDiscountScreenState
    extends State<OnboardingSpecialDiscountScreen> {
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
    _purchaseService.onPurchaseUpdate = (result, {error}) {
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingBeforeAfterScreen(),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Spacer(),
              // Urgency badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'ONE-TIME OFFER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Last Chance',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'Get '),
                    TextSpan(
                      text: '73% off',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    TextSpan(text: ' your first year'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.1),
                      AppTheme.primaryPurple.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$108',
                          style: TextStyle(
                            fontSize: 24,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '\$29',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '/year',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Just \$2.42/month • Cancel anytime',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.savings, color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save \$79 vs monthly',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'This exclusive offer expires when you leave this page.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Text(
                'Payment charged to your Apple ID or Google Play account at confirmation. Subscription auto-renews at $localGift/yr unless cancelled at least 24 hrs before period end. Manage in device settings.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text(
                          'Claim 73% Off Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
              const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
