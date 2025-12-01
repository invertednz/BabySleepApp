import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/onboarding_payment_screen_new.dart';

class PremiumRequiredScreen extends StatelessWidget {
  const PremiumRequiredScreen({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF21F1D36), Color(0xE61F1D36)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(FeatherIcons.x, color: Colors.white),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 520,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 32,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(FeatherIcons.star, color: Color(0xFFA67EB7), size: 26),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Upgrade to BabySteps Premium',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F1D36),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Unlock Focus, Ask, Home, and deeper insights crafted to celebrate and guide every new moment.',
                          style: TextStyle(fontSize: 16, color: Color(0xFF4B5563), height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _BenefitRow(icon: FeatherIcons.award, text: 'Milestone analytics and celebration ideas crafted for your baby'),
                              SizedBox(height: 14),
                              _BenefitRow(icon: FeatherIcons.heart, text: 'Daily focus plans tailored to your child’s age and pace'),
                              SizedBox(height: 14),
                              _BenefitRow(icon: FeatherIcons.messageCircle, text: 'Unlimited expert guidance—ask the questions on your mind'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const OnboardingPaymentScreenNew(
                                        fromInAppUpgrade: true,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA67EB7),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text(
                                  'See plans',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            TextButton(
                              onPressed: onClose,
                              child: const Text(
                                'Not now',
                                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFA67EB7)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF433E5A), height: 1.5),
          ),
        ),
      ],
    );
  }
}
