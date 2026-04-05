import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';

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
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Create a new report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the type of report you want to submit.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Report Lost',
                    subtitle: 'Track a missing item',
                    icon: Icons.search_off_rounded,
                    color: AppTheme.error,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(this.context, '/report-lost');
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Report Found',
                    subtitle: 'Log an item you found',
                    icon: Icons.inventory_2_rounded,
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(this.context, '/report-found');
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
          'How to use the app',
          'Create a clear lost or found report, keep details accurate, and watch notifications so you can respond quickly when a verifier confirms a match.',
        ),
        onTerms: () => _showInfoDialog(
          'Terms and conditions',
          'Submit accurate reports only, do not claim items that are not yours, and cooperate with verification requests made for campus safety.',
        ),
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Report'),
      ),
      body: DecoratedBox(
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _HeroPanel(userId: user.uid, firstName: firstName),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _StatsRow(userId: user.uid),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/my-reports'),
                          child: const Text('View all'),
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $firstName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Your campus lost and found workspace',
                style: TextStyle(color: AppTheme.textSecondary),
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
                IconButton.filledTonal(
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textPrimary,
                    fixedSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (unread > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
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
            final lost = lostSnapshot.data?.docs.length ?? 0;
            final found = foundSnapshot.data?.docs.length ?? 0;
            final total = lost + found;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good to see you, $firstName',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$total active records in your account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A clearer dashboard for faster reporting, better tracking, and simpler match follow-up.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoPill(icon: Icons.search_off_rounded, label: '$lost lost'),
                      _InfoPill(icon: Icons.inventory_2_rounded, label: '$found found'),
                      const _InfoPill(
                        icon: Icons.verified_user_outlined,
                        label: 'Verifier support',
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
            title: 'Lost',
            icon: Icons.search_off_rounded,
            tint: AppTheme.error,
            stream: FirebaseFirestore.instance
                .collection('lost_items')
                .where('userId', isEqualTo: userId)
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Found',
            icon: Icons.inventory_2_rounded,
            tint: AppTheme.success,
            stream: FirebaseFirestore.instance
                .collection('found_items')
                .where('finderId', isEqualTo: userId)
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Matched',
            icon: Icons.compare_arrows_rounded,
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
              return const _EmptyCard(
                icon: Icons.inbox_outlined,
                title: 'No reports yet',
                subtitle: 'Your latest lost and found activity will appear here.',
              );
            }
            return Column(
              children: items.take(5).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityTile(
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    status: item['status'] as String,
                    date: item['createdAt'] as DateTime,
                    isLost: item['isLost'] as bool,
                    photoURL: item['photoURL'] as String?,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
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
      width: 300,
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Container(
                      child: CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DrawerTile(
                icon: Icons.description_outlined,
                label: 'My reports',
                onTap: onMyReports,
              ),
              _DrawerTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: onNotifications,
              ),
              _DrawerTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'How to use the app',
                onTap: onHowToUse,
              ),
              _DrawerTile(
                icon: Icons.policy_outlined,
                label: 'Terms and conditions',
                onTap: onTerms,
              ),
              const Spacer(),
              _DrawerTile(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppTheme.error,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(height: 14),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
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

  @override
  Widget build(BuildContext context) {
    final accent = isLost ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoURL != null && photoURL!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoURL!,
                    fit: BoxFit.cover,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Campus update' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  _activityDate(date),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          _StatusPill(status: status),
        ],
      ),
    );
  }

  String _activityDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays <= 0) return 'Updated today';
    if (difference.inDays == 1) return 'Updated yesterday';
    return 'Updated ${difference.inDays} days ago';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (color, icon) = switch (normalized) {
      'matched' => (AppTheme.success, Icons.verified_rounded),
      'claimed' => (AppTheme.primary, Icons.done_all_rounded),
      'rejected' => (AppTheme.error, Icons.cancel_outlined),
      _ => (AppTheme.warning, Icons.schedule_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '${normalized[0].toUpperCase()}${normalized.substring(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
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

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: effectiveColor),
        title: Text(
          label,
          style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
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
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color.withOpacity(0.06),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.canvas,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
