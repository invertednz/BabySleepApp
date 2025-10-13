import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/onboarding_before_after_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'dart:math' as math;

class OnboardingSpecialDiscountScreenNew extends StatefulWidget {
  const OnboardingSpecialDiscountScreenNew({super.key});

  @override
  State<OnboardingSpecialDiscountScreenNew> createState() =>
      _OnboardingSpecialDiscountScreenNewState();
}

class _OnboardingSpecialDiscountScreenNewState
    extends State<OnboardingSpecialDiscountScreenNew>
    with SingleTickerProviderStateMixin {
  bool _hasSpun = false;
  bool _isProcessing = false;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  final List<Map<String, dynamic>> _wheelOptions = [
    {'label': 'No discount', 'color': Color(0xFF8B5CF6), 'isWinner': false},
    {'label': '\$5 off', 'color': Color(0xFFEC4899), 'isWinner': false},
    {'label': 'Extra spin', 'color': Color(0xFF3B82F6), 'isWinner': false},
    {'label': '\$35/year', 'color': Color(0xFF10B981), 'isWinner': false},
    {'label': 'No discount', 'color': Color(0xFFF97316), 'isWinner': false},
    {'label': '72% discount', 'color': Color(0xFFEF4444), 'isWinner': true},
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _spinController.addStatusListener((status) {
      if (mounted) {
        setState(() {});
      }
    });

    // Spin to land on the "72% discount" option (index 5)
    final targetRotation = (math.pi * 2 * 5) + (11 * math.pi / 6); // 5 full rotations + position of sixth segment
    _spinAnimation = Tween<double>(
      begin: 0,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));

    // Auto-spin when screen loads
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasSpun) {
        _spinWheel();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_hasSpun) return;
    setState(() {
      _hasSpun = true;
    });
    _spinController.forward();
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.markUserAsPaid(onTrial: true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Welcome to BabySteps Premium.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.of(context).pushReplacementWithFade(
      const AppContainer(initialIndex: 2),
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _skipAsFreeUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.markUserAsFree();

    if (!mounted) return;

    Navigator.of(context).pushReplacementWithFade(
      const AppContainer(initialIndex: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),
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
                'Spin to Win!',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your exclusive discount awaits',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Spinning Wheel
              Stack(
                alignment: Alignment.center,
                children: [
                  // Wheel
                  AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _spinAnimation.value,
                        child: CustomPaint(
                          size: const Size(364, 364),
                          painter: WheelPainter(options: _wheelOptions),
                        ),
                      );
                    },
                  ),
                  // Center button
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFFFBBF24),
                      size: 32,
                    ),
                  ),
                  // Pointer at top
                  Positioned(
                    top: -10,
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 50,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Result display (only show after spin completes)
              AnimatedOpacity(
                opacity: _spinController.isCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
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
                      const Text(
                        '🎉 You Won!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            '\$30',
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
                        'Just \$2.50/month • Cancel anytime',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
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
              const SizedBox(height: 32),

              // Claim button (only show after spin completes)
              AnimatedOpacity(
                opacity: _spinController.isCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _spinController.isCompleted && !_isProcessing
                            ? _handlePayment
                            : null,
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Claim Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> options;

  WheelPainter({required this.options});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / options.length;

    for (int i = 0; i < options.length; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final sweepAngle = segmentAngle;

      // Draw segment
      final paint = Paint()
        ..color = options[i]['color']
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i]['label'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
