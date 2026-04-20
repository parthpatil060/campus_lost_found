import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

// ── BROADCAST FEATURE START ──
import '../../models/broadcast_model.dart';
import '../../widgets/broadcast_card.dart';
// ── BROADCAST FEATURE END ──

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showInfoDialog(String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submit a Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help your fellow students by providing accurate details.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Lost Item',
                    subtitle: 'Track something missing',
                    icon: Icons.search_off_rounded,
                    color: AppTheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report-lost');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Found Item',
                    subtitle: 'Log a found object',
                    icon: Icons.inventory_2_rounded,
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report-found');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final initials = user.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final firstName = user.name.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _DashboardDrawer(
        userName: user.name,
        email: user.email,
        initials: initials.isEmpty ? 'U' : initials,
        onMyReports: () => Navigator.pushNamed(context, '/my-reports'),
        onNotifications: () => Navigator.pushNamed(context, '/notifications'),
        onHowToUse: () => _showInfoDialog(
          'How to use CampusRetrieve',
          'Create a clear lost or found report, keep details accurate, and watch notifications so you can respond quickly when a verifier confirms a match.',
        ),
        onTerms: () => _showInfoDialog(
          'Guidelines',
          'Submit accurate reports only, do not claim items that are not yours, and cooperate with verification requests made for campus safety.',
        ),
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _TopBar(
                      firstName: firstName,
                      initials: initials.isEmpty ? 'U' : initials,
                      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _HeroPanel(userId: user.uid, firstName: firstName),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Text(
                      'Overview Stats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _StatsRow(userId: user.uid),
                  ),
                ),
                // ── BROADCAST FEATURE START ──
                // Campus Notices Section
                SliverToBoxAdapter(
                  child: _BroadcastsSection(
                    firestoreService: _firestoreService,
                    userId: user.uid,
                    userName: user.name,
                  ),
                ),
                // ── BROADCAST FEATURE END ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/my-reports'),
                          child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _RecentActivityList(userId: user.uid),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBroadcastInfoCard extends StatelessWidget {
  final String title;
  final String message;

  const _UserBroadcastInfoCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_outlined,
              size: 28,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String firstName;
  final String initials;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.firstName,
    required this.initials,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUser!.uid;
    return Row(
      children: [
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Ready to find what you lost?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        StreamBuilder<List<NotificationModel>>(
          stream: FirestoreService().getNotificationsForUser(uid),
          builder: (context, snapshot) {
            final unread = snapshot.data?.where((n) => !n.isRead).length ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 26),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String userId;
  final String firstName;

  const _HeroPanel({required this.userId, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, lostSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('found_items')
              .where('finderId', isEqualTo: userId)
              .snapshots(),
          builder: (context, foundSnapshot) {
            return StreamBuilder<List<BroadcastModel>>(
              stream: FirestoreService().getActiveBroadcasts(),
              builder: (context, broadcastSnapshot) {
                final lost = lostSnapshot.data?.docs.length ?? 0;
                final found = foundSnapshot.data?.docs.length ?? 0;
                final broadcastCount = broadcastSnapshot.data?.length ?? 0;
                final total = lost + found;

                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: AppTheme.glassDecoration(opacity: 0.15, radius: BorderRadius.circular(12)),
                            child: const Text(
                              'CampusRetrieve Dashboard',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '$total Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'Reports in your account',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _HeroMetricPill(
                                  label: 'Lost',
                                  value: '$lost',
                                  icon: Icons.help_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HeroMetricPill(
                                  label: 'Found',
                                  value: '$found',
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HeroMetricPill(
                                  label: 'Broadcast',
                                  value: '$broadcastCount',
                                  icon: Icons.campaign_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetricPill({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String userId;

  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Lost Cases',
            icon: Icons.search_off_rounded,
            tint: AppTheme.error,
            stream: FirebaseFirestore.instance
                .collection('lost_items')
                .where('userId', isEqualTo: userId)
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Found Items',
            icon: Icons.inventory_2_rounded,
            tint: AppTheme.success,
            stream: FirebaseFirestore.instance
                .collection('found_items')
                .where('finderId', isEqualTo: userId)
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Resolved',
            icon: Icons.verified_rounded,
            tint: AppTheme.primary,
            stream: FirebaseFirestore.instance
                .collection('lost_items')
                .where('userId', isEqualTo: userId)
                .where('status', isEqualTo: 'matched')
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Stream<int> stream;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final bool isLost;
  final String? photoURL;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.isLost,
    this.photoURL,
  });

  String _activityDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today, ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final isMatched = status == 'matched';
    final accent = isMatched ? AppTheme.primary : (isLost ? AppTheme.error : AppTheme.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoURL != null && photoURL!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoURL!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Icon(
                      isLost ? Icons.search_off_rounded : Icons.inventory_2_rounded,
                      color: accent,
                    ),
                  )
                : Icon(
                    isLost ? Icons.search_off_rounded : Icons.inventory_2_rounded,
                    color: accent,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15),
                      ),
                    ),
                    _StatusTag(status: status, color: accent),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textSecondary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      _activityDate(date),
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusTag({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final String userId;

  const _RecentActivityList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final lostStream = FirebaseFirestore.instance
        .collection('lost_items')
        .where('userId', isEqualTo: userId)
        .snapshots();
    final foundStream = FirebaseFirestore.instance
        .collection('found_items')
        .where('finderId', isEqualTo: userId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: lostStream,
      builder: (context, lostSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: foundStream,
          builder: (context, foundSnapshot) {
            final items = <Map<String, dynamic>>[];
            for (final doc in lostSnapshot.data?.docs ?? []) {
              final data = doc.data();
              items.add({
                'title': data['itemName'] ?? 'Lost item',
                'subtitle': (data['possibleLocations'] as List<dynamic>? ?? [])
                    .take(2)
                    .join(', '),
                'status': data['status'] ?? 'pending',
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'isLost': true,
                'photoURL': data['photoURL'],
              });
            }
            for (final doc in foundSnapshot.data?.docs ?? []) {
              final data = doc.data();
              items.add({
                'title': data['description'] ?? 'Found item',
                'subtitle': data['locationFound'] ?? 'Campus',
                'status': data['status'] ?? 'pending',
                'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'isLost': false,
                'photoURL': data['photoURL'],
              });
            }
            items.sort(
              (a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
            );

            if (items.isEmpty) {
              return _EmptyActivity();
            }

            return Column(
              children: items.take(5).map((item) {
                return _ActivityTile(
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  status: item['status'] as String,
                  date: item['createdAt'] as DateTime,
                  isLost: item['isLost'] as bool,
                  photoURL: item['photoURL'] as String?,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No recent activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Your reports and matches will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final String userName;
  final String email;
  final String initials;
  final VoidCallback onMyReports;
  final VoidCallback onNotifications;
  final VoidCallback onHowToUse;
  final VoidCallback onTerms;
  final VoidCallback onLogout;

  const _DashboardDrawer({
    required this.userName,
    required this.email,
    required this.initials,
    required this.onMyReports,
    required this.onNotifications,
    required this.onHowToUse,
    required this.onTerms,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
                      ),
                      Text(
                        email,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _DrawerTile(icon: Icons.description_outlined, label: 'My Reports', onTap: onMyReports),
                _DrawerTile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: onNotifications),
                const Divider(height: 32, indent: 16, endIndent: 16),
                _DrawerTile(icon: Icons.help_outline_rounded, label: 'How to use', onTap: onHowToUse),
                _DrawerTile(icon: Icons.policy_outlined, label: 'Guidelines', onTap: onTerms),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: AppTheme.error,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textPrimary;
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      leading: Icon(icon, color: effectiveColor.withOpacity(0.7)),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── BROADCAST FEATURE START ──
class _BroadcastsSection extends StatelessWidget {
  final FirestoreService firestoreService;
  final String userId;
  final String userName;

  const _BroadcastsSection({
    required this.firestoreService,
    required this.userId,
    required this.userName,
  });

  Future<void> _handleRespond(
      BuildContext context, BroadcastModel broadcast) async {
    try {
      await firestoreService.markBroadcastRead(broadcast.broadcastId, userId);
      await firestoreService.notifyVerifiersBroadcastResponse(
        broadcastId: broadcast.broadcastId,
        respondedByUserId: userId,
        respondedByName: userName,
        itemName: broadcast.itemName,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Verifiers have been notified. Visit the security office with your details.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BroadcastModel>>(
      stream: firestoreService.getActiveBroadcasts(),
      builder: (context, snapshot) {
        final broadcasts = snapshot.data ?? [];
        final unreadCount =
            broadcasts.where((b) => !b.readBy.contains(userId)).length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section heading with unread badge
              Row(
                children: [
                  const Text(
                    'Campus Notices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (snapshot.hasError)
                _UserBroadcastInfoCard(
                  title: 'Broadcasts will appear here in real time.',
                  message:
                      'As soon as a verifier publishes a campus notice, this section updates automatically.',
                )
              else if (broadcasts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Column(
                    children: [
                      Text('📋', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text(
                        'No active notices right now',
                        style: TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (final broadcast in broadcasts)
                      BroadcastCard(
                        broadcast: broadcast,
                        currentUserId: userId,
                        fullWidth: true,
                        showResponseCount: false,
                        showRespondAction: false,
                        onRespond: (b) => _handleRespond(context, b),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
// ── BROADCAST FEATURE END ──
