import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/widgets/app_header.dart';

class ProgressScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProgressScreen({this.showBottomNav = false, super.key});

  static const _ok = Color(0xFF46B17B);
  static const _warn = Color(0xFFE6C370);
  static const _bad = Color(0xFFE66A6A);

  @override
  Widget build(BuildContext context) {
    return Consumer<BabyProvider>(
      builder: (context, babyProvider, _) {
        final Baby? baby = babyProvider.selectedBaby;
        final ageMonths = _formatAgeMonths(baby?.birthdate);
        final name = baby?.name ?? '';
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: babyProvider.getDomainTrackingScores(),
                    builder: (context, snapshot) {
                      final domainScores = snapshot.data ?? const <Map<String, dynamic>>[];
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHeroWithPins(context, baby: baby, domainScores: domainScores),
                          const SizedBox(height: 14),
                          _ProgressList(domainScores: domainScores),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroWithPins(BuildContext context, {Baby? baby, required List<Map<String, dynamic>> domainScores}) {
    final imgPath = _heroImageForGender(baby?.gender);
    final scores = _DomainScoreHelper(domainScores);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 320, // Increased from 280 to 320 to accommodate all pins
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            return Stack(
              children: [
                // Hero image (placeholder box if asset not available)
                Positioned.fill(
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF1F3F5),
                        alignment: Alignment.center,
                        child: const Icon(FeatherIcons.image, color: Color(0xFF9CA3AF), size: 40),
                      );
                    },
                  ),
                ),
                // Pins: Brain (14%), Social (32.5%), Speech (51%), Gross Motor (69.5%), Fine Motor (88%) — right 4%
                _ProgressPin(
                  top: h * 0.12, // Moved up slightly from 0.14
                  right: w * 0.04,
                  label: 'Brain',
                  percentile: scores.formattedPercentile('Cognitive'),
                  color: scores.colorFor('Cognitive'),
                ),
                _ProgressPin(
                  top: h * 0.28, // Moved up slightly from 0.325
                  right: w * 0.04,
                  label: 'Social',
                  percentile: scores.formattedPercentile('Social'),
                  color: scores.colorFor('Social'),
                ),
                _ProgressPin(
                  top: h * 0.44, // Moved up slightly from 0.51
                  right: w * 0.04,
                  label: 'Speech',
                  percentile: scores.formattedPercentile('Communication'),
                  color: scores.colorFor('Communication'),
                ),
                _ProgressPin(
                  top: h * 0.60, // Moved up slightly from 0.695
                  right: w * 0.04,
                  label: 'Gross Motor',
                  percentile: scores.formattedPercentile('Motor'),
                  color: scores.colorFor('Motor'),
                ),
                _ProgressPin(
                  top: h * 0.76, // Moved up from 0.88 to 0.76 to prevent cutoff
                  right: w * 0.04,
                  label: 'Fine Motor',
                  percentile: scores.formattedPercentile('Fine Motor'),
                  color: scores.colorFor('Fine Motor'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Helpers -------------------------------------------------------------

class _DomainScoreHelper {
  final Map<String, Map<String, dynamic>> _byDomain;
  _DomainScoreHelper(List<Map<String, dynamic>> rows)
      : _byDomain = {
          for (final r in rows)
            (r['domain'] as String): r,
        };

  // Default fallback values to match mockup when no data
  static const Map<String, double> _fallback = {
    'Cognitive': 72,
    'Social': 71,
    'Communication': 45,
    'Motor': 66,
    'Fine Motor': 22,
  };

  double _value(String domain) {
    final row = _byDomain[domain];
    if (row == null || row['avg_percentile'] == null) {
      return _fallback[domain]!.toDouble();
    }
    final v = (row['avg_percentile'] as num).toDouble();
    if (v < 1.0) return 1.0;
    if (v > 99.0) return 99.0;
    return v;
  }

  String formattedPercentile(String domain) => '${_value(domain).round()}%ile';

  String subtitle(String domain) {
    final n = _value(domain).round();
    final suffix = _ordinalSuffix(n);
    return '$n$suffix percentile';
  }

  double percent(String domain) => (_value(domain) / 100.0);

  Color colorFor(String domain) {
    final v = _value(domain);
    if (v < 33) return const Color(0xFFE66A6A); // bad
    if (v < 66) return const Color(0xFFE6C370); // warn
    return const Color(0xFF46B17B); // ok
  }

  _BadgeKind badgeKind(String domain) {
    final v = _value(domain);
    if (v < 33) return _BadgeKind.bad;
    if (v < 66) return _BadgeKind.warn;
    return _BadgeKind.ok;
  }

  String badgeText(String domain) {
    final kind = badgeKind(domain);
    if (kind == _BadgeKind.ok) return 'ON TRACK';
    if (kind == _BadgeKind.warn) return 'WATCH';
    return 'BEHIND';
  }
}

String _heroImageForGender(String? gender) {
  final g = (gender ?? '').toLowerCase();
  if (g.contains('f') || g.contains('girl') || g.contains('woman')) {
    return 'assets/girl.jpg';
  }
  return 'assets/boy.jpg';
}

String _formatAgeMonths(DateTime? birthdate) {
  if (birthdate == null) return '';
  final now = DateTime.now();
  int months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
  if (now.day < birthdate.day) months = months - 1;
  if (months < 0) months = 0;
  return '${months} mo';
}

String _ordinalSuffix(int n) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return 'th';
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}


class _ProgressPin extends StatelessWidget {
  final double top;
  final double right;
  final String label;
  final String percentile;
  final Color color;

  const _ProgressPin({
    required this.top,
    required this.right,
    required this.label,
    required this.percentile,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Invisible anchor for potential icon if needed
          const SizedBox.shrink(),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text('· $percentile', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  final List<Map<String, dynamic>> domainScores;
  const _ProgressList({required this.domainScores});

  @override
  Widget build(BuildContext context) {
    final scores = _DomainScoreHelper(domainScores);
    // Order: Brain, Social & Emotional, Speech & Language, Gross Motor, Fine Motor
    final items = [
      _ProgressItem(
        title: 'Brain Development',
        sub: scores.subtitle('Cognitive'),
        percent: scores.percent('Cognitive'),
        color: scores.colorFor('Cognitive'),
        badgeText: scores.badgeText('Cognitive'),
        badgeKind: scores.badgeKind('Cognitive'),
      ),
      _ProgressItem(
        title: 'Social & Emotional',
        sub: scores.subtitle('Social'),
        percent: scores.percent('Social'),
        color: scores.colorFor('Social'),
        badgeText: scores.badgeText('Social'),
        badgeKind: scores.badgeKind('Social'),
      ),
      _ProgressItem(
        title: 'Speech & Language',
        sub: scores.subtitle('Communication'),
        percent: scores.percent('Communication'),
        color: scores.colorFor('Communication'),
        badgeText: scores.badgeText('Communication'),
        badgeKind: scores.badgeKind('Communication'),
      ),
      _ProgressItem(
        title: 'Gross Motor',
        sub: scores.subtitle('Motor'),
        percent: scores.percent('Motor'),
        color: scores.colorFor('Motor'),
        badgeText: scores.badgeText('Motor'),
        badgeKind: scores.badgeKind('Motor'),
      ),
      _ProgressItem(
        title: 'Fine Motor',
        sub: scores.subtitle('Fine Motor'),
        percent: scores.percent('Fine Motor'),
        color: scores.colorFor('Fine Motor'),
        badgeText: scores.badgeText('Fine Motor'),
        badgeKind: scores.badgeKind('Fine Motor'),
      ),
    ];
    return Column(children: items);
  }
}

enum _BadgeKind { ok, warn, bad }

class _ProgressItem extends StatelessWidget {
  final String title;
  final String sub;
  final double percent; // 0..1
  final Color color;
  final String badgeText;
  final _BadgeKind badgeKind;

  const _ProgressItem({
    required this.title,
    required this.sub,
    required this.percent,
    required this.color,
    required this.badgeText,
    required this.badgeKind,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    if (badgeKind == _BadgeKind.ok) {
      badgeColor = const Color(0xFF46B17B);
    } else if (badgeKind == _BadgeKind.warn) {
      badgeColor = const Color(0xFFE6C370);
    } else {
      badgeColor = const Color(0xFFE66A6A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(sub, style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(height: 6, color: const Color(0xFFF1F3F5)),
                          Container(
                            height: 6,
                            width: constraints.maxWidth * percent,
                            decoration: BoxDecoration(color: color),
                          ),
                        ],
                      );
                    },
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
