import 'package:flutter/foundation.dart';
import 'package:babysteps_app/models/referral.dart';
import 'dart:math';

class ReferralProvider with ChangeNotifier {
  Referral? _referral;
  bool _isLoading = false;

  Referral? get referral => _referral;
  bool get isLoading => _isLoading;

  // Reward configuration
  static const double discountPerReferral = 10.0; // $10 per successful referral
  static const int maxDiscountDollars = 49; // Can't exceed full year price

  /// Generate a unique referral code for a user
  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Initialize or load referral data for user
  Future<void> initializeReferral(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Load from Supabase or local storage
      // For now, create a mock referral
      _referral = Referral(
        id: 'ref_${userId.substring(0, 8)}',
        userId: userId,
        referralCode: _generateReferralCode(),
        successfulReferrals: 0,
        earnedDiscount: 0.0,
        createdAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing referral: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a successful referral and update earned discount
  Future<void> recordSuccessfulReferral() async {
    if (_referral == null) return;

    final newReferralCount = _referral!.successfulReferrals + 1;
    final newDiscount = min(
      newReferralCount * discountPerReferral,
      maxDiscountDollars.toDouble(),
    );

    _referral = _referral!.copyWith(
      successfulReferrals: newReferralCount,
      earnedDiscount: newDiscount,
      lastReferralAt: DateTime.now(),
    );

    // TODO: Save to Supabase
    notifyListeners();
  }

  /// Get share message with referral code
  String getShareMessage(String donorName) {
    final code = _referral?.referralCode ?? 'WELCOME';
    
    return '''🎁 I just received an amazing gift from $donorName!

They used BabySteps' "Pay It Forward" program to help me get access to expert parenting tools for just \$29/year (normally \$49).

Here's the cool part: $donorName donated \$10, BabySteps matched it with another \$10, and now I get \$20 off! 💝

BabySteps helps parents track milestones, get AI-powered activities, and reduce parenting stress. Their mission is that EVERY parent should have access to these tools, regardless of finances.

If you're a parent (or know one), use my code: $code to get started! Maybe you'll receive a gift too, or pay it forward to help another parent! 

👉 Download BabySteps (use code: $code)

#ParentingCommunity #PayItForward #BabySteps''';
  }

  /// Calculate how many more referrals needed for next reward tier
  int getReferralsUntilNextReward() {
    if (_referral == null) return 1;
    
    final currentDiscount = _referral!.earnedDiscount;
    if (currentDiscount >= maxDiscountDollars) return 0; // Max reached
    
    final nextTierDiscount = ((currentDiscount / discountPerReferral).ceil() + 1) * discountPerReferral;
    final referralsNeeded = (nextTierDiscount / discountPerReferral).round() - _referral!.successfulReferrals;
    
    return max(0, referralsNeeded);
  }

  /// Get progress towards max discount (0.0 to 1.0)
  double getDiscountProgress() {
    if (_referral == null) return 0.0;
    return (_referral!.earnedDiscount / maxDiscountDollars).clamp(0.0, 1.0);
  }

  /// Reset referral data (for testing or new year)
  void reset() {
    _referral = null;
    notifyListeners();
  }
}
