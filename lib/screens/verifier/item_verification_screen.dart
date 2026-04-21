import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/found_item_model.dart';
import '../../models/lost_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';

class ItemVerificationScreen extends StatefulWidget {
  const ItemVerificationScreen({super.key});

  @override
  State<ItemVerificationScreen> createState() => _ItemVerificationScreenState();
}

class _ItemVerificationScreenState extends State<ItemVerificationScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isApproving = false;
  LostItemModel? _selectedLost;
  FoundItemModel? _selectedFound;
  List<LostItemModel> _lostItems = [];
  List<FoundItemModel> _foundItems = [];

  @override
  void initState() {
    super.initState();
    _fs.getPendingLostItems().listen((items) {
      if (mounted) setState(() => _lostItems = items);
    });
    _fs.getPendingFoundItems().listen((items) {
      if (mounted) setState(() => _foundItems = items);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _approveMatch() async {
    if (_selectedLost == null || _selectedFound == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Select one lost item and one found item first'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _isApproving = true);
    try {
      final verifierId = context.read<AuthProvider>().currentUser!.uid;
      await _fs.approveMatch(
        lostItemId: _selectedLost!.lostItemId,
        foundItemId: _selectedFound!.foundItemId,
        verifierId: verifierId,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Match approved and owner notified'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.softGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
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
                            Text('Item verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                            Text(
                              'Compare evidence carefully before approving a match.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _InfoCard(
                      title: 'Review checklist',
                      subtitle:
                          'Confirm description, category, location, and the confidential identifier before approving.',
                    ),
                    const SizedBox(height: 18),
                    _PickerSection<LostItemModel>(
                      title: 'Select lost item',
                      items: _lostItems,
                      selected: _selectedLost,
                      titleBuilder: (item) => item.itemName,
                      imageBuilder: (item) => item.photoURL,
                      fallbackIcon: Icons.search_off_rounded,
                      color: AppTheme.error,
                      onSelect: (item) => setState(() => _selectedLost = item),
                    ),
                    const SizedBox(height: 18),
                    _PickerSection<FoundItemModel>(
                      title: 'Select found item',
                      items: _foundItems,
                      selected: _selectedFound,
                      titleBuilder: (item) => item.description,
                      imageBuilder: (item) => item.photoURL,
                      fallbackIcon: Icons.inventory_2_rounded,
                      color: AppTheme.success,
                      onSelect: (item) => setState(() => _selectedFound = item),
                    ),
                    if (_selectedLost != null && _selectedFound != null) ...[
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DetailCard(
                              title: 'Lost report',
                              color: AppTheme.error,
                              imageUrl: _selectedLost!.photoURL,
                              details: {
                                'Name': _selectedLost!.itemName,
                                'Category': _selectedLost!.category ?? 'Not provided',
                                'Locations': _selectedLost!.possibleLocations.join(', '),
                                'Description': _selectedLost!.description ?? 'Not provided',
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _DetailCard(
                              title: 'Found report',
                              color: AppTheme.success,
                              imageUrl: _selectedFound!.photoURL,
                              details: {
                                'Description': _selectedFound!.description,
                                'Category': _selectedFound!.category ?? 'Not provided',
                                'Found at': _selectedFound!.locationFound,
                                'Stored at': _selectedFound!.storageOption,
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SecretCard(secret: _selectedLost!.secretIdentificationDetail),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Verification notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Optional notes for the verification record',
                              ),
                            ),
                            const SizedBox(height: 18),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final stackButtons = constraints.maxWidth < 420;
                                if (stackButtons) {
                                  return Column(
                                    children: [
                                      AppButton(
                                        text: 'Approve match',
                                        onPressed: _approveMatch,
                                        isLoading: _isApproving,
                                        color: AppTheme.success,
                                        icon: Icons.check_circle_outline_rounded,
                                      ),
                                      const SizedBox(height: 12),
                                      AppButton(
                                        text: 'Cancel',
                                        onPressed: () => Navigator.pop(context),
                                        isOutlined: true,
                                        color: AppTheme.error,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        text: 'Cancel',
                                        onPressed: () => Navigator.pop(context),
                                        isOutlined: true,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppButton(
                                        text: 'Approve match',
                                        onPressed: _approveMatch,
                                        isLoading: _isApproving,
                                        color: AppTheme.success,
                                        icon: Icons.check_circle_outline_rounded,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.fact_check_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selected;
  final String? Function(T) imageBuilder;
  final String Function(T) titleBuilder;
  final IconData fallbackIcon;
  final Color color;
  final ValueChanged<T> onSelect;

  const _PickerSection({
    required this.title,
    required this.items,
    required this.selected,
    required this.imageBuilder,
    required this.titleBuilder,
    required this.fallbackIcon,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text('No pending records available', style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
          SizedBox(
            height: 124,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = identical(item, selected);
                final imageUrl = imageBuilder(item);
                return GestureDetector(
                  onTap: () => onSelect(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.border,
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                          child: SizedBox(
                            width: 64,
                            height: 124,
                            child: imageUrl == null
                                ? Container(
                                    color: color.withOpacity(0.12),
                                    child: Icon(fallbackIcon, color: color),
                                  )
                                : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              titleBuilder(item),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? color : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Color color;
  final String? imageUrl;
  final Map<String, String> details;

  const _DetailCard({
    required this.title,
    required this.color,
    required this.imageUrl,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.22)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: !hasImage
                  ? const BorderRadius.vertical(top: Radius.circular(28))
                  : null,
            ),
            child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: details.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: const TextStyle(color: AppTheme.textPrimary, height: 1.5),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretCard extends StatelessWidget {
  final String secret;

  const _SecretCard({required this.secret});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppTheme.warning),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confidential owner identifier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(secret, style: const TextStyle(color: AppTheme.textPrimary, height: 1.5)),
          const SizedBox(height: 8),
          const Text(
            'Use this only during verification to confirm the claimant knows the private identifying detail.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
