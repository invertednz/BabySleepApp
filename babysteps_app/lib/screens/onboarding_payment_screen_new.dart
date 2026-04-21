import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_before_after_screen.dart';
import 'package:babysteps_app/screens/onboarding_annual_plan_screen.dart';
import 'package:babysteps_app/services/purchase_service.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingPaymentScreenNew extends StatefulWidget {
  final bool fromInAppUpgrade;

  const OnboardingPaymentScreenNew({
    super.key,
    this.fromInAppUpgrade = false,
  });

  @override
  State<OnboardingPaymentScreenNew> createState() => _OnboardingPaymentScreenNewState();
}

class _OnboardingPaymentScreenNewState extends State<OnboardingPaymentScreenNew> {
  bool _isProcessing = false;
  String _selectedPlan = 'yearly';
  final PurchaseService _purchaseService = PurchaseService();

  String _getProductIdForSelectedPlan() {
    switch (_selectedPlan) {
      case 'monthly':
        return ProductIds.monthly;
      case 'payforward':
        return ProductIds.payforward;
      case 'yearly':
      default:
        return ProductIds.yearly;
    }
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool hasUser = authProvider.user != null;
    final String productId = _getProductIdForSelectedPlan();
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
      await authProvider.markUserAsPaid(onTrial: false, planTier: tier);
    } else {
      await authProvider.savePendingPlanUpgrade(
        planTier: tier,
        isOnTrial: false,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Your BabySteps plan is now active.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (!hasUser && !widget.fromInAppUpgrade) {
      Navigator.of(context).pushReplacementWithFade(
        const LoginScreen(),
      );
    } else {
      Navigator.of(context).pushReplacementWithFade(
        const AppContainer(initialIndex: 2),
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

  void _skipToComparison() {
    Navigator.of(context).pushReplacementWithFade(
      const OnboardingBeforeAfterScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int standardMonthlyPrice = 15;
    const int discountedMonthlyPrice = 9;
    const int yearlyPrice = 49;
    const int payForwardPrice = 59;

    final localMonthly = _purchaseService.displayPrice(ProductIds.monthly, '\$$discountedMonthlyPrice');
    final localYearly = _purchaseService.displayPrice(ProductIds.yearly, '\$$yearlyPrice');
    final localPayforward = _purchaseService.displayPrice(ProductIds.payforward, '\$$payForwardPrice');

    final bool isYearly = _selectedPlan == 'yearly';
    final bool isMonthly = _selectedPlan == 'monthly';
    final bool isPayForward = _selectedPlan == 'payforward';

    const int annualCostMonthlyPlan = standardMonthlyPrice * 12;
    final int yearlySavings = annualCostMonthlyPlan - yearlyPrice;
    final int monthlySavings = standardMonthlyPrice - discountedMonthlyPrice;

    double afterTrialPrice;
    String billingPeriodLabel;

    if (_selectedPlan == 'monthly') {
      afterTrialPrice = discountedMonthlyPrice.toDouble();
      billingPeriodLabel = 'month';
    } else if (_selectedPlan == 'payforward') {
      afterTrialPrice = payForwardPrice.toDouble();
      billingPeriodLabel = 'year';
    } else {
      afterTrialPrice = yearlyPrice.toDouble();
      billingPeriodLabel = 'year';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingAppBar(
                onBackPressed: () {
                  Navigator.of(context).pushReplacementWithFade(
                    const OnboardingAnnualPlanScreen(),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Compare Plans',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Full access to BabySteps. Cancel anytime.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Most Popular badge for annual
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                selected: isYearly,
                onTap: () => setState(() => _selectedPlan = 'yearly'),
                title: 'Yearly Plan',
                mainPrice: localYearly,
                mainSuffix: '/year',
                trailingLabel: '\$4/month',
                savingsLabel: 'Save \$${yearlySavings} per year vs the standard monthly price',
              ),
              const SizedBox(height: 16),
              _buildPlanCard(
                selected: isMonthly,
                onTap: () => setState(() => _selectedPlan = 'monthly'),
                title: 'Monthly Plan',
                mainPrice: localMonthly,
                mainSuffix: '/month',
                subtitle: 'Billed monthly',
                savingsLabel: 'Usually \$15/month – save \$${monthlySavings} every month',
              ),
              const SizedBox(height: 16),
              // Pay It Forward badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.favorite, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'HELP ANOTHER PARENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                selected: isPayForward,
                onTap: () => setState(() => _selectedPlan = 'payforward'),
                title: 'Pay It Forward',
                mainPrice: localPayforward,
                mainSuffix: '/year',
                trailingLabel: 'Avg. \$${(payForwardPrice / 12).toStringAsFixed(2)}/mo',
                badge: '+\$10 DONATION',
                badgeColor: Color(0xFFEC4899),
                savingsLabel: 'Your \$10 donation is matched by us to help another parent access BabySteps',
              ),
              const SizedBox(height: 32),
              _buildWhatsIncludedSection(),
              const SizedBox(height: 24),
              _buildSummarySection(afterTrialPrice, billingPeriodLabel),
              const SizedBox(height: 24),
              const Text(
                'Payment charged to your Apple ID or Google Play account at confirmation. Subscription auto-renews unless cancelled at least 24 hrs before period end. Manage in device settings.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _buildCtaButton(),
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
              Center(
                child: TextButton(
                  onPressed: _skipToComparison,
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
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

  Widget _buildPlanCard({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required String mainPrice,
    required String mainSuffix,
    String? subtitle,
    String? trailingLabel,
    String? badge,
    String? savingsLabel,
    Color badgeColor = const Color(0xFF10B981),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8F2FC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryPurple : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppTheme.primaryPurple : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                    color: selected ? AppTheme.primaryPurple : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mainPrice,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    mainSuffix,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (trailingLabel != null)
                  Text(
                    trailingLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (savingsLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                savingsLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsIncludedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeature('Unlimited milestone tracking'),
          const SizedBox(height: 12),
          _buildFeature('Personalized daily activities'),
          const SizedBox(height: 12),
          _buildFeature('Expert-backed insights'),
          const SizedBox(height: 12),
          _buildFeature('Progress reports & analytics'),
          const SizedBox(height: 12),
          _buildFeature('Cancel anytime'),
        ],
      ),
    );
  }

  Widget _buildSummarySection(double afterTrialPrice, String billingPeriodLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: const Text(
        'You will be charged the price shown for your chosen plan. You can change or cancel your subscription anytime.',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCtaButton() {
    return SizedBox(
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
                'Continue with selected plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: AppTheme.primaryPurple,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}