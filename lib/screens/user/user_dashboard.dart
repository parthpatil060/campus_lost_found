import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';

// ─── Modern Clean Palette ───────────────────────────────────────────────────
class _D {
  static const bg        = Color(0xFFF8F9FA); // Minimalist off-white background
  static const surface   = Colors.white; // Solid white cards
  static const border    = Color(0xFFE5E7EB); // Very subtle gray border
  static const primary   = Color(0xFF3B82F6); // Modern soft blue
  static const primaryBg = Color(0xFFEFF6FF);
  static const green     = Color(0xFF10B981);
  static const greenBg   = Color(0xFFECFDF5);
  static const red       = Color(0xFFEF4444);
  static const redBg     = Color(0xFFFEF2F2);
  static const amber     = Color(0xFFF59E0B);
  static const amberBg   = Color(0xFFFFFBEB);
  static const purple    = Color(0xFF8B5CF6);
  static const purpleBg  = Color(0xFFF5F3FF);
  static const textHi    = Color(0xFF111827); // Deep gray-black for contrast
  static const textMid   = Color(0xFF4B5563);
  static const textLow   = Color(0xFF6B7280);
  static const divider   = Color(0xFFF3F4F6);

  static const gradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow = [
    BoxShadow(
      color: primary.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _navIndex = 0;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox();

    final firstName = user.name.split(' ').first;
    final initials = user.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: _D.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(

            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHeader(context, firstName, initials, user.uid)),
              SliverToBoxAdapter(child: _buildHero(user.uid)),
              SliverToBoxAdapter(child: _buildStatRow(user.uid)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Reports',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _D.textHi)),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/my-reports'),
                        child: const Text('View all',
                            style: TextStyle(
                                fontSize: 12,
                                color: _D.primary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: _buildRecentActivity(user.uid)),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, String firstName, String initials, String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: _D.gradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Campus L&F',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _D.textHi)),
                const Text('SIES Campus',
                    style: TextStyle(fontSize: 11, color: _D.textLow)),
              ],
            ),
          ),
          // Month pill
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _D.surface,
              border: Border.all(color: _D.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.calendar_today_outlined,
                    size: 11, color: _D.textMid),
                SizedBox(width: 5),
                Text('Mar 2026',
                    style: TextStyle(fontSize: 11, color: _D.textMid)),
                SizedBox(width: 3),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: _D.textMid),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification bell
          StreamBuilder<List<NotificationModel>>(
            stream: _firestoreService.getNotificationsForUser(
                context.read<AuthProvider>().currentUser!.uid),
            builder: (context, snap) {
              final unread =
                  snap.data?.where((n) => !n.isRead).length ?? 0;
              return Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _D.surface,
                      border: Border.all(color: _D.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.notifications_outlined,
                          color: _D.textMid, size: 18),
                      onPressed: () => Navigator.pushNamed(
                          context, '/notifications'),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _D.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: _D.bg, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                                fontSize: 7,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero(String uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('lost_items')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, lostSnap) {
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('found_items')
                .where('finderId', isEqualTo: uid)
                .snapshots(),
            builder: (context, foundSnap) {
              final total = (lostSnap.data?.docs.length ?? 0) +
                  (foundSnap.data?.docs.length ?? 0);
              final firstName = context
                  .read<AuthProvider>()
                  .currentUser!
                  .name
                  .split(' ')
                  .first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $firstName',
                    style: const TextStyle(
                        fontSize: 13,
                        color: _D.textLow,
                        letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$total',
                          style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: _D.primary,
                              letterSpacing: -1.5,
                              height: 1),
                        ),
                        const TextSpan(
                          text: ' items tracked',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: _D.textHi,
                              letterSpacing: -1.5,
                              height: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('This month on SIES Campus',
                          style:
                          TextStyle(fontSize: 13, color: _D.textLow)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _D.greenBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _D.green.withOpacity(0.3)),
                        ),
                        child: const Text('+3 new',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _D.green)),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Stat Row ──────────────────────────────────────────────────────────────
  Widget _buildStatRow(String uid) {
    Widget _buildQuickActions(BuildContext context) {
      final actions = [
        {'icon': Icons.search_off, 'label': 'Lost', 'color': _D.red},
        {'icon': Icons.volunteer_activism, 'label': 'Found', 'color': _D.green},
        {'icon': Icons.receipt_long, 'label': 'Reports', 'color': _D.primary},
        {'icon': Icons.notifications, 'label': 'Alerts', 'color': _D.amber},
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              children: actions.map((a) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: (a['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(a['icon'] as IconData,
                                color: a['color'] as Color),
                            const SizedBox(height: 6),
                            Text(a['label'] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: a['color'] as Color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Lost',
              icon: Icons.error_outline_rounded,
              iconColor: _D.red,
              iconBg: _D.redBg,
              stream: FirebaseFirestore.instance
                  .collection('lost_items')
                  .where('userId', isEqualTo: uid)
                  .snapshots()
                  .map((s) => s.docs.length),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Found',
              icon: Icons.check_circle_outline_rounded,
              iconColor: _D.green,
              iconBg: _D.greenBg,
              stream: FirebaseFirestore.instance
                  .collection('found_items')
                  .where('finderId', isEqualTo: uid)
                  .snapshots()
                  .map((s) => s.docs.length),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Matched',
              icon: Icons.compare_arrows_rounded,
              iconColor: _D.purple,
              iconBg: _D.purpleBg,
              stream: FirebaseFirestore.instance
                  .collection('lost_items')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'matched')
                  .snapshots()
                  .map((s) => s.docs.length),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chart Card ────────────────────────────────────────────────────────────




  // ── Tabs ──────────────────────────────────────────────────────────────────


  // ── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity(String uid) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .where('userId', isEqualTo: uid)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyState();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              return _ActivityTile(
                title: data['itemName'] ?? 'Item',
                subtitle: data['location'] ?? 'Unknown',
                status: data['status'] ?? 'pending',
                date: (data['createdAt'] as Timestamp).toDate(),
                isLost: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Donut Card ────────────────────────────────────────────────────────────
  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: _D.gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tip: Add clear descriptions to increase chances of finding items!",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: _D.bg,
        border: Border(top: BorderSide(color: _D.border)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _D.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0)),
            _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Reports',
                active: _navIndex == 1,
                onTap: () {
                  setState(() => _navIndex = 1);
                  Navigator.pushNamed(context, '/my-reports');
                }),
            _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: _navIndex == 3,
                onTap: () {
                  setState(() => _navIndex = 3);
                  _showProfileSheet(context);
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: _D.gradient,
        shape: BoxShape.circle,
        boxShadow: _D.glow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showReportSheet(context),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _D.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            const Text('New Report',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _D.textHi)),
            const SizedBox(height: 6),
            const Text('What would you like to report?',
                style: TextStyle(fontSize: 13, color: _D.textLow)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SheetAction(
                    icon: Icons.search_off_rounded,
                    label: 'Lost Item',
                    color: _D.red,
                    bg: _D.redBg,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report-lost');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetAction(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Found Item',
                    color: _D.green,
                    bg: _D.greenBg,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report-found');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final initials = user.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _D.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _D.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  gradient: _D.gradient, shape: BoxShape.circle),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 14),
            Text(user.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _D.textHi)),
            const SizedBox(height: 4),
            Text(user.email,
                style:
                const TextStyle(fontSize: 13, color: _D.textMid)),
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _D.primaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _D.primary.withOpacity(0.3)),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _D.primary,
                    letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _D.redBg,
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: _D.red.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text('Sign out',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _D.red)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Stream<int> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) => Text(
              '${snap.data ?? 0}'.padLeft(2, '0'),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _D.textHi,
                  height: 1),
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10, color: _D.textLow)),
        ],
      ),
    );
  }
}

