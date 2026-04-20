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

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _fs = FirestoreService();

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
    final uid = context.read<AuthProvider>().currentUser!.uid;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Reports',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                        ),
                        Text(
                          'Tracking your submissions',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Lost Items'),
                    Tab(text: 'Found Items'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StreamBuilder<List<LostItemModel>>(
                    stream: _fs.getLostItemsByUser(uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data!;
                      if (items.isEmpty) {
                        return _EmptyState(
                          title: 'No lost reports yet',
                          subtitle: 'Items you report as lost will appear here.',
                          icon: Icons.search_off_rounded,
                          actionLabel: 'Report Lost Item',
                          color: AppTheme.error,
                          onTap: () => Navigator.pushNamed(context, '/report-lost'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _LostReportTile(item: items[index]),
                      );
                    },
                  ),
                  StreamBuilder<List<FoundItemModel>>(
                    stream: _fs.getFoundItemsByUser(uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data!;
                      if (items.isEmpty) {
                        return _EmptyState(
                          title: 'No found reports yet',
                          subtitle: 'Items you report as found will appear here.',
                          icon: Icons.inventory_2_rounded,
                          actionLabel: 'Report Found Item',
                          color: AppTheme.success,
                          onTap: () => Navigator.pushNamed(context, '/report-found'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _FoundReportTile(item: items[index]),
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

class _LostReportTile extends StatelessWidget {
  final LostItemModel item;

  const _LostReportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ReportTileShell(
      title: item.itemName,
      subtitle: item.category ?? 'Lost Item',
      meta: item.possibleLocations.join(', '),
      date: item.createdAt,
      status: item.status,
      fallbackIcon: Icons.help_outline_rounded,
      fallbackColor: AppTheme.error,
      image: item.photoURL == null
          ? null
          : CachedNetworkImage(imageUrl: item.photoURL!, fit: BoxFit.cover),
    );
  }
}

class _FoundReportTile extends StatelessWidget {
  final FoundItemModel item;

  const _FoundReportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return _ReportTileShell(
      title: item.description,
      subtitle: item.category ?? 'Found Item',
      meta: '${item.locationFound} · ${item.storageOption}',
      date: item.createdAt,
      status: item.status,
      fallbackIcon: Icons.inventory_2_rounded,
      fallbackColor: AppTheme.success,
      image: CachedNetworkImage(imageUrl: item.photoURL, fit: BoxFit.cover),
    );
  }
}

class _ReportTileShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final DateTime date;
  final String status;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final Widget? image;

  const _ReportTileShell({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.date,
    required this.status,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: image ??
                    Container(
                      color: fallbackColor.withOpacity(0.1),
                      child: Icon(fallbackIcon, color: fallbackColor, size: 32),
                    ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                 Icon(Icons.access_time_filled_rounded, size: 16, color: AppTheme.textSecondary.withOpacity(0.4)),
                 const SizedBox(width: 8),
                 Text(
                   DateFormat('MMMM d, yyyy').format(date),
                   style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w700),
                 ),
                 const Spacer(),
                 const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final Color color;
  final VoidCallback onTap;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.color,
    required this.onTap,
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
              child: Icon(icon, color: color.withOpacity(0.4), size: 52),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
