import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';

class OnboardingSpecialDiscountScreen extends StatefulWidget {
  const OnboardingSpecialDiscountScreen({super.key});

  @override
  State<OnboardingSpecialDiscountScreen> createState() =>
      _OnboardingSpecialDiscountScreenState();
}

class _OnboardingSpecialDiscountScreenState
    extends State<OnboardingSpecialDiscountScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing (accepts any input)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Mark user as paid with trial
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.markUserAsPaid(onTrial: true);

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Welcome to BabySteps Premium.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppContainer(initialIndex: 3),
      ),
    );
  }

  Future<void> _skipAsFreeUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.markUserAsFree();

    if (!mounted) return;

    // Navigate to main app as free user
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppContainer(initialIndex: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
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
                      text: '50% off',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    TextSpan(text: ' your first 3 months'),
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
                          '\$9.99',
                          style: TextStyle(
                            fontSize: 24,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '\$4.99',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '/mo',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For the first 3 months',
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
                            'Save \$15 total',
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
                          'Claim 50% Off Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
