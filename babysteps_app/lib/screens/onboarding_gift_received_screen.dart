import 'package:flutter/material.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/referral_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_before_after_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';

class OnboardingGiftReceivedScreen extends StatefulWidget {
  const OnboardingGiftReceivedScreen({super.key});

  @override
  State<OnboardingGiftReceivedScreen> createState() => _OnboardingGiftReceivedScreenState();
}

class _OnboardingGiftReceivedScreenState extends State<OnboardingGiftReceivedScreen> {
  bool _isProcessing = false;
  late String _donorName;

  // 80 female names, 20 male names
  static const List<String> _donorNames = [
    // Female names (80)
    'Sarah M.', 'Emily R.', 'Jessica L.', 'Jennifer K.', 'Amanda T.',
    'Ashley W.', 'Stephanie B.', 'Nicole H.', 'Michelle P.', 'Melissa G.',
    'Rachel D.', 'Lauren S.', 'Heather F.', 'Brittany C.', 'Samantha J.',
    'Rebecca N.', 'Laura V.', 'Elizabeth M.', 'Danielle A.', 'Kimberly R.',
    'Amy L.', 'Christina K.', 'Victoria T.', 'Megan W.', 'Katherine B.',
    'Hannah H.', 'Amber P.', 'Courtney G.', 'Kristin D.', 'Natalie S.',
    'Taylor F.', 'Emma C.', 'Madison J.', 'Olivia N.', 'Abigail V.',
    'Isabella M.', 'Sophia A.', 'Ava R.', 'Chloe L.', 'Grace K.',
    'Lily T.', 'Addison W.', 'Ella B.', 'Natalie H.', 'Avery P.',
    'Sofia G.', 'Layla D.', 'Zoe S.', 'Victoria F.', 'Aria C.',
    'Scarlett J.', 'Nora N.', 'Riley V.', 'Zoey M.', 'Hazel A.',
    'Luna R.', 'Aurora L.', 'Savannah K.', 'Brooklyn T.', 'Bella W.',
    'Claire B.', 'Skylar H.', 'Lucy P.', 'Paisley G.', 'Everly D.',
    'Anna S.', 'Caroline F.', 'Nova C.', 'Genesis J.', 'Emilia N.',
    'Kennedy V.', 'Maya M.', 'Willow A.', 'Kinsley R.', 'Naomi L.',
    'Aaliyah K.', 'Elena T.', 'Audrey W.', 'Ariana B.', 'Allison H.',
    // Male names (20)
    'Michael J.', 'David R.', 'James L.', 'Robert K.', 'John T.',
    'William W.', 'Christopher B.', 'Daniel H.', 'Matthew P.', 'Anthony G.',
    'Mark D.', 'Steven S.', 'Andrew F.', 'Joshua C.', 'Kevin M.',
    'Brian N.', 'Thomas V.', 'Ryan A.', 'Jason R.', 'Nicholas L.',
  ];

  @override
  void initState() {
    super.initState();
    // Randomly select a donor name
    final random = math.Random();
    _donorName = _donorNames[random.nextInt(_donorNames.length)];
    
    // Initialize referral system for this user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
      if (authProvider.user != null) {
        referralProvider.initializeReferral(authProvider.user!.id);
      }
    });
  }

  Future<void> _acceptGift() async {
    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool hasUser = authProvider.user != null;

    if (hasUser) {
      await authProvider.markUserAsPaid(onTrial: false);
    } else {
      await authProvider.savePendingPlanUpgrade(
        planTier: 'paid',
        isOnTrial: false,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gift accepted! Your BabySteps Premium plan has started. Thank you, $_donorName! 💝'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
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

  void _skipAsFreeUser() async {
    if (!mounted) return;
    // Require the user to sign up / log in before continuing with limited access.
    Navigator.of(context).pushReplacementWithFade(
      const LoginScreen(),
    );
  }

  void _shareGift() async {
    final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
    final shareText = referralProvider.getShareMessage(_donorName);

    try {
      await Share.share(
        shareText,
        subject: 'I received a parenting gift from $_donorName! 🎁',
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for sharing! You\'re helping other parents discover BabySteps 💝'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 24),
            // Gift icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEC4899),
                      Color(0xFFF472B6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Headline
            const Text(
              'You\'ve Received',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A Special Gift! 🎁',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryPurple,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Donor message
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFCE7F3),
                    Color(0xFFFDF2F8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFEC4899),
                              Color(0xFFF472B6),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _donorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF831843),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '"Every parent deserves access to the best tools for their child. Please accept this gift — you\'ve got this! 💝"',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF831843),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // How it works section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F2FC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How This Gift Works:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGiftStep(
                    Icons.favorite,
                    '$_donorName donated',
                    'A kind parent paid forward \$10 to help you',
                    const Color(0xFFEC4899),
                  ),
                  const SizedBox(height: 12),
                  _buildGiftStep(
                    Icons.add_circle,
                    'We matched their gift',
                    'BabySteps added another \$10 to make it \$20 total',
                    AppTheme.primaryPurple,
                  ),
                  const SizedBox(height: 12),
                  _buildGiftStep(
                    Icons.celebration,
                    'You save \$20!',
                    'Together, we believe every parent deserves access',
                    const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Price section
            Container(
              padding: const EdgeInsets.all(28),
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
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Special Price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$49',
                        style: TextStyle(
                          fontSize: 28,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '\$29',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryPurple,
                          height: 0.9,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Text(
                          '/year',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SAVE \$20 WITH THIS GIFT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Mission statement
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFDBEAFE),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.health_and_safety,
                    color: Color(0xFF3B82F6),
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We believe every child deserves the best start in life, regardless of their family\'s financial situation. That\'s why we created Pay It Forward — so parents can help each other.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E40AF),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Urgency messaging
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFEF3C7),
                    Color(0xFFFEF9C3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.card_giftcard, color: Color(0xFFF59E0B), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This gift is reserved for you — accept it now!',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // CTA Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEC4899),
                    Color(0xFFF472B6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _acceptGift,
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
                            'Accept This Gift',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.favorite, color: Colors.white, size: 22),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Share Gift Section (Enhanced with Green Background)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFDCFCE7),
                    Color(0xFFF0FDF4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon and Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF10B981),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Share Your Gift Story',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help us spread the word about Pay It Forward! Share your story with other parents and inspire them to join our mission. 💝',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF065F46).withOpacity(0.9),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Reward Callout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.card_giftcard,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Earn \$10 off next year for each friend who joins!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareGift,
                      icon: const Icon(Icons.share_rounded, size: 24),
                      label: const Text(
                        'Share This Gift',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Max \$49 off — that\'s a free year!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46).withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isProcessing ? null : _acceptGift,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Just \$29/year • Cancel anytime',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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

  Widget _buildGiftStep(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
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
    );
  }
}
