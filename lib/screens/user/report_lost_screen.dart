import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _secretDetailCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final List<String> _locations = [];
  File? _selectedImage;
  bool _isSubmitting = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Electronics',
    'Bag / Backpack',
    'ID Card / Documents',
    'Keys',
    'Wallet / Purse',
    'Clothing',
    'Books / Notes',
    'Sports Equipment',
    'Other',
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _secretDetailCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Photo',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 70);
                if (img != null) {
                  setState(() => _selectedImage = File(img.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 70);
                if (img != null) {
                  setState(() => _selectedImage = File(img.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addLocation() {
    final loc = _locationCtrl.text.trim();
    if (loc.isEmpty) return;
    setState(() {
      _locations.add(loc);
      _locationCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least one possible location'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = context.read<AuthProvider>().currentUser!.uid;
      String? photoURL;

      if (_selectedImage != null) {
        photoURL =
        await _storageService.uploadLostItemImage(_selectedImage!);
      }

      await _firestoreService.reportLostItem(
        userId: userId,
        itemName: _itemNameCtrl.text.trim(),
        secretIdentificationDetail: _secretDetailCtrl.text.trim(),
        possibleLocations: _locations,
        photoURL: photoURL,
        description: _descriptionCtrl.text.trim().isNotEmpty
            ? _descriptionCtrl.text.trim()
            : null,
        category: _selectedCategory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lost item reported successfully!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Report Lost Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_off, color: Colors.red, size: 14),
                SizedBox(width: 4),
                Text('LOST',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        style: BorderStyle.solid),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius:
                    BorderRadius.circular(AppTheme.cardRadius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_selectedImage!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: AppTheme.primary.withOpacity(0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo (Optional)',
                        style: TextStyle(
                          color: AppTheme.primary.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to upload from camera or gallery',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Item Details'),
              const SizedBox(height: 12),

              AppTextField(
                hint: 'Item Name *',
                controller: _itemNameCtrl,
                prefixIcon: Icons.inventory_2_outlined,
                validator: (v) =>
                v == null || v.isEmpty ? 'Item name is required' : null,
              ),
              const SizedBox(height: 14),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  hintText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppTheme.textSecondary, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 14),

              AppTextField(
                hint: 'Description (optional)',
                controller: _descriptionCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _sectionLabel('🔒 Secret Identification Detail'),
              const SizedBox(height: 4),
              Text(
                'This is kept confidential and used to verify the true owner.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.8)),
              ),
              const SizedBox(height: 10),
              AppTextField(
                hint: 'e.g. Sticker on back, serial number, name written inside...',
                controller: _secretDetailCtrl,
                prefixIcon: Icons.lock_outline_rounded,
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty
                    ? 'Secret detail is required'
                    : null,
              ),
              const SizedBox(height: 20),

              _sectionLabel('📍 Possible Locations'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'e.g. Library, Canteen, Lab 3...',
                      controller: _locationCtrl,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addLocation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius:
                        BorderRadius.circular(AppTheme.inputRadius),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_locations.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _locations
                      .map((loc) => Chip(
                    label: Text(loc),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        setState(() => _locations.remove(loc)),
                    backgroundColor:
                    AppTheme.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                  ))
                      .toList(),
                ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Submit Lost Report',
                onPressed: _submit,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