// ─── Activity Tile ────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final bool isLost;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.isLost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLost ? _D.redBg : _D.greenBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isLost
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isLost ? _D.red : _D.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _D.textHi)),
                const SizedBox(height: 3),
                Text(
                  '${isLost ? 'Lost' : 'Found'} · $subtitle · ${_formatDate(date)}',
                  style: const TextStyle(
                      fontSize: 11, color: _D.textLow),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusChip(status: status),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, border) = switch (status) {
      'matched' => (_D.green, _D.greenBg, _D.green.withOpacity(0.3)),
      'claimed' => (_D.primary, _D.primaryBg, _D.primary.withOpacity(0.3)),
      _ => (_D.amber, _D.amberBg, _D.amber.withOpacity(0.3)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─── Legend Item ──────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;
  const _LegendItem(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: _D.textMid)),
        const Spacer(),
        Text(pct,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _D.textHi)),
      ],
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _D.primaryBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20, color: active ? _D.primary : _D.textLow),
            if (active) ...[
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _D.primary)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sheet Action Button ──────────────────────────────────────────────────────
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _D.border),
        ),
        child: Column(
          children: const [
            Icon(Icons.inbox_outlined, color: _D.textLow, size: 38),
            SizedBox(height: 10),
            Text('No activity yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _D.textHi)),
            SizedBox(height: 4),
            Text('Report a lost or found item to get started',
                style: TextStyle(fontSize: 12, color: _D.textLow),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Chart Painter ───────────────────────────────────────────────────
class _ActivityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = _D.border
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 3; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Primary line points (lost items trend)
    final pts1 = [
      Offset(0, h * 0.8),
      Offset(w * 0.2, h * 0.45),
      Offset(w * 0.37, h * 0.35),
      Offset(w * 0.5, h * 0.22),
      Offset(w * 0.65, h * 0.45),
      Offset(w * 0.82, h * 0.28),
      Offset(w, h * 0.32),
    ];

    // Fill under primary line
    final fillPath = Path()..moveTo(0, h);
    fillPath.lineTo(pts1.first.dx, pts1.first.dy);
    for (int i = 0; i < pts1.length - 1; i++) {
      final cp1 = Offset(
          (pts1[i].dx + pts1[i + 1].dx) / 2, pts1[i].dy);
      final cp2 = Offset(
          (pts1[i].dx + pts1[i + 1].dx) / 2, pts1[i + 1].dy);
      fillPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts1[i + 1].dx, pts1[i + 1].dy);
    }
    fillPath.lineTo(w, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _D.primary.withOpacity(0.28),
          _D.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Primary stroke
    final linePaint1 = Paint()
      ..color = _D.primary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath1 = Path()..moveTo(pts1.first.dx, pts1.first.dy);
    for (int i = 0; i < pts1.length - 1; i++) {
      final cp1 = Offset(
          (pts1[i].dx + pts1[i + 1].dx) / 2, pts1[i].dy);
      final cp2 = Offset(
          (pts1[i].dx + pts1[i + 1].dx) / 2, pts1[i + 1].dy);
      linePath1.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts1[i + 1].dx, pts1[i + 1].dy);
    }
    canvas.drawPath(linePath1, linePaint1);

    // Secondary dashed line (found items)
    final pts2 = [
      Offset(0, h * 0.9),
      Offset(w * 0.2, h * 0.65),
      Offset(w * 0.37, h * 0.75),
      Offset(w * 0.5, h * 0.6),
      Offset(w * 0.65, h * 0.5),
      Offset(w * 0.82, h * 0.45),
      Offset(w, h * 0.52),
    ];

    final dashPaint = Paint()
      ..color = _D.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashed
    final dashPath = Path()..moveTo(pts2.first.dx, pts2.first.dy);
    for (int i = 0; i < pts2.length - 1; i++) {
      final cp1 = Offset((pts2[i].dx + pts2[i + 1].dx) / 2, pts2[i].dy);
      final cp2 = Offset((pts2[i].dx + pts2[i + 1].dx) / 2, pts2[i + 1].dy);
      dashPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts2[i + 1].dx, pts2[i + 1].dy);
    }
    _drawDashedPath(canvas, dashPath, dashPaint);

    // Highlight dot at peak
    final dotX = w * 0.5;
    final dotY = h * 0.22;
    canvas.drawCircle(
        Offset(dotX, dotY), 7, Paint()..color = _D.primary.withOpacity(0.2));
    canvas.drawCircle(
        Offset(dotX, dotY), 4, Paint()..color = _D.primary);
    canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    const dashLength = 5.0;
    const gapLength = 4.0;
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(
              metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final int total;
  const _DonutPainter({required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final segments = [
      (0.38, _D.primary),
      (0.24, _D.green),
      (0.21, _D.red),
      (0.17, _D.amber),
    ];

    // Track background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _D.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final (pct, color) in segments) {
      final sweep = (pct * 2 * math.pi) - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += pct * 2 * math.pi;
    }

    // Center text
    final numPainter = TextPainter(
      text: TextSpan(
        text: '$total',
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _D.textHi),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numPainter.paint(
        canvas,
        center -
            Offset(numPainter.width / 2, numPainter.height / 2 + 7));

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'reports',
        style: const TextStyle(fontSize: 9, color: _D.textLow),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
        canvas,
        center -
            Offset(labelPainter.width / 2, -numPainter.height / 2 - 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}