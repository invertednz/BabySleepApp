import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/services/recommendation_service.dart';
import 'package:babysteps_app/models/recommendation.dart';

class HomeMockupsScreen extends StatefulWidget {
  const HomeMockupsScreen({super.key});

  @override
  State<HomeMockupsScreen> createState() => _HomeMockupsScreenState();
}

class _HomeMockupsScreenState extends State<HomeMockupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _activities = [
    {
      'title': 'Tummy Time Adventure',
      'desc': 'Gentle tummy time on a soft mat for 5–10 minutes to build neck and core strength.'
    },
    {
      'title': 'Read & Point',
      'desc': 'Read a picture book and point to objects. Let your child try to point too.'
    },
    {
      'title': 'Outdoor Stroller Walk',
      'desc': 'A short 10–15 minute walk, talk about what you see and hear.'
    },
    {
      'title': 'High-Contrast Cards',
      'desc': 'Show black & white cards 8–12 inches from face to encourage focus.'
    },
    {
      'title': 'Peekaboo Smiles',
      'desc': 'Play peekaboo to encourage social smiles and connection.'
    },
  ];

  List<Recommendation> get _recs => RecommendationService.getFeaturedRecommendations();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.lightPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkPurple),
        title: const Text('Home Mockups', style: TextStyle(color: AppTheme.darkPurple)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.darkPurple,
          tabs: const [
            Tab(text: 'Mockup 1'),
            Tab(text: 'Mockup 2'),
            Tab(text: 'Mockup 3'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MockupDashboard(_activities, _recs),
          _MockupStatusChips(_activities, _recs),
          _MockupActionRail(_activities, _recs),
        ],
      ),
    );
  }
}

class _MockupDashboard extends StatelessWidget {
  final List<Map<String, String>> activities;
  final List<Recommendation> recs;
  const _MockupDashboard(this.activities, this.recs);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick boxes 2x2 grid
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: const [
            _QuickBox(title: 'Concerns', icon: FeatherIcons.alertCircle),
            _QuickBox(title: 'Diary', icon: FeatherIcons.bookOpen),
            _QuickBox(title: 'Short-Term Focus', icon: FeatherIcons.target),
            _QuickBox(title: 'Ask', icon: FeatherIcons.messageCircle),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Activities Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...activities.take(6).map((a) => _ActivityCard(title: a['title']!, desc: a['desc']!)),
        const SizedBox(height: 24),
        const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...recs.map((r) => _RecommendationRow(title: r.title, description: r.description)),
      ],
    );
  }
}

class _MockupStatusChips extends StatelessWidget {
  final List<Map<String, String>> activities;
  final List<Recommendation> recs;
  const _MockupStatusChips(this.activities, this.recs);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Horizontal chips
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _StatusChip(title: 'Concerns', subtitle: '3 active', icon: FeatherIcons.alertCircle),
              _StatusChip(title: 'Diary', subtitle: 'Today', icon: FeatherIcons.bookOpen),
              _StatusChip(title: 'Focus', subtitle: '2 selected', icon: FeatherIcons.target),
              _StatusChip(title: 'Ask', subtitle: 'New replies', icon: FeatherIcons.messageCircle),
            ].expand((w) sync* {
              yield w;
              yield const SizedBox(width: 12);
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          childAspectRatio: 2.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: activities.take(6).map((a) => _ActivityCard(title: a['title']!, desc: a['desc']!)).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: recs
                .map((r) => _RecommendationChip(title: r.title, description: r.description))
                .expand((w) sync* {
              yield w;
              yield const SizedBox(width: 12);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MockupActionRail extends StatelessWidget {
  final List<Map<String, String>> activities;
  final List<Recommendation> recs;
  const _MockupActionRail(this.activities, this.recs);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left action rail
        Container(
          width: 140,
          color: Colors.transparent,
          padding: const EdgeInsets.all(12),
          child: const Column(
            children: [
              _RailBox(title: 'Concerns', icon: FeatherIcons.alertCircle),
              SizedBox(height: 12),
              _RailBox(title: 'Diary', icon: FeatherIcons.bookOpen),
              SizedBox(height: 12),
              _RailBox(title: 'Focus', icon: FeatherIcons.target),
              SizedBox(height: 12),
              _RailBox(title: 'Ask', icon: FeatherIcons.messageCircle),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Main content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Activities Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...activities.take(6).toList().asMap().entries.map((e) {
                final idx = e.key + 1;
                final a = e.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$idx. ${a['title']!}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(a['desc']!, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    const _ReactionRow(),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              const SizedBox(height: 16),
              const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...recs.map((r) => _RecommendationRow(title: r.title, description: r.description)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickBox extends StatelessWidget {
  final String title;
  final IconData icon;
  const _QuickBox({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryPurple),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Open', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _StatusChip({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailBox extends StatelessWidget {
  final String title;
  final IconData icon;
  const _RailBox({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String desc;
  const _ActivityCard({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            const _ReactionRow(),
          ],
        ),
      ),
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow();

  @override
  Widget build(BuildContext context) {
    Widget _iconButton(String label, String emoji, Color color) {
      return OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
    }

    return Row(
      children: [
        _iconButton('remove', '×', Colors.grey),
        const SizedBox(width: 8),
        _iconButton('smile', '🙂', Colors.green),
        const SizedBox(width: 8),
        _iconButton('neutral', '😐', Colors.amber),
        const SizedBox(width: 8),
        _iconButton('sad', '🙁', Colors.redAccent),
      ],
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final String title;
  final String description;
  const _RecommendationRow({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(FeatherIcons.chevronRight),
        onTap: () {},
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String title;
  final String description;
  const _RecommendationChip({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('View', style: TextStyle(color: AppTheme.darkPurple)),
            ),
          ),
        ],
      ),
    );
  }
}
