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
    _tabController = TabController(length: 2, vsync: this);
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
        primaryLabel: 'Review queue',
        onSecondary: () => Navigator.pushNamed(context, '/verify-item'),
        secondaryLabel: 'Open matcher',
        onLogout: () async {
          await context.read<AuthProvider>().signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: DecoratedBox(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _VerifierHero(name: verifier?.name ?? 'Verifier', fs: _fs),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelPadding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: 'Lost queue'),
                      Tab(text: 'Found queue'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    StreamBuilder<List<LostItemModel>>(
                      stream: _fs.getAllLostItems(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snapshot.data!;
                        if (items.isEmpty) {
                          return const _VerifierEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No lost items in queue',
                            subtitle: 'New student reports will appear here for review.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _LostVerifyCard(
                            item: items[index],
                            onCompare: () => Navigator.pushNamed(
                              context,
                              '/verify-item',
                              arguments: {'lostItem': items[index]},
                            ),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<List<FoundItemModel>>(
                      stream: _fs.getAllFoundItems(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final items = snapshot.data!;
                        if (items.isEmpty) {
                          return const _VerifierEmptyState(
                            icon: Icons.inventory_2_rounded,
                            title: 'No found items in queue',
                            subtitle: 'New submissions will appear here for review and matching.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _FoundVerifyCard(
                            item: items[index],
                            onCompare: () => Navigator.pushNamed(
                              context,
                              '/verify-item',
                              arguments: {'foundItem': items[index]},
                            ),
                          ),
                        );
                      },
                    ),
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
            final pending = pendingSnapshot.data?.length ?? 0;
            final matched =
                lostSnapshot.data?.where((item) => item.status == 'matched').length ?? 0;
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifier panel',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hello, ${name.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Review reports, compare evidence, and confirm the right matches.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroStat(label: 'Pending', value: '$pending'),
                      const SizedBox(width: 12),
                      _HeroStat(label: 'Matched', value: '$matched'),
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
          borderRadius: BorderRadius.circular(999),
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
                initials.isEmpty ? 'V' : initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
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
                'Verifier workspace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                name,
                style: const TextStyle(color: AppTheme.textSecondary),
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
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials.isEmpty ? 'V' : initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DrawerAction(label: primaryLabel, icon: Icons.dashboard_outlined, onTap: onPrimary),
              _DrawerAction(label: secondaryLabel, icon: Icons.compare_arrows_rounded, onTap: onSecondary),
              const Spacer(),
              _DrawerAction(
                label: 'Logout',
                icon: Icons.logout_rounded,
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
      icon: Icons.search_off_rounded,
      color: AppTheme.error,
      actionLabel: 'Compare and match',
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
      actionLabel: 'Open comparison',
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 82,
              height: 82,
              child: image ??
                  Container(
                    color: color.withOpacity(0.12),
                    child: Icon(icon, color: color, size: 30),
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle.isEmpty ? 'Campus submission' : subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (pending) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: Text(actionLabel),
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

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
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
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
