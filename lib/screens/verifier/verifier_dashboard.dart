import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/found_item_model.dart';
import '../../models/lost_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/status_badge.dart';

// ── BROADCAST FEATURE START ──
import '../../models/broadcast_model.dart';
import '../../widgets/broadcast_card.dart';
// ── BROADCAST FEATURE END ──

class VerifierDashboard extends StatefulWidget {
  const VerifierDashboard({super.key});

  @override
  State<VerifierDashboard> createState() => _VerifierDashboardState();
}

class _VerifierDashboardState extends State<VerifierDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _fs = FirestoreService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // ── BROADCAST FEATURE START ──
    _tabController = TabController(length: 3, vsync: this);
    // ── BROADCAST FEATURE END ──
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verifier = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _RoleDrawer(
        name: verifier?.name ?? 'Verifier',
        email: verifier?.email ?? '',
        onPrimary: () {},
        primaryLabel: 'Review Queue',
        onSecondary: () => Navigator.pushNamed(context, '/verify-item'),
        secondaryLabel: 'Open Matcher Tool',
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _RoleTopBar(
                  name: verifier?.name ?? 'Verifier',
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _VerifierHero(name: verifier?.name ?? 'Verifier', fs: _fs),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Lost Reports'),
                      Tab(text: 'Found Items'),
                      // ── BROADCAST FEATURE START ──
                      Tab(text: 'Broadcasts'),
                      // ── BROADCAST FEATURE END ──
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ReviewQueueList<LostItemModel>(
                      stream: _fs.getAllLostItems(),
                      isLost: true,
                      emptyTitle: 'No lost reports in queue',
                      emptySubtitle: 'Student submissions will appear here for review.',
                      cardBuilder: (item) => _LostVerifyCard(
                        item: item,
                        onCompare: () => Navigator.pushNamed(
                          context,
                          '/verify-item',
                          arguments: {'lostItem': item},
                        ),
                      ),
                    ),
                    _ReviewQueueList<FoundItemModel>(
                      stream: _fs.getAllFoundItems(),
                      isLost: false,
                      emptyTitle: 'No found items in queue',
                      emptySubtitle: 'New submissions will appear here for match processing.',
                      cardBuilder: (item) => _FoundVerifyCard(
                        item: item,
                        onCompare: () => Navigator.pushNamed(
                          context,
                          '/verify-item',
                          arguments: {'foundItem': item},
                        ),
                      ),
                    ),
                    // ── BROADCAST FEATURE START ──
                    _BroadcastsTab(
                      fs: _fs,
                      verifier: context.watch<AuthProvider>().currentUser,
                    ),
                    // ── BROADCAST FEATURE END ──
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewQueueList<T> extends StatelessWidget {
  final Stream<List<T>> stream;
  final bool isLost;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(T) cardBuilder;

  const _ReviewQueueList({
    required this.stream,
    required this.isLost,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) {
          return _VerifierEmptyState(
            icon: isLost ? Icons.search_off_rounded : Icons.inventory_2_rounded,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          itemCount: items.length,
          itemBuilder: (context, index) => cardBuilder(items[index]),
        );
      },
    );
  }
}

class _VerifierHero extends StatelessWidget {
  final String name;
  final FirestoreService fs;

  const _VerifierHero({required this.name, required this.fs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoundItemModel>>(
      stream: fs.getPendingFoundItems(),
      builder: (context, pendingSnapshot) {
        return StreamBuilder<List<LostItemModel>>(
          stream: fs.getAllLostItems(),
          builder: (context, lostSnapshot) {
            return StreamBuilder<List<BroadcastModel>>(
              stream: fs.getActiveBroadcasts(),
              builder: (context, broadcastSnapshot) {
                final pending = pendingSnapshot.data?.length ?? 0;
                final matched =
                    lostSnapshot.data?.where((item) => item.status == 'matched').length ?? 0;
                final broadcastCount = broadcastSnapshot.data?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.verified_user_rounded, size: 120, color: Colors.white.withOpacity(0.08)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: AppTheme.glassDecoration(opacity: 0.15, radius: BorderRadius.circular(12)),
                            child: const Text(
                              'Verifier Access Active',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Hello, ${name.split(' ').first}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Process students reports and confirm matches to help return items.',
                            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _HeroMetricPill(label: 'Pending', value: '$pending', color: AppTheme.accent),
                              _HeroMetricPill(label: 'Matched', value: '$matched', color: AppTheme.success),
                              _HeroMetricPill(label: 'Broadcast', value: '$broadcastCount', color: const Color(0xFF4FC3F7)),
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
  final Color color;

  const _HeroMetricPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.glassDecoration(opacity: 0.15, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RoleTopBar extends StatelessWidget {
  final String name;
  final VoidCallback onMenuTap;

  const _RoleTopBar({required this.name, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Row(
      children: [
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(18),
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
                initials.isEmpty ? 'V' : initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.primary,
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
              const Text(
                'Verifier Workspace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Managing Campus Submissions',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleDrawer extends StatelessWidget {
  final String name;
  final String email;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onLogout;

  const _RoleDrawer({
    required this.name,
    required this.email,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
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
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials.isEmpty ? 'V' : initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Verified Staff',
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
                _DrawerAction(label: primaryLabel, icon: Icons.playlist_add_check_rounded, onTap: onPrimary),
                _DrawerAction(label: secondaryLabel, icon: Icons.compare_arrows_rounded, onTap: onSecondary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _DrawerAction(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              color: AppTheme.error,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textPrimary;
    return ListTile(
      leading: Icon(icon, color: effectiveColor.withOpacity(0.7)),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _LostVerifyCard extends StatelessWidget {
  final LostItemModel item;
  final VoidCallback onCompare;

  const _LostVerifyCard({required this.item, required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return _VerifyCardShell(
      title: item.itemName,
      subtitle: item.possibleLocations.take(2).join(', '),
      date: item.createdAt,
      status: item.status,
      image: item.photoURL == null
          ? null
          : CachedNetworkImage(imageUrl: item.photoURL!, fit: BoxFit.cover),
      icon: Icons.help_center_outlined,
      color: AppTheme.error,
      actionLabel: 'Compare Details',
      onTap: onCompare,
    );
  }
}

class _FoundVerifyCard extends StatelessWidget {
  final FoundItemModel item;
  final VoidCallback onCompare;

  const _FoundVerifyCard({required this.item, required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return _VerifyCardShell(
      title: item.description,
      subtitle: item.locationFound,
      date: item.createdAt,
      status: item.status,
      image: CachedNetworkImage(imageUrl: item.photoURL, fit: BoxFit.cover),
      icon: Icons.inventory_2_rounded,
      color: AppTheme.success,
      actionLabel: 'Check for Matches',
      onTap: onCompare,
    );
  }
}

class _VerifyCardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final String status;
  final Widget? image;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  const _VerifyCardShell({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.image,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: image ??
                Container(
                  color: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 28),
                ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: status, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Campus Submission' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textSecondary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (pending) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: Text(actionLabel, style: const TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final isMatched = status == 'matched';
    final effectiveColor = isMatched ? AppTheme.primary : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: effectiveColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

class _VerifierEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _VerifierEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(icon, color: AppTheme.textSecondary.withOpacity(0.3), size: 54),
            ),
            const SizedBox(height: 28),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BROADCAST FEATURE START ──

/// The Broadcasts tab shown to verifiers.
/// Section A: active broadcasts list with deactivate.
/// Section B: create new broadcast buttons.
class _BroadcastsTab extends StatefulWidget {
  final FirestoreService fs;
  final dynamic verifier; // UserModel

  const _BroadcastsTab({required this.fs, required this.verifier});

  @override
  State<_BroadcastsTab> createState() => _BroadcastsTabState();
}

class _BroadcastsTabState extends State<_BroadcastsTab> {
  void _confirmDeactivate(BuildContext context, BroadcastModel broadcast) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Broadcast'),
        content: Text('Stop broadcasting "${broadcast.itemName}" to all users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.fs.deactivateBroadcast(broadcast.broadcastId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Broadcast deactivated.'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Deactivate', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showCreateBroadcastSheet(BuildContext context, String broadcastType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateBroadcastSheet(
        fs: widget.fs,
        broadcastType: broadcastType,
        verifierId: widget.verifier?.uid ?? '',
        verifierName: widget.verifier?.name ?? 'Verifier',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Broadcast',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BroadcastTypeButton(
                  label: 'Broadcast a\nLost Item',
                  icon: Icons.search_off_rounded,
                  color: AppTheme.primary,
                  onTap: () => _showCreateBroadcastSheet(context, 'lost_broadcast'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BroadcastTypeButton(
                  label: 'Broadcast a\nFound Item',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF7C73E6),
                  onTap: () => _showCreateBroadcastSheet(context, 'found_broadcast'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Active Broadcasts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<BroadcastModel>>(
            stream: widget.fs.getActiveBroadcasts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 30),
                      SizedBox(height: 10),
                      Text(
                        'Broadcast access is blocked by Firestore rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Deploy the latest Firestore rules and confirm this account has verifier access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                      ),
                    ],
                  ),
                );
              }
              final broadcasts = snap.data ?? [];
              if (broadcasts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign_outlined, color: AppTheme.primary, size: 30),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No active broadcasts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create a notice to alert students about a lost report or found item.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: broadcasts
                    .map((b) => BroadcastCard(
                          broadcast: b,
                          currentUserId: widget.verifier?.uid ?? '',
                          compact: true,
                          onDeactivate: (bc) => _confirmDeactivate(context, bc),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BroadcastTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BroadcastTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.16),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.22)),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateBroadcastSheet extends StatefulWidget {
  final FirestoreService fs;
  final String broadcastType;
  final String verifierId;
  final String verifierName;

  const _CreateBroadcastSheet({
    required this.fs,
    required this.broadcastType,
    required this.verifierId,
    required this.verifierName,
  });

  @override
  State<_CreateBroadcastSheet> createState() => _CreateBroadcastSheetState();
}

class _CreateBroadcastSheetState extends State<_CreateBroadcastSheet> {
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  LostItemModel? _selectedLost;
  FoundItemModel? _selectedFound;
  Map<String, bool> _alreadyBroadcast = {};

  bool get _isLost => widget.broadcastType == 'lost_broadcast';

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting(String itemId) async {
    if (_alreadyBroadcast.containsKey(itemId)) return;
    final exists = await widget.fs.broadcastExistsForItem(itemId);
    if (mounted) {
      setState(() => _alreadyBroadcast[itemId] = exists);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedId = _isLost ? _selectedLost?.lostItemId : _selectedFound?.foundItemId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an item to broadcast.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String itemName, itemDesc, itemPhoto, locationInfo;
      if (_isLost) {
        itemName = _selectedLost!.itemName;
        itemDesc = _selectedLost!.description ?? '';
        itemPhoto = _selectedLost!.photoURL ?? '';
        locationInfo = _selectedLost!.possibleLocations.join(', ');
      } else {
        itemName = _selectedFound!.description;
        itemDesc = _selectedFound!.description;
        itemPhoto = _selectedFound!.photoURL;
        locationInfo = _selectedFound!.locationFound;
      }

      await widget.fs.createBroadcast(
        broadcastType: widget.broadcastType,
        sourceItemId: selectedId,
        itemName: itemName,
        itemDescription: itemDesc,
        itemPhotoURL: itemPhoto,
        locationInfo: locationInfo,
        verifierMessage: _messageCtrl.text.trim(),
        createdByVerifierId: widget.verifierId,
        createdByName: widget.verifierName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Broadcast sent to all users ?'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: '),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
  Widget _buildItemSelector() {
    if (_isLost) {
      return StreamBuilder<List<LostItemModel>>(
        stream: widget.fs.getPendingLostItems(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Text('No pending lost items.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          for (final item in items) {
            _checkExisting(item.lostItemId);
          }
          return Column(
            children: items.map((item) {
              final alreadyBroadcasting = _alreadyBroadcast[item.lostItemId] == true;
              final isSelected = _selectedLost?.lostItemId == item.lostItemId;
              return GestureDetector(
                onTap: alreadyBroadcasting ? null : () => setState(() => _selectedLost = item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.grey.shade50,
                    border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: alreadyBroadcasting ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (alreadyBroadcasting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Already broadcasting',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    } else {
      return StreamBuilder<List<FoundItemModel>>(
        stream: widget.fs.getPendingFoundItems(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Text('No pending found items.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          for (final item in items) {
            _checkExisting(item.foundItemId);
          }
          return Column(
            children: items.map((item) {
              final alreadyBroadcasting = _alreadyBroadcast[item.foundItemId] == true;
              final isSelected = _selectedFound?.foundItemId == item.foundItemId;
              return GestureDetector(
                onTap: alreadyBroadcasting ? null : () => setState(() => _selectedFound = item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C73E6).withOpacity(0.08) : Colors.grey.shade50,
                    border: Border.all(
                        color: isSelected ? const Color(0xFF7C73E6) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: alreadyBroadcasting ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (alreadyBroadcasting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Already broadcasting',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF7C73E6), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    }
  }

  Widget _buildItemPreview() {
    if (_isLost && _selectedLost != null) {
      final item = _selectedLost!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (item.photoURL != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.photoURL!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(width: 60, height: 60, color: Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200),
                ),
              ),
            if (item.photoURL != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (item.description != null)
                    Text(item.description!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  Text(item.possibleLocations.take(2).join(', '),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (!_isLost && _selectedFound != null) {
      final item = _selectedFound!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF7C73E6).withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.photoURL,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 60, height: 60, color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('Found at: ${item.locationFound}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isLost ? AppTheme.primary : const Color(0xFF7C73E6);
    final title = _isLost ? 'Broadcast a Lost Item' : 'Broadcast a Found Item';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Share a short campus notice that matches the verifier workspace styling.',
                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.95)),
                ),
                const SizedBox(height: 16),

                // Item selector
                Text('Select Item',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 8),
                _buildItemSelector(),

                // Selected item preview
                if ((_isLost && _selectedLost != null) || (!_isLost && _selectedFound != null)) ...[
                  const SizedBox(height: 12),
                  Text('Preview',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 8),
                  _buildItemPreview(),
                ],

                const SizedBox(height: 16),
                Text('Message for Users',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageCtrl,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a message for users...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send Broadcast', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ── BROADCAST FEATURE END ──
