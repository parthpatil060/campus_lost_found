import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/lost_item_model.dart';
import '../../models/found_item_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';

class ItemVerificationScreen extends StatefulWidget {
  const ItemVerificationScreen({super.key});

  @override
  State<ItemVerificationScreen> createState() =>
      _ItemVerificationScreenState();
}

class _ItemVerificationScreenState extends State<ItemVerificationScreen> {
  final FirestoreService _fs = FirestoreService();
  bool _isApproving = false;
  LostItemModel? _selectedLost;
  FoundItemModel? _selectedFound;
  List<LostItemModel> _lostItems = [];
  List<FoundItemModel> _foundItems = [];
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both a lost item and a found item'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
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
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Match approved! Owner has been notified.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Item Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select a lost item and a found item, compare details manually, then approve or reject the match.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── LOST ITEM SELECTOR ───────────────────────────────────
            _sectionHeader('😢 Select Lost Item'),
            const SizedBox(height: 10),
            if (_lostItems.isEmpty)
              _emptyChip('No pending lost items')
            else
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _lostItems.length,
                  itemBuilder: (_, i) {
                    final item = _lostItems[i];
                    final isSelected = _selectedLost?.lostItemId == item.lostItemId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLost = item),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? AppTheme.buttonShadow : [],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(11),
                                bottomLeft: Radius.circular(11),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 90,
                                child: item.photoURL != null
                                    ? CachedNetworkImage(
                                    imageUrl: item.photoURL!,
                                    fit: BoxFit.cover)
                                    : Container(
                                    color: const Color(0xFFFFEBEE),
                                    child: const Center(
                                        child: Text('😢'))),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  item.itemName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                  ),
                                  maxLines: 2,
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

            const SizedBox(height: 20),

            // ─── FOUND ITEM SELECTOR ──────────────────────────────────
            _sectionHeader('🎉 Select Found Item'),
            const SizedBox(height: 10),
            if (_foundItems.isEmpty)
              _emptyChip('No pending found items')
            else
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _foundItems.length,
                  itemBuilder: (_, i) {
                    final item = _foundItems[i];
                    final isSelected =
                        _selectedFound?.foundItemId == item.foundItemId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFound = item),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(11),
                                bottomLeft: Radius.circular(11),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 90,
                                child: CachedNetworkImage(
                                    imageUrl: item.photoURL,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                        color: const Color(0xFFE8F5E9),
                                        child: const Center(
                                            child: Text('🎉')))),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF4CAF50)
                                        : AppTheme.textPrimary,
                                  ),
                                  maxLines: 2,
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

            // ─── COMPARISON SIDE-BY-SIDE ──────────────────────────────
            if (_selectedLost != null && _selectedFound != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _sectionHeader('🔍 Side-by-Side Comparison'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _DetailCard(
                    title: 'LOST ITEM',
                    color: AppTheme.error,
                    items: {
                      'Name': _selectedLost!.itemName,
                      'Category': _selectedLost!.category ?? '—',
                      'Locations': _selectedLost!.possibleLocations.join(', '),
                      'Description': _selectedLost!.description ?? '—',
                    },
                    imageUrl: _selectedLost!.photoURL,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _DetailCard(
                    title: 'FOUND ITEM',
                    color: const Color(0xFF4CAF50),
                    items: {
                      'Description': _selectedFound!.description,
                      'Category': _selectedFound!.category ?? '—',
                      'Found at': _selectedFound!.locationFound,
                      'Stored at': _selectedFound!.storageOption,
                    },
                    imageUrl: _selectedFound!.photoURL,
                  )),
                ],
              ),

              const SizedBox(height: 16),
              // Secret detail reveal
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🔒', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text('Secret Identification Detail',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFFB45309))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedLost!.secretIdentificationDetail,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask the claimant to describe this detail to verify ownership.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Notes field
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add verification notes (optional)...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Approve Match',
                      onPressed: _approveMatch,
                      isLoading: _isApproving,
                      color: AppTheme.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }

  Widget _emptyChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Color color;
  final Map<String, String> items;
  final String? imageUrl;

  const _DetailCard(
      {required this.title,
        required this.color,
        required this.items,
        this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(13)),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    height: 100,
                    color: color.withOpacity(0.1),
                    child: Center(
                        child: Icon(Icons.image_outlined,
                            color: color))),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: imageUrl == null
                  ? const BorderRadius.vertical(top: Radius.circular(13))
                  : BorderRadius.zero,
            ),
            child: Center(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: items.entries
                  .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key}: ',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
