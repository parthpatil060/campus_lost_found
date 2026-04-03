import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/lost_item_model.dart';
import '../../models/found_item_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/status_badge.dart';

class VerifierDashboard extends StatefulWidget {
  const VerifierDashboard({super.key});

  @override
  State<VerifierDashboard> createState() => _VerifierDashboardState();
}

class _VerifierDashboardState extends State<VerifierDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _fs = FirestoreService();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() => _tabIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final verifier = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        (verifier?.name ?? 'V')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campus L&F',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1A1D23),
                          ),
                        ),
                        Text(
                          verifier?.name ?? 'Verifier',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logout button
                  PopupMenuButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_vert,
                          color: Color(0xFF1A1D23), size: 20),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Logout',
                              style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await context.read<AuthProvider>().signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Greeting + Stats ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${verifier?.name?.split(' ').first ?? 'Verifier'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<List<FoundItemModel>>(
                    stream: _fs.getPendingFoundItems(),
                    builder: (_, snap) {
                      final pending = snap.data?.length ?? 0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$pending',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'pending\nreviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D23),
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🛡️ Verifier Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Stat Cards Row
                  StreamBuilder<List<LostItemModel>>(
                    stream: _fs.getAllLostItems(),
                    builder: (_, lostSnap) {
                      return StreamBuilder<List<FoundItemModel>>(
                        stream: _fs.getAllFoundItems(),
                        builder: (_, foundSnap) {
                          final lostItems = lostSnap.data ?? [];
                          final foundItems = foundSnap.data ?? [];
                          final matched = lostItems
                              .where((i) => i.status == 'matched')
                              .length;

                          return Row(
                            children: [
                              _StatCard(
                                icon: '⚠️',
                                iconBg: const Color(0xFFFFEBEE),
                                count: lostItems.length,
                                label: 'Lost',
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: '✅',
                                iconBg: const Color(0xFFE8F5E9),
                                count: foundItems.length,
                                label: 'Found',
                              ),
                              const SizedBox(width: 10),
                              _StatCard(
                                icon: '🔗',
                                iconBg: const Color(0xFFEDE7F6),
                                count: matched,
                                label: 'Matched',
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tab Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8A94A6),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Lost Items'),
                    Tab(text: 'Found Items'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab Content ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // LOST ITEMS
                  StreamBuilder<List<LostItemModel>>(
                    stream: _fs.getAllLostItems(),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return _EmptyState(
                            emoji: '😢', label: 'No lost items reported yet.');
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _LostItemVerifyCard(
                          item: items[i],
                          onCompare: () => Navigator.pushNamed(
                              context, '/verify-item',
                              arguments: {'lostItem': items[i]}),
                        ),
                      );
                    },
                  ),

                  // FOUND ITEMS
                  StreamBuilder<List<FoundItemModel>>(
                    stream: _fs.getAllFoundItems(),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return _EmptyState(
                            emoji: '🎉', label: 'No found items reported yet.');
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _FoundItemVerifyCard(
                          item: items[i],
                          onCompare: () => Navigator.pushNamed(
                              context, '/verify-item',
                              arguments: {'foundItem': items[i]}),
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
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final int count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 10),
            Text(
              count.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D23),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String label;

  const _EmptyState({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF8A94A6))),
        ],
      ),
    );
  }
}

// ── Lost Item Card ────────────────────────────────────────────────────────────

class _LostItemVerifyCard extends StatelessWidget {
  final LostItemModel item;
  final VoidCallback onCompare;

  const _LostItemVerifyCard(
      {required this.item, required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: item.photoURL != null
                    ? CachedNetworkImage(
                    imageUrl: item.photoURL!, fit: BoxFit.cover)
                    : Container(
                    color: const Color(0xFFFFEBEE),
                    child: const Center(
                        child:
                        Text('😢', style: TextStyle(fontSize: 24)))),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23),
                          ),
                        ),
                      ),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Lost · ${item.possibleLocations.take(2).join(', ')} · '
                        '${DateFormat('MMM d').format(item.createdAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A94A6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.status == 'pending') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCompare,
                        icon: const Icon(Icons.compare_arrows_rounded,
                            size: 15),
                        label: const Text('Compare & Match'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Found Item Card ───────────────────────────────────────────────────────────

class _FoundItemVerifyCard extends StatelessWidget {
  final FoundItemModel item;
  final VoidCallback onCompare;

  const _FoundItemVerifyCard(
      {required this.item, required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: CachedNetworkImage(
                  imageUrl: item.photoURL,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: const Color(0xFFE8F5E9),
                      child: const Center(
                          child:
                          Text('🎉', style: TextStyle(fontSize: 24)))),
                  errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFFE8F5E9),
                      child: const Center(
                          child:
                          Text('🎉', style: TextStyle(fontSize: 24)))),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Found · ${item.locationFound}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A94A6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.status == 'pending') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCompare,
                        icon: const Icon(Icons.compare_arrows_rounded,
                            size: 15),
                        label: const Text('Compare & Match'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}