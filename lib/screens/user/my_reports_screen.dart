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

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
      appBar: AppBar(
        title: const Text('My Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Lost Items'),
            Tab(text: 'Found Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // LOST ITEMS TAB
          StreamBuilder<List<LostItemModel>>(
            stream: _fs.getLostItemsByUser(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _EmptyState(
                  emoji: '😢',
                  title: 'No Lost Items',
                  subtitle: 'You haven\'t reported any lost items yet.',
                  actionLabel: 'Report a Lost Item',
                  onAction: () =>
                      Navigator.pushNamed(context, '/report-lost'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (_, i) => _LostItemCard(item: items[i]),
              );
            },
          ),

          // FOUND ITEMS TAB
          StreamBuilder<List<FoundItemModel>>(
            stream: _fs.getFoundItemsByUser(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _EmptyState(
                  emoji: '🎉',
                  title: 'No Found Items',
                  subtitle: 'You haven\'t reported any found items yet.',
                  actionLabel: 'Report a Found Item',
                  onAction: () =>
                      Navigator.pushNamed(context, '/report-found'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (_, i) => _FoundItemCard(item: items[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LostItemCard extends StatelessWidget {
  final LostItemModel item;
  const _LostItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.cardRadius),
              bottomLeft: Radius.circular(AppTheme.cardRadius),
            ),
            child: SizedBox(
              width: 88,
              height: 96,
              child: item.photoURL != null
                  ? CachedNetworkImage(
                imageUrl: item.photoURL!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: const Color(0xFFFFEBEE),
                child: const Center(
                    child: Text('😢',
                        style: TextStyle(fontSize: 32))),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.itemName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Text(item.category!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                  if (item.possibleLocations.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.possibleLocations.join(', '),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(item.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
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

class _FoundItemCard extends StatelessWidget {
  final FoundItemModel item;
  const _FoundItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.cardRadius),
              bottomLeft: Radius.circular(AppTheme.cardRadius),
            ),
            child: SizedBox(
              width: 88,
              height: 96,
              child: CachedNetworkImage(
                imageUrl: item.photoURL,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                        child:
                        Text('🎉', style: TextStyle(fontSize: 32)))),
                errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                        child:
                        Text('🎉', style: TextStyle(fontSize: 32)))),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.description,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(status: item.status),
                    ],
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Text(item.category!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(item.locationFound,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.storage_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(item.storageOption,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(item.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
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
  final String emoji;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
