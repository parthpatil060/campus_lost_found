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
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(50, 50),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          Text(
                            'Review every lost and found report you have submitted.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      color: AppTheme.canvas.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelPadding: EdgeInsets.zero,
                    tabs: const [
                      Tab(text: 'Lost items'),
                      Tab(text: 'Found items'),
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
                            title: 'No lost reports',
                            subtitle: 'Start by submitting a lost item report with clear identifying details.',
                            icon: Icons.search_off_rounded,
                            actionLabel: 'Report lost item',
                            onTap: () => Navigator.pushNamed(context, '/report-lost'),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                            title: 'No found reports',
                            subtitle: 'When you recover an item on campus, log it here for verification.',
                            icon: Icons.inventory_2_rounded,
                            actionLabel: 'Report found item',
                            onTap: () => Navigator.pushNamed(context, '/report-found'),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
      subtitle: item.category ?? 'Lost item',
      meta: item.possibleLocations.join(', '),
      date: item.createdAt,
      status: item.status,
      fallbackIcon: Icons.search_off_rounded,
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
      subtitle: item.category ?? 'Found item',
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
            child: SizedBox(
              width: 102,
              height: 122,
              child: image ??
                  Container(
                    color: fallbackColor.withOpacity(0.12),
                    child: Icon(fallbackIcon, color: fallbackColor, size: 34),
                  ),
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
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
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
  final VoidCallback onTap;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onTap, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
