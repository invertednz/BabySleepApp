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

class OnboardingPaymentScreen extends StatefulWidget {
  const OnboardingPaymentScreen({super.key});

  @override
  State<OnboardingPaymentScreen> createState() => _OnboardingPaymentScreenState();
}

class _OnboardingPaymentScreenState extends State<OnboardingPaymentScreen> {
  bool _isProcessing = false;
  final PurchaseService _purchaseService = PurchaseService();

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool hasUser = authProvider.user != null;
    const String productId = ProductIds.monthly;
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
        content: Text('Payment successful! Your 3-day free trial has started.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (!hasUser) {
      Navigator.of(context).pushReplacementWithFade(
        const LoginScreen(),
      );
    } else {
      Navigator.of(context).pushReplacementWithFade(
        const AppContainer(initialIndex: 2),
      );
    }
  }

  @override
  void dispose() {
    _purchaseService.onPurchaseUpdate = null;
    super.dispose();
  }

  void _skipToComparison() {
    Navigator.of(context).pushReplacementWithFade(
      const OnboardingBeforeAfterScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = _purchaseService.displayPrice(ProductIds.monthly, '\$9');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingBeforeAfterScreen(),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Start Your Free Trial',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No charge for 3 days. Cancel anytime.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F2FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BabySteps Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$monthlyPrice/mo',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '\$0.00',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'After 3 days',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          monthlyPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Spacer(),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy. Payment charged to your Apple ID or Google Play account at confirmation. Subscription auto-renews at $monthlyPrice/mo unless cancelled at least 24 hrs before period end. Manage in device settings.',
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
                    elevation: 0,
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
                          'Start Free Trial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}
