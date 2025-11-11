class Referral {
  final String id;
  final String userId;
  final String referralCode;
  final int successfulReferrals;
  final double earnedDiscount; // Dollar amount earned for next year
  final DateTime createdAt;
  final DateTime? lastReferralAt;

  Referral({
    required this.id,
    required this.userId,
    required this.referralCode,
    this.successfulReferrals = 0,
    this.earnedDiscount = 0.0,
    required this.createdAt,
    this.lastReferralAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'referral_code': referralCode,
      'successful_referrals': successfulReferrals,
      'earned_discount': earnedDiscount,
      'created_at': createdAt.toIso8601String(),
      'last_referral_at': lastReferralAt?.toIso8601String(),
    };
  }

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      referralCode: json['referral_code'] as String,
      successfulReferrals: json['successful_referrals'] as int? ?? 0,
      earnedDiscount: (json['earned_discount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastReferralAt: json['last_referral_at'] != null
          ? DateTime.parse(json['last_referral_at'] as String)
          : null,
    );
  }

  Referral copyWith({
    String? id,
    String? userId,
    String? referralCode,
    int? successfulReferrals,
    double? earnedDiscount,
    DateTime? createdAt,
    DateTime? lastReferralAt,
  }) {
    return Referral(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referralCode: referralCode ?? this.referralCode,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      earnedDiscount: earnedDiscount ?? this.earnedDiscount,
      createdAt: createdAt ?? this.createdAt,
      lastReferralAt: lastReferralAt ?? this.lastReferralAt,
    );
  }
}
